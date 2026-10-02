#!/bin/bash
# Builds Docs/CivAware_demo.mp4 from the screenshots. No installs needed (PIL + macOS AVFoundation).
set -e
cd "$(dirname "$0")"
python3 make_demo_video.py
swiftc -O encode_video.swift -o /tmp/civaware_encode_video
/tmp/civaware_encode_video /tmp/civaware_demo/frames 24 /tmp/civaware_demo/audio.wav ../CivAware_demo.mp4
