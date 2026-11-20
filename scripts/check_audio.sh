#!/usr/bin/env bash
set -euo pipefail

input="${1:?Usage: bash scripts/check_audio.sh AUDIO_FILE}"
if [[ ! -s "$input" ]]; then
  echo "error: no audio file at $input" >&2
  exit 1
fi

if ! log=$(ffmpeg -hide_banner -nostats -i "$input" -map 0:a:0 -af volumedetect -f null - 2>&1); then
  printf '%s\n' "$log" >&2
  exit 1
fi

# volumedetect works in 16-bit PCM and can report digital silence as about -91 dB.
peak=$(awk '/max_volume:/ { print $(NF - 1) }' <<< "$log")
if ! awk -v peak="$peak" 'BEGIN { exit !(peak ~ /^-?[0-9]+([.][0-9]+)?$/ && peak + 0 > -80) }'; then
  echo "error: missing or near-silent audio in $input (peak: ${peak:-unavailable} dBFS)" >&2
  exit 1
fi
printf '%s: peak %s dBFS\n' "$input" "$peak"
