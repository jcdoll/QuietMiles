// Package source as one plain-text cartridge for browser loading.
const fs = require('node:fs');
const path = require('node:path');
const { readCartridge, buildDir } = require('./cartridge');

const source = readCartridge();
fs.mkdirSync(buildDir, { recursive: true });
fs.writeFileSync(path.join(buildDir, 'quiet_miles.p8'), source);
console.log('Created build/quiet_miles.p8; load it in PICO-8.');
