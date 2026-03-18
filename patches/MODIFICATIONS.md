# WebRTC Modifications for SmileCX

This document describes the modifications made to upstream WebRTC source code in this distribution.

## Purpose

These modifications add symbol prefixing to prevent naming collisions when this WebRTC library is used alongside other WebRTC implementations in the same Android application.

## Modification Summary

### 1. Native (JNI) Symbol Prefixing

**Modified Files:**
- `sdk/android/api/org/webrtc/PeerConnectionFactory.java` - Updated library name reference
- `sdk/android/src/jni/jni_helpers.h` - Added JNI prefix macros
- `modules/video_coding/codecs/test/android_codec_factory_helper.cc` - Updated JNI class paths

**Changes:**
- Native library renamed: `libjingle_peerconnection_so.so` → `libscxjingle_peerconnection_so.so`
- JNI method names prefixed: `Java_org_webrtc_*` → `Java_cx_smile_org_webrtc_*`
- JNI class lookups hardcoded: `org/webrtc/*` → `cx/smile/org/webrtc/*`

**Note:** WebRTC M146 has built-in JNI prefix support. We use minimal patching by hardcoding the prefix in JNI helpers and factory code. The Java package relocation (via Gradle Shadow plugin) ensures JNI symbols match at runtime.

### 2. Build Configuration

**Modified Files:**
- `webrtc.gni` - Added android_package_prefix declaration

**Changes:**
- Added global `android_package_prefix = "cx/smile"` variable
- Used by build system for reference (though M146's JNI generation has changed)

### 3. Build Script Modifications

**Modified Files:**
- `tools_webrtc/android/build_aar.py` - Commented out automatic license generation

**Changes:**
- Line 323-324: Commented out `GenerateLicenses(license_dir, build_dir, archs)` call
- License information is instead maintained in the repository root (LICENSE.md, NOTICE)
- This ensures consistent licensing documentation across all distribution channels

## Application Method

These modifications are applied via patch file during the WebRTC build process:

```bash
# Patch is applied after WebRTC source checkout
git apply patches/jni_prefix_smile.patch
# or
patch -p1 < patches/jni_prefix_smile.patch
```

The patch file: `patches/jni_prefix_smile.patch`

## Additional Build-Time Modifications

Beyond the source code patches, the distribution build also applies:

### Java Package Relocation (Shadow Plugin)

**Method:** Gradle Shadow plugin during AAR repackaging
**Location:** `android-scx/shadow/build.gradle`

**Changes:**
- All Java bytecode packages relocated: `org.webrtc.*` → `cx.smile.org.webrtc.*`
- Applied to the extracted classes.jar from the patched WebRTC AAR
- Results in complete symbol isolation at both native and Java layers

## Compliance Notes

### License Requirements

**BSD 3-Clause (WebRTC core):**
- Requires: Copyright notice, license text, disclaimer in all redistributions
- Status: Preserved in LICENSE.md and NOTICE files

**Apache 2.0 (abseil-cpp, boringssl, protobuf):**
- Requires: Copyright notices, license text, modification notices (Section 4.b)
- Status: Original license texts preserved in LICENSE.md, modification notices documented in NOTICE and this file

### Modification Documentation

Per Apache License 2.0 Section 4(b), modified files must carry prominent notices stating that files have been changed. This requirement is satisfied by:

1. **This MODIFICATIONS.md file** - Documents all changes made to upstream sources
2. **NOTICE file** - Provides prominent notice of modifications in the distribution
3. **Patch file** - Complete record of all source code changes in `patches/jni_prefix_smile.patch`
4. **Repository history** - Git commits document when and why modifications were made
5. **README.md** - Describes modifications and clarifies this is not an official upstream release

### Source Availability

The complete modified source code, including all patches and build scripts, is available at:
https://github.com/smile-cx/webrtc-android-scx

The upstream WebRTC source code is available at:
https://webrtc.googlesource.com/src

## Version Tracking

Each release of this modified WebRTC distribution is tagged with the upstream WebRTC milestone and branch version. Example:
- Tag: `146` (milestone tag for distribution)
- Full version: `146.7680.0` (upstream WebRTC version)
- Release notes include link to upstream WebRTC branch

## Contact

For questions about these modifications:
- Repository: https://github.com/smile-cx/webrtc-android-scx
- Organization: SmileCX

For questions about upstream WebRTC:
- Official WebRTC: https://webrtc.org
- Source: https://webrtc.googlesource.com/src
