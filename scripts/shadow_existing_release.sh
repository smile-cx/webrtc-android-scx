#!/bin/bash
set -e

# Script to apply shadowing to an existing GitHub release AAR
# Usage: ./scripts/shadow_existing_release.sh 146

VERSION=${1:-146}
REPO="smile-cx/webrtc-android-scx"
AAR_NAME="libscxwebrtc.aar"

echo "=================================================="
echo "Shadow Existing Release AAR"
echo "=================================================="
echo "Version: $VERSION"
echo "Repository: $REPO"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is required but not installed."
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Authenticate check
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

# Create temp directory
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

cd "$WORK_DIR"
echo "Working directory: $WORK_DIR"
echo ""

# Download existing AAR from release
echo "1. Downloading existing AAR from GitHub release..."
gh release download "$VERSION" \
    --repo "$REPO" \
    --pattern "$AAR_NAME" \
    --clobber || {
    echo "❌ Failed to download AAR from release $VERSION"
    echo "Make sure the release exists and contains $AAR_NAME"
    exit 1
}

echo "✓ Downloaded $AAR_NAME ($(du -h $AAR_NAME | cut -f1))"
echo ""

# Check if already shadowed
echo "2. Checking if AAR is already shadowed..."
unzip -q "$AAR_NAME" -d check/
if jar -tf check/classes.jar | grep -q "cx/smile/org/webrtc"; then
    echo "✓ AAR is already shadowed!"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
else
    echo "AAR is NOT shadowed - applying shadowing..."
fi
rm -rf check/
echo ""

# Copy Gradle project files needed for shadowing
echo "3. Setting up shadow environment..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cp -r "$SCRIPT_DIR/android-scx" .
cp -r "$SCRIPT_DIR/settings.gradle" .
cp -r "$SCRIPT_DIR/build.gradle" .
cp -r "$SCRIPT_DIR/gradlew" .
cp -r "$SCRIPT_DIR/gradlew.bat" .
cp -r "$SCRIPT_DIR/gradle" . 2>/dev/null || true

echo "✓ Shadow environment ready"
echo ""

# Extract AAR
echo "4. Extracting AAR..."
mkdir -p aar-extract
unzip -q "$AAR_NAME" -d aar-extract/
echo "✓ Extracted"
echo ""

# Prepare shadow module
echo "5. Preparing shadow module..."
rm -rf android-scx/shadow/libs/*
mkdir -p android-scx/shadow/libs
cp aar-extract/classes.jar android-scx/shadow/libs/
echo "✓ classes.jar copied"
echo ""

# Run shadow JAR creation
echo "6. Running Gradle shadow plugin..."
./gradlew :android-scx:shadow:shadowJar -PVERSION_NAME="$VERSION" --quiet --console=plain || {
    echo "❌ Gradle shadow failed"
    exit 1
}
echo "✓ Shadow JAR created"
echo ""

# Verify shadowing
echo "7. Verifying shadowed classes..."
SHADOWED_COUNT=$(jar -tf android-scx/shadow/build/libs/webrtc-shadowed.jar | grep "cx/smile/org/webrtc" | wc -l)
if [ "$SHADOWED_COUNT" -gt 0 ]; then
    echo "✓ Found $SHADOWED_COUNT shadowed classes (cx/smile/org/webrtc/*)"
    jar -tf android-scx/shadow/build/libs/webrtc-shadowed.jar | grep "cx/smile/org/webrtc" | head -5
else
    echo "❌ No shadowed classes found!"
    exit 1
fi
echo ""

# Replace classes.jar with shadowed version
echo "8. Repackaging AAR..."
cp android-scx/shadow/build/libs/webrtc-shadowed.jar aar-extract/classes.jar
cd aar-extract
zip -q -r ../libscxwebrtc-shadowed.aar *
cd ..
echo "✓ Shadowed AAR created ($(du -h libscxwebrtc-shadowed.aar | cut -f1))"
echo ""

# Verify final AAR
echo "9. Final verification..."
unzip -q libscxwebrtc-shadowed.aar -d verify/
FINAL_COUNT=$(jar -tf verify/classes.jar | grep "cx/smile/org/webrtc" | wc -l)
if [ "$FINAL_COUNT" -gt 0 ]; then
    echo "✓ Final AAR contains $FINAL_COUNT shadowed classes"
else
    echo "❌ Final AAR verification failed!"
    exit 1
fi
rm -rf verify/
echo ""

# Upload back to release
echo "10. Uploading shadowed AAR to GitHub release..."
echo "This will replace the existing $AAR_NAME in release $VERSION"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. Shadowed AAR saved to: $WORK_DIR/libscxwebrtc-shadowed.aar"
    echo "You can manually upload it to the release."
    trap - EXIT  # Don't delete work dir
    exit 0
fi

# Delete old asset and upload new one
gh release upload "$VERSION" \
    --repo "$REPO" \
    --clobber \
    libscxwebrtc-shadowed.aar#libscxwebrtc.aar || {
    echo "❌ Failed to upload AAR"
    exit 1
}

echo ""
echo "=================================================="
echo "✓ SUCCESS!"
echo "=================================================="
echo "Release $VERSION has been updated with shadowed AAR"
echo "Download: https://github.com/$REPO/releases/download/$VERSION/$AAR_NAME"
echo ""
