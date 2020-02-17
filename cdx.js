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

        // Only deal with whatwg@whatwg.org attachments.
        if (!pathname.startsWith('/pipermail/whatwg-whatwg.org/attachments/')) {
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
        // Pick the most recent entry.
        entries.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
        for (const entry of entries) {
            const archiveURL = `https://web.archive.org/web/${entry.timestamp}id_/${entry.original}`;
            const response = await fetch(archiveURL);
            if (!response.ok) {
                console.error(`Bad response for ${archiveURL}: ${response.status}`);
                await new Promise(resolve => setTimeout(resolve, 30000));
                continue;
            }
            const buffer = await response.buffer();
            console.log(`Saving ${archiveURL} to ${filePath}`);
            const dirPath = path.dirname(filePath);
            await mkdirp(dirPath);
            await writeFile(filePath, buffer);
            break;
        }
    }
}

main().catch((reason) => {
    console.error(reason);
    process.exit(1);
});
