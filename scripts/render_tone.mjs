import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer';

const score = JSON.parse(await readFile(new URL('../canon/score.json', import.meta.url), 'utf8'));
const duration = Number(process.env.MUSIC_RECORD_DURATION ?? score.renderDurationSeconds);
const output = path.resolve(process.env.MUSIC_RECORD_PATH ?? 'canon/canon_tone.wav');
const sampleRate = 44_100;
if (!Number.isFinite(duration) || duration <= 0 || Math.round(duration * sampleRate) < 1) {
  throw new Error('MUSIC_RECORD_DURATION must be a positive duration of at least one sample');
}

// Puppeteer runs the Web Audio renderer in Chrome's OfflineAudioContext.
async function renderInBrowser(score, duration, sampleRate) {
  const { Tone } = window;
  const secondsPerBeat = 60 / score.tempoBpm;
  const audio = await Tone.Offline(() => {
    const master = new Tone.Gain(0.8).toDestination();
    master.gain.setValueAtTime(0.8, Math.max(0, duration - 0.2));
    master.gain.linearRampToValueAtTime(0, duration);
    const ambience = new Tone.FeedbackDelay({ delayTime: 0.137, feedback: 0.24, wet: 1 }).connect(master);
    const send = new Tone.Gain(0.12).connect(ambience);

    for (const voice of score.voices) {
      const pan = new Tone.Panner(voice.pan).connect(master).connect(send);
      const filter = new Tone.Filter(voice.filter, 'lowpass').connect(pan);
      const synth = new Tone.PolySynth(Tone.Synth, {
        oscillator: { type: voice.sound },
        envelope: { attack: voice.attack, decay: 0.2, sustain: 0.65, release: voice.release },
      }).connect(filter);
      for (const { time, note, duration: beats, amp } of voice.notes) {
        const start = time * secondsPerBeat;
        if (start >= duration) break;
        synth.triggerAttackRelease(Tone.Frequency(note, 'midi').toFrequency(), beats * secondsPerBeat, start, amp);
      }
    }
  }, duration, 2, sampleRate);

  const left = audio.getChannelData(0);
  const right = audio.getChannelData(1);
  let peak = 0;
  for (let frame = 0; frame < left.length; frame++) {
    peak = Math.max(peak, Math.abs(left[frame]), Math.abs(right[frame]));
  }
  if (!Number.isFinite(peak)) throw new Error('Tone.js produced non-finite samples');
  const gain = 32767 / Math.max(1, peak);
  const pcm = new Uint8Array(left.length * 4);
  const view = new DataView(pcm.buffer);
  for (let frame = 0; frame < left.length; frame++) {
    view.setInt16(frame * 4, Math.round(left[frame] * gain), true);
    view.setInt16(frame * 4 + 2, Math.round(right[frame] * gain), true);
  }
  // Encode bounded chunks for transfer over the browser debugging connection.
  const chunks = [];
  const chunkSize = 24_576;
  for (let offset = 0; offset < pcm.length; offset += chunkSize) {
    chunks.push(btoa(String.fromCharCode(...pcm.subarray(offset, offset + chunkSize))));
  }
  return chunks.join('');
}

const browser = await puppeteer.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
});
try {
  const page = await browser.newPage();
  const bundle = new URL('../Tone.js', import.meta.resolve('tone'));
  await page.addScriptTag({ path: fileURLToPath(bundle) });
  const pcm = Buffer.from(await page.evaluate(renderInBrowser, score, duration, sampleRate), 'base64');
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(pcm.length + 36, 4);
  header.write('WAVEfmt ', 8);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(2, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(sampleRate * 4, 28);
  header.writeUInt16LE(4, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(pcm.length, 40);
  await mkdir(path.dirname(output), { recursive: true });
  await writeFile(output, Buffer.concat([header, pcm]));
  console.log(`Wrote ${output}`);
} finally {
  await browser.close();
}
