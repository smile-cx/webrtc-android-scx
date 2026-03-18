# Java Package Shadowing Implementation

## Overview

This document explains the Java package shadowing/relocation mechanism implemented in this repository to prevent symbol collisions.

## Problem Statement

WebRTC libraries can conflict with each other when used in the same application:
- Multiple apps/SDKs may bundle different versions of WebRTC
- Native symbols and Java classes can collide
- Standard approach only handles native (JNI) prefixing

## Our Solution: Two-Layer Isolation

### Layer 1: Native/JNI Prefix (Applied at Build Time)

Applied via patches during WebRTC build:
- JNI method names: `Java_org_webrtc_*` → `Java_cx_smile_org_webrtc_*`
- Native library: `libjingle_peerconnection_so.so` → `libscxjingle_peerconnection_so.so`
- Package prefix: `cx/smile` in JNI headers

**Result**: `libscxwebrtc.aar` with prefixed native symbols

### Layer 2: Java Package Relocation (Applied in GitHub Workflow)

Applied via Gradle Shadow plugin during GitHub Actions build:
- Java packages: `org.webrtc.*` → `cx.smile.org.webrtc.*`
- Bytecode transformation (not source rewrite)
- All references updated automatically

**Result**: `libscxwebrtc.aar` in GitHub releases is pre-shadowed with both native and Java isolation

## Implementation Details

### Build Structure

```
webrtc-android-scx/
├── android-scx/                     # Main module
│   ├── build.gradle                # Fat-aar assembly
│   ├── src/main/jniLibs/           # Native .so files (copied)
│   └── shadow/                     # Shadow submodule
│       ├── build.gradle            # Shadow plugin config
│       └── libs/classes.jar        # Extracted from AAR
```

### Shadow Module (`android-scx/shadow/build.gradle`)

```gradle
plugins {
    id 'java-library'
    id 'com.github.johnrengelman.shadow' version '8.1.1'
}

dependencies {
    api files("libs/classes.jar")
}

shadowJar {
    relocate 'org.webrtc', 'cx.smile.org.webrtc'
}

task relocateShadowJar(type: ConfigureShadowRelocation) {
    target = tasks.shadowJar
    prefix = "cx.smile"
}
```

**Key Points:**
- Input: `classes.jar` extracted from `libscxwebrtc.aar`
- Process: Bytecode relocation using ASM library
- Output: Shadowed JAR with relocated packages

### Main Module (`android-scx/build.gradle`)

```gradle
plugins {
    id 'com.android.library'
    id 'com.kezong.fat-aar'
    id 'maven-publish'
}

dependencies {
    compileOnly project(path: ':android-scx:shadow', configuration: 'shadow')
    embed project(path: ':android-scx:shadow', configuration: 'shadow')
}
```

**Key Points:**
- Embeds shadowed JAR from shadow module
- Includes native libraries from `src/main/jniLibs/`
- Produces final AAR for distribution

## GitHub Workflow Shadowing

The shadowing happens automatically in GitHub Actions (`.github/workflows/`):

1. **Build Base AAR**: WebRTC build with JNI prefix → `libscxwebrtc.aar`
2. **Extract**: Unzip AAR to get `classes.jar` and native `.so` files
3. **Prepare**:
   - Copy `classes.jar` → `android-scx/shadow/libs/`
4. **Shadow**: Run `shadowJar` task to relocate Java packages
5. **Repackage**: Replace `classes.jar` in AAR with shadowed version
6. **Publish**: Upload pre-shadowed `libscxwebrtc.aar` to GitHub release

**Result**: GitHub releases contain fully shadowed AAR ready for direct use.

## JitPack Build Flow (Optional)

JitPack can republish the pre-shadowed AAR from GitHub releases:

1. **Download**: Fetch pre-shadowed `libscxwebrtc.aar` from GitHub release
2. **Republish**: Publish to JitPack Maven repository
3. **Cache**: Store for future requests

**Note**: Shadowing is already done in the GitHub workflow, so JitPack just republishes the artifact.

## Why This Approach?

### Advantages

1. **Complete Isolation**: Both native and Java layers are prefixed
2. **Build Time Separation**: JNI prefixing at build, Java relocation at distribution
3. **Transparent to Users**: Consumers just use different package names
4. **No Source Changes**: Bytecode manipulation preserves all functionality
5. **JitPack Compatible**: On-demand building from GitHub releases

### Alternatives Considered

1. **Source Code Rewrite**: Complex, breaks patches, hard to maintain
2. **JNI Only**: Leaves Java packages vulnerable to collision
3. **Manual Packaging**: Not scalable, error-prone

## Usage

### For Consumers

Import from relocated package:
```java
import cx.smile.org.webrtc.PeerConnection;
import cx.smile.org.webrtc.PeerConnectionFactory;
```

### For Maintainers

Test locally:
```bash
./prepare_aar.sh /path/to/libscxwebrtc.aar
./gradlew :android-scx:assembleRelease
```

## References

- Shadow Plugin: https://github.com/johnrengelman/shadow
- Fat-aar Plugin: https://github.com/kezong/fat-aar-android
