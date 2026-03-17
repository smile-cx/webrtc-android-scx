#!/bin/bash
# Prepare AAR for shadowing and repackaging
# Usage: ./prepare_aar.sh <path-to-libscxwebrtc.aar>

set -e
set -x

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-libscxwebrtc.aar>"
    echo "Example: $0 /path/to/libscxwebrtc.aar"
    exit 1
fi

AAR_PATH="$1"

if [ ! -f "$AAR_PATH" ]; then
    echo "Error: AAR file not found: $AAR_PATH"
    exit 1
fi

echo "Preparing AAR for shadowing: $AAR_PATH"

# Extract AAR contents
echo "Extracting AAR..."
rm -rf extracted/
mkdir -p extracted
unzip -o "$AAR_PATH" -d extracted/

# Prepare shadow module - copy classes.jar
echo "Preparing shadow module..."
rm -rf android-scx/shadow/libs/*
mkdir -p android-scx/shadow/libs
cp extracted/classes.jar android-scx/shadow/libs/

# Copy native libraries to main module
echo "Copying native libraries..."
rm -rf android-scx/src/main/jniLibs/*
mkdir -p android-scx/src/main/jniLibs
cp -r extracted/jni/* android-scx/src/main/jniLibs/

# Verify .so files have correct names (should already be libscxjingle_peerconnection_so.so)
echo "Verifying native library names..."
find android-scx/src/main/jniLibs/ -type f -name "*.so" -exec echo "Found: {}" \;

# Clean up extracted files
rm -rf extracted/

echo "✅ AAR prepared successfully!"
echo "Next steps:"
echo "  1. Build the shadowed AAR: ./gradlew :android-scx:assembleRelease"
echo "  2. Find output at: android-scx/build/outputs/aar/android-scx-release.aar"
