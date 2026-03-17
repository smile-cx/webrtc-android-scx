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

### 1. Build & Release (via GitHub Actions)

The workflow automatically:
- Builds WebRTC AAR with SmileCX JNI prefixes (`libscxwebrtc.aar`)
- Creates GitHub release with tag `M<milestone>` and asset `libscxwebrtc.aar`
- Examples: `M144`, `M146`, `M150`

### 2. JitPack Automatic Build with Shadowing

JitPack automatically builds when:
1. User requests the version
2. GitHub release exists with matching tag
3. `libscxwebrtc.aar` is present in release assets

**JitPack Build Process:**
1. Downloads `libscxwebrtc.aar` from GitHub release
2. Extracts AAR contents (classes.jar + native libraries)
3. Uses Shadow Gradle plugin to relocate Java packages: `org.webrtc.*` → `cx.smile.org.webrtc.*`
4. Repackages with fat-aar plugin (shadowed JAR + native libs)
5. Publishes final AAR to JitPack Maven repository
6. Caches for future requests

### 3. Local Testing (Optional)

To test the shadowing process locally:

```bash
# Prepare AAR for shadowing
./prepare_aar.sh /path/to/libscxwebrtc.aar

# Build the shadowed AAR
./gradlew :android-scx:assembleRelease

# Find output at:
# android-scx/build/outputs/aar/android-scx-release.aar
```

### 4. Build Architecture

The repository uses a multi-module structure for shadowing:

```
webrtc-android-scx/
├── android-scx/              # Main module (fat-aar)
│   ├── shadow/              # Shadow submodule
│   │   ├── libs/            # Extracted classes.jar
│   │   └── build.gradle     # Shadow plugin config
│   ├── src/main/jniLibs/    # Native .so files
│   └── build.gradle         # Fat-aar assembly
└── build.gradle             # Root config
```

**Shadow Module**: Uses `com.github.johnrengelman.shadow` plugin to relocate all Java bytecode packages.

**Main Module**: Uses `com.kezong.fat-aar` plugin to embed the shadowed JAR and native libraries into a single AAR.

### 3. Verify JitPack Build

Check build status: https://jitpack.io/com/github/smile-cx/webrtc-android-scx/<version>/build.log

Example: https://jitpack.io/com/github/smile-cx/webrtc-android-scx/M144/build.log

## Versioning

We use milestone-based versioning:
- Git tag: milestone number only (e.g., `144`, `146`, `150`)
- Release title: milestone with M prefix (e.g., `M144`, `M146`)
- Release notes: include full WebRTC version (e.g., `146.7680.0`)

Example:
- Git tag: `146`
- Release title: `M146`
- Release notes: "WebRTC Version: 146.7680.0"
- User dependency: `com.github.smile-cx:webrtc-android-scx:146`

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
