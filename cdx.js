'use strict';

const assert = require('assert');
const fetch = require('node-fetch');
const mkdirp = require('mkdirp');
const path = require('path');
const {stat, writeFile} = require('fs').promises;

// Wayback CDX Server API: https://github.com/internetarchive/wayback/tree/master/wayback-cdx-server
const cdxURL = 'http://web.archive.org/cdx/search/cdx?url=lists.whatwg.org/*&output=json';

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
                'August', 'September', 'October', 'November', 'December'];

async function isFile(path) {
    try {
        return (await stat(path)).isFile();
    } catch(_) {
        return false;
    }
}

async function main() {
    const entriesByPathname = new Map();

    const rows = await (await fetch(cdxURL)).json();
    const header = rows[0];
    for (let rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        const row = rows[rowIndex];
        const entry = {};
        assert(row.length === header.length)
        for (const [index, value] of row.entries()) {
            entry[header[index]] = value;
        }

        const status = parseInt(entry.statuscode, 10);
        if (status !== 200) {
            continue;
        }

        let pathname = path.normalize(new URL(entry.original).pathname);

        // Treat /htdig.cgi as an alias of /pipermail.
        if (pathname.startsWith('/htdig.cgi/')) {
            pathname = '/pipermail/' + pathname.substr(11);
        }

        // Expand index.html to alias the two forms.
        if (pathname.endsWith('/')) {
            pathname += 'index.html';
        }

        // Only deal with the archives of the whatwg@whatwg.org list.
        if (!pathname.startsWith('/pipermail/whatwg-whatwg.org/')) {
            continue;
        }

        // Only deal with the thread / subject / author / date listings.
        const match = /\/([0-9]{4})-([A-Z][a-z]+)\/([a-z]+)\.html$/.exec(pathname);
        if (!match) {
            continue;
        }
        const year = +match[1];
        assert(year >= 2004 && year <= 2019);
        const month = MONTHS.indexOf(match[2]) + 1;
        assert(month >= 1 && month <= 12);
        if (!['thread', 'subject', 'author', 'date', 'index'].includes(match[3])) {
            continue;
        }

        if (entriesByPathname.has(pathname)) {
            entriesByPathname.get(pathname).push(entry);
        } else {
            entriesByPathname.set(pathname, [entry]);
        }
    }

    const pathnames = Array.from(entriesByPathname.keys());
    pathnames.sort();
    for (const pathname of pathnames) {
        const filePath = path.join('./lists.whatwg.org/', pathname);
        if (await isFile(filePath)) {
            console.log(`Already have ${filePath}`);
            continue;
        }
        const entries = entriesByPathname.get(pathname);
        let entry = entries[0];
        if (entries.length > 1) {
            // Pick the biggest entry.
            const sizes = entries.map(e => +e.length);
            const maxSize = Math.max(...sizes);
            entry = entries.find(e => +e.length === maxSize);
        }
        const archiveURL = `https://web.archive.org/web/${entry.timestamp}id_/${entry.original}`;
        console.log(`Saving ${archiveURL} to ${filePath}`);
        const response = await fetch(archiveURL);
        if (!response.ok) {
            throw new Error(`Bad response for ${archiveURL}: ${response.status}`);
        }
        const buffer = await response.buffer();
        const dirPath = path.dirname(filePath);
        await mkdirp(dirPath);
        await writeFile(filePath, buffer);
    }
}

main().catch((reason) => {
    console.error(reason);
    process.exit(1);
});
