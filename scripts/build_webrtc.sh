#!/bin/sh

./tools_webrtc/android/build_aar.py --output libscxwebrtc.aar --verbose --extra-gn-args 'use_siso=false'
