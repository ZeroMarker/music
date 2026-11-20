"""Render the shared Canon arrangement with additive synthesis to stereo WAV."""

import argparse
import json
import math
import wave
from pathlib import Path

import numpy as np

SAMPLE_RATE = 44_100


def synthesize(voice, event, hold_seconds, sample_count):
    """Synthesize up to the requested number of samples from a note's onset."""
    attack = min(voice["attack"], hold_seconds / 2)
    release = voice["release"]
    count = min(sample_count, math.ceil((hold_seconds + release) * SAMPLE_RATE))
    time = np.arange(count) / SAMPLE_RATE
    frequency = 440 * 2 ** ((event["note"] - 69) / 12)
    phase = 2 * np.pi * frequency * time
    bowed = voice["name"] in {"cello", "viola", "violin"}
    if bowed:
        phase += (0.075 * np.sin(2 * np.pi * 5.2 * time)) * np.minimum(1, time / 0.2)
        partials = (1, 0.37, 0.24, 0.15, 0.11, 0.08, 0.06)
        decay = 0.8 + 0.2 * np.exp(-2.2 * time)
    else:
        partials = (1, 0.18, 0.25, 0.07, 0.09, 0.04, 0.03)
        decay = 0.37 + 0.63 * np.exp(-4.4 * time)

    tone = np.zeros(count)
    for harmonic, weight in enumerate(partials, start=1):
        harmonic_hz = harmonic * frequency
        if harmonic_hz >= SAMPLE_RATE / 2:
            break
        attenuation = 1 / math.sqrt(1 + (harmonic_hz / voice["filter"]) ** 4)
        tone += weight * attenuation * np.sin(harmonic * phase)

    envelope = np.minimum(time / attack, 1) * np.clip(1 - (time - hold_seconds) / release, 0, 1) ** 2
    return tone * decay * envelope * event["amp"]


def render(score, duration):
    frames = round(duration * SAMPLE_RATE)
    mix = np.zeros((frames, 2), dtype=np.float32)
    seconds_per_beat = 60 / score["tempoBpm"]
    for voice in score["voices"]:
        angle = (voice["pan"] + 1) * math.pi / 4
        panning = np.array([math.cos(angle), math.sin(angle)])
        for event in voice["notes"]:
            start = round(event["time"] * seconds_per_beat * SAMPLE_RATE)
            if start >= frames:
                break
            signal = synthesize(voice, event, event["duration"] * seconds_per_beat, frames - start)
            mix[start:start + len(signal)] += signal[:, None] * panning

    dry = mix.copy()
    for delay_seconds, gain in ((0.037, 0.12), (0.071, 0.09), (0.113, 0.07), (0.173, 0.05), (0.239, 0.025)):
        delay = round(delay_seconds * SAMPLE_RATE)
        if delay < frames:
            mix[delay:] += gain * dry[:-delay, ::-1]
    fade = min(frames, round(0.2 * SAMPLE_RATE))
    mix[-fade:] *= np.linspace(1, 0, fade)[:, None]
    peak = float(np.max(np.abs(mix)))
    if not math.isfinite(peak):
        raise ValueError("The renderer produced non-finite samples")
    gain = min(1.6, 0.9 / peak) if peak else 1.6
    return np.rint(mix * gain * 32_767).astype("<i2")


def main():
    here = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=here / "canon_python.wav")
    parser.add_argument("--duration", type=float, help="Override the render duration in seconds")
    args = parser.parse_args()
    score = json.loads((here / "score.json").read_text(encoding="utf-8"))
    duration = args.duration if args.duration is not None else score["renderDurationSeconds"]
    if not math.isfinite(duration) or duration <= 0 or round(duration * SAMPLE_RATE) < 1:
        parser.error("--duration must be a positive duration of at least one sample")

    pcm = render(score, duration)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(args.output), "wb") as wav:
        wav.setparams((2, 2, SAMPLE_RATE, 0, "NONE", "not compressed"))
        wav.writeframes(pcm.tobytes())
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
