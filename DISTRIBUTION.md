# Distribution Guide - Android

This repository publishes SmileCX WebRTC as an AAR via JitPack.

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
    implementation 'com.github.smile-cx:webrtc-android-scx:M144'
}
```

Or using version catalogs:

```toml
[versions]
smilecx-webrtc = "M144"

[libraries]
smilecx-webrtc = { module = "com.github.smile-cx:webrtc-android-scx", version.ref = "smilecx-webrtc" }
```

## For Maintainers - Publishing New Releases

### 1. Build & Release (via GitHub Actions)

The workflow automatically:
- Builds WebRTC AAR with SmileCX prefixes
- Creates GitHub release with tag `M<milestone>` and asset `libscxwebrtc.aar`
- Examples: `M144`, `M146`, `M150`

### 2. JitPack Automatic Build

JitPack automatically builds when:
1. User requests the version
2. GitHub release exists with matching tag
3. `libscxwebrtc.aar` is present in release assets

**No manual steps needed!** JitPack will:
- Download AAR from GitHub release
- Publish to Maven repository
- Cache for future requests

### 3. Verify JitPack Build

Check build status: https://jitpack.io/com/github/smile-cx/webrtc-android-scx/<version>/build.log

Example: https://jitpack.io/com/github/smile-cx/webrtc-android-scx/M144/build.log

## Versioning

We use simple milestone tags: `M<milestone>`
- Examples: `M144`, `M146`, `M150`
- Corresponds to WebRTC milestone versions

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
