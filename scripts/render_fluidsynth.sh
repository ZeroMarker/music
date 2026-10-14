#!/usr/bin/env bash
set -euo pipefail

# Shared FluidSynth renderer: renders <project>/score.mid to WAV (non-realtime)
# with a General MIDI SoundFont.
#
# Environment variables (consistent with render_csound.sh):
#   MUSIC_PROJECT_DIR     project directory (default: current working directory)
#   MUSIC_RECORD_DURATION render length in seconds (default: project.json renderDurationSeconds)
#   MUSIC_RECORD_PATH     output WAV path (default: <project>/<name>_fluidsynth.wav)
#   MUSIC_SOUNDFONT       .sf2 file (default: /usr/share/sounds/sf2/FluidR3_GM.sf2 or default-GM.sf2)
#
# Example:
#   MUSIC_PROJECT_DIR=canon MUSIC_RECORD_DURATION=8 \
#     bash scripts/render_fluidsynth.sh

project_dir="${MUSIC_PROJECT_DIR:-$(pwd)}"
project_dir="$(cd "$project_dir" && pwd)"
project_name="$(basename "$project_dir")"
midi="$project_dir/score.mid"

if [ ! -f "$midi" ]; then
  echo "error: no $midi (run npm run rebuild:music)" >&2
  exit 1
fi

duration="${MUSIC_RECORD_DURATION:-}"
if [ -z "$duration" ] && [ -f "$project_dir/project.json" ]; then
  duration="$(jq -er '.renderDurationSeconds' "$project_dir/project.json")"
fi
if [ -z "$duration" ]; then
  echo "error: MUSIC_RECORD_DURATION unset and project.json has no renderDurationSeconds" >&2
  exit 1
fi

soundfont="${MUSIC_SOUNDFONT:-}"
if [ -z "$soundfont" ]; then
  for candidate in /usr/share/sounds/sf2/FluidR3_GM.sf2 /usr/share/sounds/sf2/default-GM.sf2; do
    if [ -f "$candidate" ]; then soundfont="$candidate"; break; fi
  done
fi
if [ ! -f "$soundfont" ]; then
  echo "error: no SoundFont found; install fluid-soundfont-gm or set MUSIC_SOUNDFONT" >&2
  exit 1
fi

output="${MUSIC_RECORD_PATH:-$project_dir/${project_name}_fluidsynth.wav}"
mkdir -p "$(dirname "$output")"
raw="$(mktemp --suffix=.wav)"
trap 'rm -f "$raw"' EXIT

echo "Rendering ${project_name} (${duration}s) with FluidSynth ($(basename "$soundfont")) -> $output"
fluidsynth -q -n -i -g 1.0 -r 44100 -R 1 -C 1 -F "$raw" "$soundfont" "$midi"
# The MIDI file ends at the render duration; trim for smoke tests and fade the last second.
fade_start="$(awk -v d="$duration" 'BEGIN { s = d - 1; print (s > 0 ? s : 0) }')"
ffmpeg -v error -y -i "$raw" -t "$duration" -af "afade=t=out:st=${fade_start}:d=1,alimiter=limit=0.95" "$output"

if [ ! -s "$output" ]; then
  echo "error: no audio produced: $output" >&2
  exit 1
fi
echo "Wrote $output"
