import { createServer } from 'node:http';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import puppeteer from 'puppeteer';

// Shared renderer: reads <project>/strudel.html and project.json.
//   MUSIC_PROJECT_DIR     project directory (default: current working directory)
//   MUSIC_RECORD_DURATION recording length (default: project config, then 137.2)
//   MUSIC_RECORD_PATH     output WebM path (default: <project>/strudel.webm)
// Legacy CANON_* aliases remain supported.
const projectDirValue = process.env.MUSIC_PROJECT_DIR ?? process.env.CANON_PROJECT_DIR;
const projectDir = projectDirValue
  ? path.resolve(projectDirValue)
  : process.cwd();
let projectConfig = {};
try {
  projectConfig = JSON.parse(await readFile(path.join(projectDir, 'project.json'), 'utf8'));
} catch (error) {
  if (error.code !== 'ENOENT') throw new Error(`Invalid project.json: ${error.message}`);
}
const durationSeconds = Number(
  process.env.MUSIC_RECORD_DURATION
    ?? process.env.CANON_RECORD_DURATION
    ?? projectConfig.renderDurationSeconds
    ?? 137.2,
);
const outputValue = process.env.MUSIC_RECORD_PATH ?? process.env.CANON_RECORD_PATH;
const outputPath = outputValue
  ? path.resolve(outputValue)
  : path.join(projectDir, 'strudel.webm');

if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) {
  throw new Error('MUSIC_RECORD_DURATION must be a positive number');
}

await mkdir(path.dirname(outputPath), { recursive: true });

const server = createServer(async (request, response) => {
  if (request.url === '/favicon.ico') {
    response.writeHead(204).end();
    return;
  }
  const requestedFile = request.url === '/node_modules/@strudel/web/dist/index.js'
    ? path.resolve('node_modules/@strudel/web/dist/index.js')
    : request.url === '/' || request.url === '/strudel.html'
      ? path.join(projectDir, 'strudel.html')
      : null;
  if (!requestedFile) {
    response.writeHead(404).end();
    return;
  }

  try {
    const content = await readFile(requestedFile);
    const contentType = requestedFile.endsWith('.js')
      ? 'text/javascript; charset=utf-8'
      : 'text/html; charset=utf-8';
    response.writeHead(200, { 'Content-Type': contentType });
    response.end(content);
  } catch (error) {
    response.writeHead(500).end(String(error));
  }
});

await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(0, '127.0.0.1', resolve);
});

const { port } = server.address();
let browser;

try {
  browser = await puppeteer.launch({
    headless: true,
    args: [
      '--autoplay-policy=no-user-gesture-required',
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
    ],
  });

  const page = await browser.newPage();
  page.on('console', (message) => console.log(`PAGE: ${message.text()}`));
  page.on('pageerror', (error) => console.error(`PAGE ERROR: ${error.message}`));
  page.on('response', (response) => {
    if (response.status() >= 400) console.error(`HTTP ${response.status()}: ${response.url()}`);
  });

  await page.evaluateOnNewDocument(() => {
    const OriginalAudioContext = window.AudioContext || window.webkitAudioContext;

    function CapturedAudioContext(...args) {
      const context = new OriginalAudioContext(...args);
      const captureDestination = context.createMediaStreamDestination();
      const originalConnect = AudioNode.prototype.connect;

      AudioNode.prototype.connect = function connect(destination, ...connectArgs) {
        const result = originalConnect.call(this, destination, ...connectArgs);
        if (destination === context.destination) {
          originalConnect.call(this, captureDestination);
        }
        return result;
      };

      window.__canonCaptureStream = captureDestination.stream;
      return context;
    }

    CapturedAudioContext.prototype = OriginalAudioContext.prototype;
    window.AudioContext = CapturedAudioContext;
    window.webkitAudioContext = CapturedAudioContext;
  });

  await page.goto(`http://127.0.0.1:${port}/`, {
    waitUntil: 'networkidle2',
    timeout: 60_000,
  });
  await page.waitForSelector('#btnPlay:not([disabled])', { timeout: 30_000 });

  // Strudel creates its AudioContext lazily on first playback. Warm it up,
  // stop immediately, then start the real playback after recording begins.
  await page.click('#btnPlay');
  await page.waitForFunction(() => Boolean(window.__canonCaptureStream), {
    timeout: 30_000,
  });
  await page.evaluate(() => hush());

  const audioDataUrl = await page.evaluate(async (durationMs) => {
    const stream = window.__canonCaptureStream;
    const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
      ? 'audio/webm;codecs=opus'
      : 'audio/webm';
    const recorder = new MediaRecorder(stream, { mimeType });
    const chunks = [];

    const finished = new Promise((resolve, reject) => {
      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunks.push(event.data);
      };
      recorder.onerror = () => reject(recorder.error);
      recorder.onstop = async () => {
        const blob = new Blob(chunks, { type: mimeType });
        const reader = new FileReader();
        reader.onerror = () => reject(reader.error);
        reader.onloadend = () => resolve(reader.result);
        reader.readAsDataURL(blob);
      };
    });

    // Start capture before playback so the first notes are not lost.
    recorder.start(1000);
    await window.playCanon();
    await new Promise((resolve) => setTimeout(resolve, durationMs));
    recorder.stop();
    return finished;
  }, durationSeconds * 1000);

  const base64 = audioDataUrl.split(',', 2)[1];
  if (!base64) throw new Error('Browser returned no recorded audio');
  await writeFile(outputPath, Buffer.from(base64, 'base64'));
  console.log(`Wrote ${durationSeconds}s recording to ${outputPath}`);
} finally {
  if (browser) await browser.close();
  await new Promise((resolve) => server.close(resolve));
}
