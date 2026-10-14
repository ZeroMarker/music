# canon

Current release: [canon-1.3.0](https://github.com/ZeroMarker/music/releases/tag/canon-1.3.0).
Includes SuperCollider, Csound and MIDI + FluidSynth WAV/MP3 plus Strudel MP3.
`1.3.0` adds the FluidSynth sample-based render and refines phrase dynamics.

## Strudel (browser)

Run `npm ci` in the repository root, then open `strudel.html` in a browser and
click **Play**. The browser arrangement uses piano, violin, viola, and cello
through Strudel's built-in triangle and sawtooth synthesizers on the Web Audio
engine.

The arrangement is generated from `../scripts/rebuild_scores.mjs` for all three
engines at 84 BPM. Piano and cello establish the ground, piano arpeggios join
after 16 beats, then the melody and viola enter after 32 beats. A quieter middle
section leads to the return, and a final D major chord begins at 125.71 s.
The score ends at 128.57 s; the remaining render time preserves release tails.

Run `npm run rebuild:music` from the repository root after editing the shared
score. `npm run check` evaluates the entire browser score and verifies that it
stops producing notes after the configured render duration.

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

`main.csd` is a single self-contained file: note tables (MIDI) + a scheduler
instrument that schedules every event, plus the instrument definitions and a
master reverb bus. To render a WAV (csound must be on PATH):

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

## GitHub Actions

All workflows resolve the project name from the pushed tag
(`<project>-<version>`, e.g. `canon-1.0.0`) or from the `project` input when
run manually. Project names may only contain letters, digits and underscores;
versions must be plain dotted numbers (no `-beta` suffixes). Artifacts and
release assets are prefixed with the project name, so multiple projects can be
published from the same repository.

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
