"""Render the shared Canon score from recorded VSCO 2 Community Edition samples."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import math
from pathlib import Path
import subprocess
from tempfile import NamedTemporaryFile
from urllib.parse import quote
from urllib.request import urlopen
import wave

import numpy as np

HERE = Path(__file__).resolve().parent
RATE = 44_100
SOURCE = 'https://raw.githubusercontent.com/sgossner/VSCO-2-CE/440300901dfe9275fd84e0b7763af1f8443ae62e/'

# Pitch centers come from the publisher's 1.1.0 SFZ mappings. Several of the
# ensemble recordings use octave labels different from concert MIDI pitches.
PIANO = {key: f'{(key - 21) // 2:03d}' for key in range(41, 82, 4)}
CELLO = {36: 'C1', 40: 'E1'}
BASS = {30: 'F#0', 31: 'G0', 34: 'A#0', 36: 'C1'}
VIOLA = {48: 'C2', 50: 'D2', 52: 'E2', 55: 'G2', 59: 'B2', 62: 'D3'}
VIOLIN = {55: 'G3', 57: 'A3', 60: 'C4', 64: 'E4', 67: 'G4', 69: 'A4', 72: 'C5', 76: 'E5', 79: 'G5'}


def sample_for(voice, pitch, gain):
    if voice.startswith('piano'):
        bank = PIANO
        layer = 1 if gain < 0.079 else 2
        pattern = f'Keys/Upright Piano/Player_dyn{layer}_rr1_{{name}}.wav'
    elif voice == 'cello' and pitch < 36:
        bank = BASS
        pattern = 'Strings/Solo Contrabass/SusNV/BKCtbss_SusNV_{name}_v1_rr1.wav'
    elif voice == 'cello':
        bank = CELLO
        pattern = 'Strings/Cello Section/susvib/susvib_{name}_v1_1.wav'
    elif voice == 'viola':
        bank = VIOLA
        pattern = 'Strings/Viola Section/susvib/ViolaEns_susvib_{name}_v1_1.wav'
    elif voice == 'violin':
        bank = VIOLIN
        pattern = 'Strings/Solo Violin/Arco Vib/LLVln_ArcoVib_{name}_p.wav'
    else:
        raise ValueError(f'no samples mapped for {voice}')
    root = min(bank, key=lambda key: abs(pitch - key))
    if abs(pitch - root) > 3:
        raise ValueError(f'no nearby sample for {voice} MIDI {pitch}')
    return root, pattern.format(name=bank[root])


def load_recording(relative, cache):
    target = cache / Path(relative).name
    if not target.is_file():
        # Commit a complete download so multiple renders can share the cache.
        with NamedTemporaryFile(dir=cache, delete=False) as partial:
            partial_path = Path(partial.name)
            try:
                with urlopen(SOURCE + quote(relative), timeout=45) as response:
                    while block := response.read(256 * 1024):
                        partial.write(block)
                partial.close()
                partial_path.replace(target)
            finally:
                partial_path.unlink(missing_ok=True)
    pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', target, '-t', '5',
                                   '-ar', str(RATE), '-ac', '2', '-f', 'f32le', 'pipe:1'])
    frames = np.frombuffer(pcm, dtype='<f4').reshape(-1, 2)
    if len(frames) < RATE // 4:
        raise ValueError(f'sample too short: {target}')
    # Skip recording pre-roll while retaining the original attack or bow onset.
    window = RATE // 200
    head = frames[:RATE // 2 // window * window].reshape(-1, window, 2)
    peaks = np.max(np.abs(head), axis=(1, 2))
    active = np.flatnonzero(peaks > np.max(peaks) * 0.035)
    if not active.size:
        raise ValueError(f'no attack detected in {target}')
    edited = frames[max(0, int(active[0]) - 2) * window:]
    reference = edited[:RATE * 3 // 4]
    rms = np.sqrt(np.mean(reference ** 2))
    return edited * min(0.18 / rms, 0.85 / np.max(np.abs(edited)))


def render(score, duration, cache):
    frame_count = round(duration * RATE)
    frames_per_beat = 60 * RATE / score['tempoBpm']
    events = []
    for voice in score['voices']:
        for note in voice['notes']:
            onset = round(note['time'] * frames_per_beat)
            if onset < frame_count:
                root, path = sample_for(voice['name'], note['note'], note['amp'])
                events.append((voice, note, onset, root, path))
    paths = sorted({event[-1] for event in events})
    cache.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=8) as pool:
        recordings = dict(zip(paths, pool.map(lambda path: load_recording(path, cache), paths), strict=True))

    mix = np.zeros((frame_count, 2), dtype=np.float32)
    for voice, note, onset, root, path in events:
        piano = voice['name'].startswith('piano')
        held = round(note['duration'] * frames_per_beat)
        tail = round((0.24 if piano else 0.17) * RATE)
        speed = 2 ** ((note['note'] - root) / 12)
        recording = recordings[path]
        available = int((len(recording) - 1) / speed)
        length = min(available, held + tail, frame_count - onset)
        positions = np.arange(length) * speed
        index = positions.astype(np.intp)
        part = recording[index] + (recording[index + 1] - recording[index]) * (positions - index)[:, None]
        fade_in = min(length, round((0.003 if piano else 0.016) * RATE))
        part[:fade_in] *= np.linspace(0, 1, fade_in)[:, None]
        fade_out = min(tail, length)
        part[-fade_out:] *= (0.5 + 0.5 * np.cos(np.linspace(0, np.pi, fade_out)))[:, None]
        pan = (voice['pan'] + 1) * math.pi / 4
        balance = np.array([math.cos(pan), math.sin(pan)])
        voice_level = 0.93 if piano else 1.12 if voice['name'] == 'violin' else 1
        mix[onset:onset + length] += part * balance * note['amp'] * voice_level

    # A few quiet early reflections help the close recordings share a room.
    dry = mix.copy()
    for seconds, gain in ((0.027, 0.12), (0.043, 0.08), (0.071, 0.05), (0.109, 0.03)):
        delay = round(seconds * RATE)
        if delay < frame_count:
            mix[delay:] += dry[:-delay, ::-1] * gain
    fade = min(frame_count, round(0.15 * RATE))
    mix[-fade:] *= np.linspace(1, 0, fade)[:, None]
    peak = float(np.max(np.abs(mix)))
    if not math.isfinite(peak) or peak <= 0:
        raise ValueError('render produced no finite, non-silent audio')
    return np.rint(mix * (0.8 * 32_767 / peak)).astype('<i2')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=HERE / 'canon_samples.wav')
    parser.add_argument('--sample-dir', type=Path, default=HERE / '.sample-cache')
    parser.add_argument('--duration', type=float, help='Override the render duration in seconds')
    args = parser.parse_args()
    score = json.loads((HERE / 'score.json').read_text(encoding='utf-8'))
    duration = score['renderDurationSeconds'] if args.duration is None else args.duration
    if not math.isfinite(duration) or round(duration * RATE) < 2:
        parser.error('--duration must be a positive duration of at least two samples')
    pcm = render(score, duration, args.sample_dir)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(args.output), 'wb') as wav:
        wav.setparams((2, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(pcm.tobytes())
    print(f'Wrote {args.output}')


if __name__ == '__main__':
    main()
