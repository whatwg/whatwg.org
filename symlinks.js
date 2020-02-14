'use strict';

const klaw = require('klaw');
const path = require('path');
const fs = require('fs');

function exists(path) {
  try {
    fs.statSync(path);
    return true;
  } catch(_) {
    return false;
  }
}

function main() {
  const dir = './lists.whatwg.org/pipermail/whatwg-whatwg.org';
  klaw(dir).on('data', (item) => {
    const relpath = path.relative(dir, item.path);
    const match = /^([0-9]{4})-([A-Z][a-z]+)\/([0-9]+)\.html$/.exec(relpath);
    if (!match) {
      return;
    }
    const year = +match[1];
    if (year >= 2017) {
      // archives restart entirely in July 2017, no renumbering from then.
      return;
    }
    const n = +match[3];
    let altn;
    if (n < 42273) {
      altn = n + 42273;
    } else if (n < 2*42273) {
      altn = n - 42273;
    } else {
      // do nothing
      return;
    }
    const altbase = `${String(altn).padStart(6, '0')}.html`;
    const altpath = path.join(path.dirname(item.path), altbase);
    if (!exists(altpath)) {
      fs.symlinkSync(path.basename(item.path), altpath);
    }
  });
}

main();
