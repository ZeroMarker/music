import { readFile, readdir, access } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { evalScope, controls, State, TimeSpan } from '@strudel/core';
import * as core from '@strudel/core';
import * as mini from '@strudel/mini';
import * as tonal from '@strudel/tonal';
import * as webaudio from '@strudel/webaudio';
import { evaluate } from '@strudel/transpiler';

// Offline smoke check for <project>/strudel.html: extracts the pattern code,
// evaluates it exactly like the browser does (transpiler + eval scope) and
// queries the resulting pattern, so broken code or dead patterns fail in CI
// without launching a browser.
// Usage: node scripts/check_strudel_pattern.mjs [project ...]

const requestedProjects = process.argv.slice(2);
let projectNames = requestedProjects;
if (!projectNames.length) {
  const directories = (await readdir('.', { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);
  const candidates = await Promise.all(directories.map(async (name) => {
    try {
      await access(path.join(name, 'strudel.html'));
      return name;
    } catch {
      return null;
    }
  }));
  projectNames = candidates.filter(Boolean).sort();
}

if (!projectNames.length) throw new Error('No strudel.html files found');

const extractPatternCode = (html, file) => {
  const match = html.match(/const\s+\w+\s*=\s*(?:String\.raw)?`([\s\S]*?)`/);
  if (!match) throw new Error(`${file}: could not find pattern code in strudel.html`);
  return match[1];
};

const checkValue = (value, where) => {
  if (value === null || typeof value !== 'object') return;
  for (const [key, entry] of Object.entries(value)) {
    if (typeof entry === 'number' && !Number.isFinite(entry)) {
      throw new Error(`${where}: control "${key}" is not a finite number (${entry})`);
    }
    if (key === 'note' && typeof entry === 'number' && (entry < 0 || entry > 127)) {
      throw new Error(`${where}: note ${entry} is outside the MIDI range`);
    }
  }
};

await evalScope(evalScope, controls, core, mini, tonal, webaudio, {
  hush: () => {},
  evaluate: () => {},
});

for (const projectName of projectNames) {
  const file = path.join(projectName, 'strudel.html');
  const html = await readFile(file, 'utf8');
  const code = extractPatternCode(html, file);

  let pattern;
  try {
    ({ pattern } = await evaluate(code));
  } catch (error) {
    throw new Error(`${file}: pattern failed to evaluate: ${error.message}`);
  }
  if (typeof pattern?.query !== 'function') {
    throw new Error(`${file}: evaluated code did not return a pattern`);
  }

  // Query eight cycles; enough to cover intro/build-up sections.
  let eventCount = 0;
  let voiced = 0;
  for (let begin = 0; begin < 8; begin++) {
    const haps = pattern.query(new State(new TimeSpan(begin, begin + 1)));
    for (const hap of haps) {
      eventCount++;
      checkValue(hap.value, `${file} (cycle ${begin})`);
      if (hap.value && (hap.value.note !== undefined || hap.value.sound !== undefined)) voiced++;
      if (!hap.whole) throw new Error(`${file}: event without a timespan at cycle ${begin}`);
    }
  }
  if (!eventCount) throw new Error(`${file}: pattern is silent for the first 8 cycles`);
  if (!voiced) throw new Error(`${file}: pattern has no note/sound events in the first 8 cycles`);
  console.log(`Checked ${projectName} (${eventCount} events over 8 cycles)`);
}
