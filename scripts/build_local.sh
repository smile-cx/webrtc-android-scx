#!/bin/bash
# Local build script for Android WebRTC with SmileCX patches
# Usage: ./scripts/build_local.sh [branch_number] [build_dir]
# Example: ./scripts/build_local.sh 7680 ./local-build

set -e

WEBRTC_BRANCH="${1:-7680}"
BUILD_DIR="${2:-$(pwd)/local-build}"

echo "================================================"
echo "SmileCX WebRTC Android Local Build"
echo "================================================"
echo "Branch: branch-heads/$WEBRTC_BRANCH"
echo "Build directory: $BUILD_DIR"
echo "================================================"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Step 1: Checkout depot_tools
if [ ! -d depot_tools ]; then
    echo "📥 Checking out depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
else
    echo "✓ depot_tools already exists"
fi

export PATH="$(pwd)/depot_tools:$PATH"

# Step 2: Fetch WebRTC Android
if [ ! -d src ]; then
    echo "📥 Fetching WebRTC Android (this will take a while)..."
    fetch --nohooks webrtc_android
else
    echo "✓ WebRTC source already exists"
fi

cd src

# Step 3: Checkout branch
echo "🔄 Checking out branch-heads/$WEBRTC_BRANCH..."
git checkout "branch-heads/$WEBRTC_BRANCH"

cd ..

# Step 4: Sync dependencies
echo "🔄 Running gclient sync (this will take a while)..."
gclient sync --with_branch_heads --with_tags

cd src

# Step 5: Apply SmileCX patches
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH_FILE="$REPO_DIR/patches/jni_prefix_smile.patch"

echo "🩹 Applying SmileCX patches..."
echo "Patch file: $PATCH_FILE"

if [ ! -f "$PATCH_FILE" ]; then
    echo "❌ Patch file not found: $PATCH_FILE"
    exit 1
fi

# Try git apply first
if git apply --check --verbose "$PATCH_FILE" 2>&1; then
    echo "Using git apply..."
    git apply "$PATCH_FILE"
else
    echo "git apply failed, trying patch with fuzz..."
    patch -p1 --fuzz=3 --verbose < "$PATCH_FILE" || {
        echo "❌ Patch failed!"
        echo "Showing reject files:"
        find . -name "*.rej" -exec echo "=== {} ===" \; -exec cat {} \;
        exit 1
    }
fi

echo "✓ Patch applied successfully!"
echo ""
echo "Verifying patch application..."
grep -q "scxjingle_peerconnection_so" sdk/android/api/org/webrtc/PeerConnectionFactory.java && echo "✓ Library name updated" || echo "✗ Library name NOT updated"
grep -q "Java_cx_smile_org_webrtc" sdk/android/src/jni/jni_helpers.h && echo "✓ JNI helpers updated" || echo "✗ JNI helpers NOT updated"
grep -q "cx/smile" webrtc.gni && echo "✓ Package prefix added" || echo "✗ Package prefix NOT added"
echo ""

# Step 6: Build AAR
echo "🔨 Building Android AAR (this will take a long time)..."
./tools_webrtc/android/build_aar.py --output libscxwebrtc.aar --verbose --extra-gn-args 'use_siso=false'

echo ""
echo "================================================"
echo "✅ Build Complete!"
echo "================================================"
echo "Build directory: $BUILD_DIR/src"
echo "Output AAR: $BUILD_DIR/src/libscxwebrtc.aar"
echo ""
if [ -f "libscxwebrtc.aar" ]; then
    ls -lh libscxwebrtc.aar
fi
