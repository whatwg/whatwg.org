'use strict';

const fetch = require('node-fetch');
const mkdirp = require('mkdirp');
const path = require('path');
const {stat, writeFile} = require('fs').promises;

// Wayback CDX Server API: https://github.com/internetarchive/wayback/tree/master/wayback-cdx-server
const cdxURL = 'http://web.archive.org/cdx/search/cdx?url=lists.whatwg.org/*&output=json';

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
        console.assert(row.length === header.length)
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

        // There was a big crawl that started right before midnight 2014-04-01.
        // Only use the entries from that narrow slice of time for now.
        console.assert(entry.timestamp.length == 14);
        const timestamp = +entry.timestamp;
        if (timestamp < 20140331000000 || timestamp >= 20140403000000) {
            continue;
        }

        // Skip any entries after the first renumbering of messages:
        // https://github.com/whatwg/meta/issues/153#issuecomment-566980200
        const basename = path.basename(pathname);
        if (/^[0-9]+\.html$/.test(basename)) {
            const n = parseInt(basename.split('.')[0], 10);
            if (n >= 42273) {
                continue;
            }
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
