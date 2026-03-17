# SmileCX WebRTC for Android

Pre-built WebRTC library for Android with complete symbol isolation to prevent collisions with other WebRTC implementations.

## Overview

This repository provides WebRTC binaries for Android with SmileCX-prefixed symbols at both the native (JNI) and Java layers. This ensures that the Vivocha SDK won't have symbol collision with other libraries embedded in the customer app.

### Symbol Isolation Strategy

**Two-Layer Approach:**

1. **Native Layer (JNI)**: All native symbols are prefixed with `scx`
   - JNI methods: `Java_cx_smile_org_webrtc_*`
   - Native library: `libscxjingle_peerconnection_so.so`

2. **Java Layer**: All Java packages are relocated to `cx.smile`
   - Original: `org.webrtc.*`
   - Relocated: `cx.smile.org.webrtc.*`

This prevents conflicts with standard WebRTC libraries (`org.webrtc`) or other prefixed versions.

## Installation

Add JitPack to your repositories:

```gradle
repositories {
    maven { url 'https://jitpack.io' }
}
```

Add the dependency:

```gradle
dependencies {
    implementation 'com.github.smile-cx:webrtc-android-scx:146'
}
```

## Usage

Import WebRTC classes from the `cx.smile.org.webrtc` package:

```java
import cx.smile.org.webrtc.PeerConnection;
import cx.smile.org.webrtc.PeerConnectionFactory;
import cx.smile.org.webrtc.VideoTrack;
import cx.smile.org.webrtc.AudioTrack;

// Use as normal
PeerConnectionFactory factory = PeerConnectionFactory.builder().createPeerConnectionFactory();
```

## Versioning

We use milestone-based versioning:

- `144` - WebRTC Milestone 144
- `146` - WebRTC Milestone 146
- etc.

Each release includes the full WebRTC version in the release notes (e.g., 146.7680.0).

## How It Works

### Build Process

1. **WebRTC Build**: Patches are applied during build to add native (JNI) prefixes
   - Modifies package paths and JNI method names
   - Outputs: `libscxwebrtc.aar`

2. **Distribution Build** (JitPack):
   - Downloads `libscxwebrtc.aar` from GitHub releases
   - Extracts `classes.jar` and native libraries
   - Applies Java package relocation using Shadow Gradle plugin
   - Repackages with Fat-aar plugin
   - Publishes to JitPack Maven repository

### Architecture

```
webrtc-android-scx/
├── patches/                    # Patches for native symbol prefixing
│   └── jni_prefix_smile.patch # JNI package prefix modifications
├── scripts/                    # Build scripts
├── android-scx/               # Distribution module (for JitPack)
│   ├── shadow/                # Shadow submodule for package relocation
│   └── build.gradle           # Fat-aar assembly
└── .github/workflows/         # CI/CD for WebRTC builds
```

## Documentation

- **[DISTRIBUTION.md](DISTRIBUTION.md)**: Complete guide for users and maintainers
- **[SHADOWING.md](SHADOWING.md)**: Technical details of the shadowing implementation
- **[BUILD_REPLICATION_PLAN.md](BUILD_REPLICATION_PLAN.md)**: How to replicate the build system

## For Maintainers

See [DISTRIBUTION.md](DISTRIBUTION.md) for:
- Publishing new releases
- Testing the shadowing process locally
- JitPack build configuration

## License

WebRTC is licensed under the BSD 3-Clause License. See [LICENSE](LICENSE) for details.

## References

- [WebRTC Official Documentation](https://webrtc.googlesource.com/src/+/main/docs/native-code/android/index.md)
- [Shadow Gradle Plugin](https://github.com/johnrengelman/shadow)
- [Fat-aar Android Plugin](https://github.com/kezong/fat-aar-android)
