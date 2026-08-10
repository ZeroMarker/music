# canon

## Strudel (browser)

Open `strudel.html` in a browser and click **Play**. Uses built-in
synthesizers (triangle for piano, sawtooth for violin) via Strudel's
Web Audio engine.

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

The rendered file is written to `canon_in_d.wav`.

For a short test render:

```bash
CANON_RECORD_DURATION=5 CANON_RECORD_PATH=canon_test.wav sclang export_wav.scd
```

## GitHub Actions

Both workflows resolve the project name from the pushed tag
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
`../scripts/render_strudel.mjs`; `CANON_PROJECT_DIR`, `CANON_RECORD_DURATION`
and `CANON_RECORD_PATH` control the project directory, recording length
(137.2 s default) and output path. On tag pushes the MP3 is also attached to
the GitHub Release.

Run it from the Actions tab with **Render Strudel** > **Run workflow**
(project: `canon`), or push a version tag such as `canon-1.0.0`.
