#!/bin/bash

set -e

echo "==============================================="
echo "Local JitPack Build Test"
echo "==============================================="

# Configuration
VERSION=${1:-146}
USE_LOCAL_AAR=${2:-false}
LOCAL_AAR_PATH=${3:-""}

echo "Version: $VERSION"
echo ""

# Clean previous test artifacts
echo "Cleaning previous test artifacts..."
rm -rf extracted/
rm -rf android-scx/shadow/libs/*
rm -rf android-scx/src/main/jniLibs/*
rm -f libscxwebrtc.aar

# Download or use local AAR
if [ "$USE_LOCAL_AAR" = "true" ] && [ -n "$LOCAL_AAR_PATH" ] && [ -f "$LOCAL_AAR_PATH" ]; then
    echo "Using local AAR: $LOCAL_AAR_PATH"
    cp "$LOCAL_AAR_PATH" libscxwebrtc.aar
else
    echo "Downloading AAR from GitHub releases..."
    wget "https://github.com/smile-cx/webrtc-android-scx/releases/download/${VERSION}/libscxwebrtc.aar" -O libscxwebrtc.aar || {
        echo "❌ Failed to download AAR for version ${VERSION}"
        exit 1
    }
fi

# Extract AAR contents
echo ""
echo "Extracting AAR..."
unzip -q -o libscxwebrtc.aar -d extracted/
echo "✓ AAR extracted"

# Show AAR contents
echo ""
echo "AAR contents:"
ls -lh extracted/
echo ""
echo "Native libraries:"
ls -lh extracted/jni/*/

# Prepare shadow module - copy classes.jar
echo ""
echo "Preparing shadow module..."
mkdir -p android-scx/shadow/libs
cp extracted/classes.jar android-scx/shadow/libs/
echo "✓ classes.jar copied to shadow/libs/"

# Copy native libraries to main module
echo ""
echo "Copying native libraries..."
mkdir -p android-scx/src/main/jniLibs
cp -r extracted/jni/* android-scx/src/main/jniLibs/
echo "✓ Native libraries copied"

# Verify native library names
echo ""
echo "Verifying native library names..."
find android-scx/src/main/jniLibs/ -type f -name "*.so" | while read lib; do
    echo "  - $(basename $lib)"
done

# Clean up extracted files
rm -rf extracted/

# Build and test
echo ""
echo "==============================================="
echo "Building shadowed AAR with Gradle..."
echo "==============================================="
echo ""

./gradlew clean :android-scx:assembleRelease -PVERSION_NAME=${VERSION} || {
    echo ""
    echo "❌ Gradle build failed!"
    echo ""
    echo "Common issues:"
    echo "  1. Fat-aar plugin using deprecated Transform API (Gradle 8+)"
    echo "  2. Shadow plugin ConfigureShadowRelocation import error"
    echo "  3. JDK version mismatch"
    echo ""
    exit 1
}

echo ""
echo "==============================================="
echo "✓ Build successful!"
echo "==============================================="
echo ""

# Show output
OUTPUT_AAR="android-scx/build/outputs/aar/android-scx-release.aar"
if [ -f "$OUTPUT_AAR" ]; then
    echo "Output AAR: $OUTPUT_AAR"
    ls -lh "$OUTPUT_AAR"
    echo ""
    echo "Verifying shadowed classes..."
    unzip -l "$OUTPUT_AAR" | grep -E "cx/smile/org/webrtc" | head -10
    echo "  ... (showing first 10 classes)"
else
    echo "⚠️  Output AAR not found at expected location"
fi

echo ""
echo "To test with specific AAR:"
echo "  ./test_jitpack_local.sh 146 true /path/to/libscxwebrtc.aar"
