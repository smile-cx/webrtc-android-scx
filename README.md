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

## License and Third-Party Notices

This repository contains modified versions of WebRTC and related third-party software components.

### Original WebRTC License

WebRTC is licensed under the BSD 3-Clause License.
Copyright (c) 2011, The WebRTC project authors. All rights reserved.

### Modifications

This distribution includes WebRTC source code that has been modified by SmileCX. Modifications include:

- **Native (JNI) symbol prefixing**: JNI method names and native library names have been modified to prevent symbol collisions
- **Java package relocation**: All Java packages have been relocated from `org.webrtc.*` to `cx.smile.org.webrtc.*` using the Gradle Shadow plugin
- **Build system modifications**: Build scripts and configuration files have been modified to support custom symbol prefixing

All modifications are documented in:
- Source patches: `patches/jni_prefix_smile.patch`
- Build scripts: `scripts/`
- Distribution module: `android-scx/`

Modified files carry changes as documented in the repository history and patch files. This modified distribution should not be confused with the official upstream WebRTC project.

### Third-Party Components

WebRTC includes multiple third-party components under various licenses, including:
- **BSD 3-Clause**: WebRTC core, libc++, libc++abi, libsrtp, libvpx, libyuv, opus, usrsctp, zlib
- **Apache 2.0**: abseil-cpp, boringssl, protobuf
- **MIT and other permissive licenses**: Various components (see LICENSE.md)

Where applicable, this distribution preserves all original copyright notices, license texts, and attribution requirements from upstream components.

### License Files

- **[LICENSE.md](LICENSE.md)**: Complete license texts for WebRTC and all third-party components
- **[NOTICE](NOTICE)**: Modification notices and attribution information for this distribution

### Upstream References

- Upstream WebRTC: https://webrtc.googlesource.com/src
- WebRTC License: https://webrtc.googlesource.com/src/+/main/LICENSE

## References

- [WebRTC Official Documentation](https://webrtc.googlesource.com/src/+/main/docs/native-code/android/index.md)
- [Shadow Gradle Plugin](https://github.com/johnrengelman/shadow)
- [Fat-aar Android Plugin](https://github.com/kezong/fat-aar-android)
