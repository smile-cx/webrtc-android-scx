#!/bin/bash
# Local patch testing script
# Usage: ./scripts/test_patch_locally.sh [webrtc_branch]

set -e

WEBRTC_BRANCH="${1:-7680}"
TEST_DIR="/tmp/webrtc-patch-test-$$"

echo "📦 Creating test directory: $TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📥 Checking out depot_tools..."
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$TEST_DIR/depot_tools:$PATH"

echo "📥 Fetching WebRTC Android..."
fetch --nohooks webrtc_android

cd src
echo "🔄 Checking out branch-heads/$WEBRTC_BRANCH..."
git checkout "branch-heads/$WEBRTC_BRANCH"

cd ..
echo "🔄 Running gclient sync..."
gclient sync --with_branch_heads --with_tags

cd src
echo "🩹 Testing patch application..."
PATCH_FILE="${GITHUB_WORKSPACE:-$OLDPWD}/patches/jni_prefix_smile.patch"

if [ ! -f "$PATCH_FILE" ]; then
    echo "❌ Patch file not found: $PATCH_FILE"
    exit 1
fi

echo "Applying patch with git apply --check..."
if git apply --check --verbose "$PATCH_FILE" 2>&1; then
    echo "✅ git apply check passed!"
    echo "Applying patch..."
    git apply "$PATCH_FILE"
    echo "✅ Patch applied successfully with git apply!"
else
    echo "⚠️  git apply failed, trying patch --dry-run..."
    if patch -p1 --dry-run --verbose < "$PATCH_FILE"; then
        echo "✅ patch dry-run passed!"
        patch -p1 < "$PATCH_FILE"
        echo "✅ Patch applied successfully with patch!"
    else
        echo "❌ Patch failed!"
        echo "Showing reject files:"
        find . -name "*.rej" -exec echo "=== {} ===" \; -exec cat {} \;
        exit 1
    fi
fi

echo ""
echo "✅ Verification:"
grep -q "scxjingle_peerconnection_so" sdk/android/api/org/webrtc/PeerConnectionFactory.java && echo "✓ Library name updated" || echo "✗ Library name NOT updated"
grep -q "cx/smile" sdk/android/src/jni/jni_helpers.h && echo "✓ JNI helpers updated" || echo "✗ JNI helpers NOT updated"
grep -q "cx/smile" webrtc.gni && echo "✓ Package prefix added" || echo "✗ Package prefix NOT added"

echo ""
echo "🧹 Cleanup test directory? (y/n)"
read -r cleanup
if [ "$cleanup" = "y" ]; then
    cd /
    rm -rf "$TEST_DIR"
    echo "✅ Cleaned up $TEST_DIR"
else
    echo "📂 Test directory preserved at: $TEST_DIR"
fi
