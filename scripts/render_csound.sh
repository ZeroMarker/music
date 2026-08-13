#!/usr/bin/env bash
set -euo pipefail

# Shared Csound renderer: renders <project>/main.csd to WAV (non-realtime).
#
# Environment variables (consistent with export_wav.scd / render_strudel.mjs):
#   MUSIC_PROJECT_DIR     project directory (default: current working directory)
#   MUSIC_RECORD_DURATION render length in seconds (default: project.json renderDurationSeconds)
#   MUSIC_RECORD_PATH     output WAV path (default: <project>/<name>_csound.wav)
#
# Example:
#   MUSIC_PROJECT_DIR=canon MUSIC_RECORD_DURATION=8 \
#     bash scripts/render_csound.sh

project_dir="${MUSIC_PROJECT_DIR:-$(pwd)}"
project_dir="$(cd "$project_dir" && pwd)"
project_name="$(basename "$project_dir")"
csd="$project_dir/main.csd"

if [ ! -f "$csd" ]; then
  echo "error: no $csd" >&2
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

output="${MUSIC_RECORD_PATH:-$project_dir/${project_name}_csound.wav}"
mkdir -p "$(dirname "$output")"

echo "Rendering ${project_name} (${duration}s) with Csound -> $output"
csound --smacro:DURATION="$duration" -d -m0 -o "$output" "$csd"

if [ ! -s "$output" ]; then
  echo "error: no audio produced: $output" >&2
  exit 1
fi
echo "Wrote $output"
