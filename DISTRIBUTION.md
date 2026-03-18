# Distribution Guide - Android

This repository publishes SmileCX WebRTC as an AAR via JitPack with complete symbol isolation.

## Symbol Collision Prevention

SmileCX WebRTC uses a two-layer approach to prevent symbol collisions:

1. **Native Layer**: All JNI symbols are prefixed with `scx` (e.g., `Java_cx_smile_org_webrtc_*`)
2. **Java Layer**: All Java packages are relocated from `org.webrtc.*` to `cx.smile.org.webrtc.*`

This ensures complete isolation from standard WebRTC libraries, preventing conflicts in applications that may use multiple WebRTC implementations.

## For Users - Installing via Gradle

### Add JitPack repository

In your root `build.gradle` or `settings.gradle`:

```gradle
repositories {
    maven { url 'https://jitpack.io' }
}
```

### Add dependency

In your app `build.gradle`:

```gradle
dependencies {
    implementation 'com.github.smile-cx:webrtc-android-scx:146'
}
```

Or using version catalogs:

```toml
[versions]
smilecx-webrtc = "146"

[libraries]
smilecx-webrtc = { module = "com.github.smile-cx:webrtc-android-scx", version.ref = "smilecx-webrtc" }
```

### Important: Package Names

When using this library, import WebRTC classes from the `cx.smile.org.webrtc` package:

```java
import cx.smile.org.webrtc.PeerConnection;
import cx.smile.org.webrtc.PeerConnectionFactory;
import cx.smile.org.webrtc.VideoTrack;
// etc.
```

## For Maintainers - Publishing New Releases

### Automated Daily Workflow

The repository has two GitHub Actions workflows:

1. **Scheduled Workflow** (`build_last_mstone.yml`) - Runs daily at midnight (UTC)
   - Checks for new stable WebRTC milestones
   - **Smart build detection**: Only rebuilds if new branch detected (~30 min)
   - **Fast path**: Reuses existing AAR if same branch (~1 min)
   - Applies shadowing automatically in the workflow

2. **On-Demand Workflow** (`build_mstones.yml`) - Manual trigger for specific milestones
   - Build specific milestone versions
   - Can reuse existing AAR or force rebuild

### What the Workflows Do

**For new WebRTC branches:**
1. Checkout WebRTC source
2. Apply SmileCX patches (JNI prefix: `scx`)
3. Build WebRTC AAR (`libscxwebrtc.aar`)
4. Apply Java package shadowing: `org.webrtc.*` → `cx.smile.org.webrtc.*`
5. Create/update milestone tag (e.g., `146`)
6. Create or update GitHub release with shadowed AAR

**For existing releases (same branch):**
1. Download existing AAR from release
2. Check if already shadowed
3. Apply shadowing if needed (~1 min vs ~30 min rebuild)
4. Update release with shadowed AAR
5. Skip tag push if only shadowing

### Shadowing Process (in GitHub Workflow)

The workflow applies Java package relocation using Gradle Shadow plugin:

```yaml
# Extract base AAR
unzip -q libscxwebrtc.aar -d aar-extract/

# Run shadow JAR creation
./gradlew :android-scx:shadow:shadowJar

# Replace classes.jar with shadowed version
cp android-scx/shadow/build/libs/webrtc-shadowed.jar aar-extract/classes.jar

# Repackage AAR
zip -r libscxwebrtc-shadowed.aar aar-extract/*
```

**Result**: `libscxwebrtc.aar` in GitHub releases is **pre-shadowed** and ready to use.

### Local Testing (Optional)

To test the shadowing process locally:

```bash
# Test shadowing existing release
./scripts/shadow_existing_release.sh 146
```

### Build Architecture

```
webrtc-android-scx/
├── android-scx/
│   └── shadow/              # Shadow submodule
│       ├── libs/            # Extracted classes.jar (workflow)
│       └── build.gradle     # Shadow plugin config
├── scripts/
│   └── shadow_existing_release.sh  # Local testing script
└── .github/workflows/       # Automated shadowing
```

### JitPack Distribution (Optional)

JitPack can republish the pre-shadowed AAR as a Maven dependency:

1. User requests version (e.g., `146`)
2. JitPack downloads pre-shadowed AAR from GitHub release
3. Publishes to Maven repository
4. Caches for future requests

Check build status: https://jitpack.io/com/github/smile-cx/webrtc-android-scx/<version>/build.log

**Note**: JitPack is optional. Users can download AAR directly from GitHub releases for bundling in their SDK (see [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)).

## Versioning

We use **milestone-only tags** with full version in release notes:

- **Milestone tag**: `146` (used for releases)
- **Release notes**: "WebRTC Version: 146.7680.0" (full version info)
- **Release title**: "M146"

When a new branch version is available (e.g., 146.7680.1), the workflow:
1. Detects new branch by parsing release notes
2. Rebuilds and shadows AAR
3. Force-updates milestone tag `146` to point to new commit
4. Updates release with new asset

**Benefits:**
- Tags remain clean and updatable
- Full version tracking in release body
- Pre-shadowed AAR ready for direct use or JitPack
- Daily automation prevents manual intervention

## License and Attribution

This distribution contains modified versions of WebRTC and related third-party components. All original license texts, copyright notices, and attribution requirements are preserved.

### Key Documentation

- **[LICENSE.md](LICENSE.md)**: Complete license texts for WebRTC and all third-party components
- **[NOTICE](NOTICE)**: Modification notices and attribution information
- **[patches/MODIFICATIONS.md](patches/MODIFICATIONS.md)**: Detailed documentation of all source code modifications

### Compliance Notes

This modified distribution satisfies the requirements of:
- BSD 3-Clause License (WebRTC): Copyright notices and license text preserved
- Apache 2.0 License (abseil-cpp, boringssl, protobuf): Modification notices documented, original licenses preserved
- Other component licenses: All notices and license texts preserved in LICENSE.md

The build process applies modifications via patch files and Gradle plugins. All modifications are documented and traceable via:
- Patch files in `patches/` directory
- Build scripts in `scripts/` directory
- Repository commit history
- NOTICE file and MODIFICATIONS.md documentation

## Troubleshooting

### JitPack build failed

1. Check that GitHub release exists: https://github.com/smile-cx/webrtc-android-scx/releases
2. Verify `libscxwebrtc.aar` is in release assets
3. Check JitPack build log for errors
4. Rebuild on JitPack: Visit https://jitpack.io/#smile-cx/webrtc-android-scx and click "Look up"

### Gradle sync failed

- Clear Gradle cache: `./gradlew clean --refresh-dependencies`
- Invalidate caches in Android Studio
- Check internet connection (JitPack needs to download from GitHub)
