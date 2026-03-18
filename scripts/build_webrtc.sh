#!/bin/sh
# Build WebRTC AAR with SmileCX modifications
# This builds modified WebRTC source code (patches applied separately)
# Modifications documented in: patches/MODIFICATIONS.md and NOTICE

./tools_webrtc/android/build_aar.py --output libscxwebrtc.aar --verbose --extra-gn-args 'use_siso=false'
