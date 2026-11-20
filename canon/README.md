# canon

Current release: [canon-1.3.0](https://github.com/ZeroMarker/music/releases/tag/canon-1.3.0).
Includes SuperCollider, Csound and MIDI + FluidSynth WAV/MP3 plus Strudel MP3.
`1.3.0` adds the FluidSynth sample-based render and refines phrase dynamics.

## Strudel (browser)

Run `npm ci` in the repository root, then open `strudel.html` in a browser and
click **Play**. The browser arrangement uses piano, violin, viola, and cello
through Strudel's built-in triangle and sawtooth synthesizers on the Web Audio
engine.

The arrangement comes from the [shared score generator](../scripts/rebuild_scores.mjs)
at 84 BPM. Piano and cello establish the ground, piano arpeggios join
after 16 beats, then the melody and viola enter after 32 beats. A quieter middle
section leads to the return, and a final D major chord begins at 125.71 s.
The score ends at 128.57 s; the remaining render time preserves release tails.

Set `tempoBpm` and `renderDurationSeconds` in [project.json](project.json), then
run `npm run rebuild:music` from the repository root. Allow enough time for all
180 beats plus release tails. `npm run check` checks the full Strudel pattern and
reports generated arrangements that are out of date.

## SuperCollider

SuperCollider arrangement of Canon in D for:

- piano
- violin
- viola
- cello

Open `main.scd` in SuperCollider and evaluate the whole file. The piece starts
after the server boots.

To stop playback, evaluate:

```supercollider
~stopCanon.()
```

To export a WAV from the command line (sclang must be on PATH):

```bash
sclang export_wav.scd
```

The rendered file is written to `canon.wav`.

For a short test render:

```bash
MUSIC_RECORD_DURATION=5 MUSIC_RECORD_PATH=canon_test.wav sclang export_wav.scd
```

## Csound

Csound arrangement of Canon in D for:

- soft piano
- violin
- viola
- cello

`main.csd` contains the generated scheduler, instrument definitions, and master
reverb bus. To render a WAV with Csound installed, run the following from the
repository root.

```bash
cd canon
csound --smacro:DURATION=137.2 -o canon_csound.wav main.csd
```

The `DURATION` macro defaults to 137.2 s inside the file, so a plain
`csound -o canon_csound.wav main.csd` works too. Use the shared script for
project-aware rendering:

```bash
MUSIC_PROJECT_DIR=canon MUSIC_RECORD_PATH=canon/canon_csound.wav \
  bash scripts/render_csound.sh
```

For a short test render:

```bash
MUSIC_PROJECT_DIR=canon MUSIC_RECORD_DURATION=5 MUSIC_RECORD_PATH=/tmp/canon_test.wav \
  bash scripts/render_csound.sh
```

## Tone.js

Use Node.js 22.12 or newer. From the repository root, install dependencies
with `npm ci`, then render the WAV.

```bash
npm run render:tone
```

Tone.js uses Chromium's offline Web Audio context to schedule the shared
[score.json](score.json), apply per-part filters and panning, and write
`canon/canon_tone.wav` at 44.1 kHz stereo. Set `MUSIC_RECORD_PATH` to change the
output location and `MUSIC_RECORD_DURATION` for a shorter render. If Puppeteer
requires a local browser, set `PUPPETEER_EXECUTABLE_PATH` to Chrome or Chromium.
[Tone.js offline implementation](https://github.com/Tonejs/Tone.js/blob/dev/Tone/core/context/Offline.ts)

## Sonic Pi

Open [sonic_pi.rb](sonic_pi.rb) in the Sonic Pi desktop editor and press **Run**.
Each part plays in its own thread. Press **Stop** to interrupt the performance
or **Record** to capture it. The score section is rebuilt from the shared
arrangement. [Sonic Pi tutorial](https://sonic-pi.net/tutorial.html)

## Python DSP and music21

From the repository root, use Python 3.10 or newer.

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r canon/requirements.txt
.venv/bin/python canon/render_python.py
.venv/bin/python canon/export_music21.py
```

The Python renderer uses additive synthesis, distinct piano and string envelopes,
stereo panning and short delay taps. The default output is
`canon/canon_python.wav` at 44.1 kHz stereo. Use `--duration` to render an excerpt
and `--output` to change the path. With FFmpeg installed, encode either WAV to
MP3 using `ffmpeg -i input.wav -c:a libmp3lame -q:a 2 output.mp3`.

The music21 exporter quantizes the shared `score.mid` to a sixteenth-note grid
for readable notation and writes five parts to `canon/canon.musicxml`. Open the
MusicXML in a notation editor. Use [score.mid](score.mid) for the original
performance timing. [music21 MIDI documentation](https://music21.org/music21docs/moduleReference/moduleMidiTranslate.html)

## GitHub Actions

The four release render workflows resolve the project name from the pushed tag
(`<project>-<version>`, e.g. `canon-1.0.0`) or from the `project` input when
run manually. Project names may only contain letters, digits and underscores;
versions must be plain dotted numbers (no `-beta` suffixes). Artifacts and
release assets are prefixed with the project name, so multiple projects can be
published from the same repository. The validation workflow also renders short
Tone.js and Python samples, exports MusicXML, and syntax-checks the Sonic Pi file.

### SuperCollider Render

The workflow in `../.github/workflows/render.yml` renders `canon.wav` from
the arrangement, converts it to `canon.mp3`, and uploads both files as the
`canon-audio` artifact. On tag pushes it also attaches both files to the
GitHub Release.

Run it from the Actions tab with **Render SuperCollider** > **Run workflow**
(project: `canon`), or push a version tag such as `canon-1.0.0`.

### Strudel Render

The workflow in `../.github/workflows/strudel.yml` renders `strudel.html`
to MP3 using headless Chrome and Puppeteer. The shared capture script is
`../scripts/render_strudel.mjs`; `MUSIC_PROJECT_DIR`, `MUSIC_RECORD_DURATION`
and `MUSIC_RECORD_PATH` control the project directory, recording length
(137.2 s default) and output path. On tag pushes the MP3 is also attached to
the GitHub Release.

Run it from the Actions tab with **Render Strudel** > **Run workflow**
(project: `canon`), or push a version tag such as `canon-1.0.0`.

### Csound Render

The workflow in `../.github/workflows/csound.yml` renders `canon_csound.wav`
from `main.csd` with non-realtime Csound, converts it to `canon_csound.mp3`,
and uploads both files as the `canon-csound-audio` artifact. On tag pushes it
also attaches both files to the GitHub Release.

Run it from the Actions tab with **Render Csound** > **Run workflow**
(project: `canon`), or push a version tag such as `canon-1.0.0`.
