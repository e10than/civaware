#!/bin/bash
# usage: build_overlay_video.sh <raw_screen_recording.mov> [out.mp4]
set -e
cd "$(dirname "$0")"
RAW="${1:?give the raw screen recording path}"
OUT="${2:-../../CivAware_demo_screen.mp4}"
python3 make_overlay_assets.py "$RAW"
swiftc -O compose_overlay.swift -o /tmp/civaware_compose_overlay
/tmp/civaware_compose_overlay "$RAW" /tmp/civaware_overlay "$OUT"
