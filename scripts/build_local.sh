#!/bin/bash
# Local build script for Android WebRTC with SmileCX patches
# Usage: ./scripts/build_local.sh [branch_number] [build_dir]
# Example: ./scripts/build_local.sh 7680 ./local-build
#
# This script builds a modified version of WebRTC with SmileCX symbol prefixing.
# All modifications are documented in:
#   - patches/MODIFICATIONS.md
#   - NOTICE file
# For license compliance information, see LICENSE.md and NOTICE.

set -e

# Determine script and repo directories at the start
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

WEBRTC_BRANCH="${1:-7680}"
BUILD_DIR="${2:-$(pwd)/local-build}"

# Convert BUILD_DIR to absolute path
BUILD_DIR="$(cd "$(dirname "$BUILD_DIR")" 2>/dev/null && pwd)/$(basename "$BUILD_DIR")" || BUILD_DIR="$(pwd)/$BUILD_DIR"

echo "================================================"
echo "SmileCX WebRTC Android Local Build"
echo "================================================"
echo "Branch: branch-heads/$WEBRTC_BRANCH"
echo "Build directory: $BUILD_DIR"
echo "================================================"
echo ""

# Check if we're on macOS and not already inside Docker
if [[ "$OSTYPE" == "darwin"* ]] && [ ! -f /.dockerenv ]; then
    echo "🐳 Detected macOS - WebRTC Android builds require Linux"
    echo "🐳 Launching Docker container for build..."
    echo ""

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed or not in PATH"
        echo "Please install Docker Desktop for Mac: https://www.docker.com/products/docker-desktop"
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo "❌ Docker daemon is not running"
        echo "Please start Docker Desktop"
        exit 1
    fi

    # Create build directory on host
    mkdir -p "$BUILD_DIR"

    # Run build inside Docker container with proper Android build environment
    docker run --rm -it \
        -v "$BUILD_DIR:$BUILD_DIR" \
        -v "$REPO_DIR:/repo" \
        -w "$BUILD_DIR" \
        ubuntu:24.04 \
        bash -c "
            set -e
            echo '📦 Installing build dependencies...'
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get -y install tzdata > /dev/null 2>&1
            echo 'Etc/UTC' > /etc/timezone
            dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1

            apt-get install -y -qq \
                binutils \
                git \
                locales \
                lsb-release \
                pkg-config \
                python3 \
                ninja-build \
                python3-setuptools \
                rsync \
                sudo \
                unzip \
                wget \
                xz-utils \
                openjdk-11-jdk \
                build-essential \
                > /dev/null 2>&1

            echo '🔨 Starting build inside container...'
            cd /repo/scripts
            bash build_local.sh $WEBRTC_BRANCH $BUILD_DIR
        "

    echo ""
    echo "================================================"
    echo "✅ Docker build completed!"
    echo "================================================"
    exit 0
fi

# If we reach here, we're either on Linux or inside Docker container
echo "✓ Running on Linux (native or Docker container)"
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
    NEED_SYNC=true
else
    echo "✓ WebRTC source already exists"
    NEED_SYNC=false
fi

cd src

# Step 3: Check if we're already on the right branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$CURRENT_BRANCH" = "branch-heads/$WEBRTC_BRANCH" ]; then
    echo "✓ Already on branch-heads/$WEBRTC_BRANCH"

    # Just clean patches, no need to re-sync
    echo "🧹 Cleaning previous patches..."
    git reset --hard HEAD 2>/dev/null || true
    git clean -fd
else
    echo "🔄 Switching to branch-heads/$WEBRTC_BRANCH..."

    # Clean everything before switching
    git reset --hard HEAD 2>/dev/null || true
    git clean -fd
    git checkout "branch-heads/$WEBRTC_BRANCH"

    NEED_SYNC=true
fi

cd ..

# Step 4: Sync dependencies only if needed
if [ "$NEED_SYNC" = true ]; then
    echo "🧹 Cleaning all dependencies..."
    gclient revert --nohooks

    echo "🔄 Running gclient sync (this will take a while)..."
    gclient sync --with_branch_heads --with_tags
else
    echo "✓ Skipping gclient sync (already up to date)"
fi

cd src

# Step 5: Apply SmileCX patches
# This patch modifies upstream WebRTC source files to add symbol prefixing.
# All modifications are documented in patches/MODIFICATIONS.md and NOTICE.
PATCH_FILE="$REPO_DIR/patches/jni_prefix_smile.patch"

echo "🩹 Applying SmileCX patches..."
echo "Patch file: $PATCH_FILE"
echo "Modifications documented in: patches/MODIFICATIONS.md"

if [ ! -f "$PATCH_FILE" ]; then
    echo "❌ Patch file not found: $PATCH_FILE"
    exit 1
fi

# Check if patch is already applied
if grep -q "scxjingle_peerconnection_so" sdk/android/api/org/webrtc/PeerConnectionFactory.java 2>/dev/null && \
   grep -q "Java_cx_smile_org_webrtc" sdk/android/src/jni/jni_helpers.h 2>/dev/null && \
   grep -q "cx/smile" webrtc.gni 2>/dev/null; then
    echo "✓ Patch already applied, skipping..."
else
    echo "Applying patch..."

    # Reset any previous partial patches
    git reset --hard HEAD 2>/dev/null || true

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
fi

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
