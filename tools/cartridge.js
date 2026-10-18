const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const buildDir = path.join(root, 'build');

/** Flatten the entry cartridge's one-level Lua includes into a text cartridge. */
function readCartridge() {
  const read = file => fs.readFileSync(path.join(root, file), 'utf8').replaceAll('\r\n', '\n');
  return read('quiet_miles.p8').replace(/^#include (.+)$/gm, (_, file) => {
    const source = read(file);
    if (/^#include\b/m.test(source)) throw new Error(`Nested include in ${file}`);
    return source.trimEnd();
  });
}

module.exports = { readCartridge, buildDir };
