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

To export a WAV from the command line:

```powershell
& "C:\Program Files\SuperCollider-3.14.1\sclang.exe" "D:\canon\export_wav.scd"
```

The rendered file is written to `canon_in_d.wav`.

For a short test render:

```powershell
$env:CANON_RECORD_DURATION = "5"
$env:CANON_RECORD_PATH = "D:/canon/canon_test.wav"
& "C:\Program Files\SuperCollider-3.14.1\sclang.exe" "D:\canon\export_wav.scd"
```

## GitHub Actions

### SuperCollider Render

The workflow in `../.github/workflows/render.yml` renders `canon_in_d.wav`, converts
it to `canon_in_d.mp3`, and uploads both files as the `canon-in-d-audio`
artifact.

Run it from the Actions tab with **Render Canon** > **Run workflow**, or push a
version tag such as `v1.0.0`.

### Strudel Render

The workflow in `../.github/workflows/strudel.yml` renders `strudel.html`
to MP3 using headless Chrome and Puppeteer.

Run it from the Actions tab with **Render Strudel Canon** > **Run workflow**.
