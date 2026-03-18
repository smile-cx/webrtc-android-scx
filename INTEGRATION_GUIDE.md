# Integration Guide

The `libscxwebrtc.aar` artifact in GitHub releases is **pre-shadowed** and ready to use directly.

## Direct AAR Usage (Recommended for VivochaSDK)

### Download from GitHub Releases

```bash
# Download latest release
wget https://github.com/smile-cx/webrtc-android-scx/releases/download/146/libscxwebrtc.aar
```

### Bundle in Your SDK

**Directory structure:**
```
VivochaSDK/
├── libs/
│   └── libscxwebrtc.aar    # Pre-shadowed, ready to use
└── build.gradle
```

**build.gradle with flavors:**
```gradle
android {
    flavorDimensions "capability"

    productFlavors {
        chatOnly {
            dimension "capability"
            // No WebRTC
        }

        multimedia {
            dimension "capability"
            // WebRTC bundled
        }
    }
}

dependencies {
    // Other dependencies...

    // WebRTC only for multimedia flavor
    multimediaImplementation files('libs/libscxwebrtc.aar')
}
```

### What's Included

The AAR contains:
- ✅ **Shadowed Java classes**: `cx.smile.org.webrtc.*` (relocated from `org.webrtc.*`)
- ✅ **Native libraries**: `libjingle_peerconnection_so.so` with JNI prefix `Java_cx_smile_org_webrtc_*`
- ✅ **All architectures**: armeabi-v7a, arm64-v8a, x86, x86_64

### Customer Usage

Your customers just add your SDK:

```gradle
// Chat-only version
implementation 'cx.smile:vivocha-sdk-chat-only:1.0.0'

// Or multimedia version (with WebRTC bundled)
implementation 'cx.smile:vivocha-sdk-multimedia:1.0.0'
```

**No extra repositories needed!** ✅

## Alternative: JitPack (Optional)

If you prefer Maven dependencies:

```gradle
repositories {
    maven { url 'https://jitpack.io' }
}

dependencies {
    implementation 'com.github.smile-cx:webrtc-android-scx:146'
}
```

**Note**: JitPack just republishes the pre-shadowed AAR from GitHub releases.

## Automation

### Auto-download Latest AAR

Add to your SDK's Gradle build:

```gradle
task downloadWebRTC {
    doLast {
        def version = "146"  // Or read from version.properties
        def aarUrl = "https://github.com/smile-cx/webrtc-android-scx/releases/download/${version}/libscxwebrtc.aar"
        def aarFile = file("libs/libscxwebrtc.aar")

        if (!aarFile.exists()) {
            println "Downloading WebRTC ${version}..."
            aarFile.parentFile.mkdirs()
            new URL(aarUrl).withInputStream { i ->
                aarFile.withOutputStream { it << i }
            }
            println "✓ Downloaded libscxwebrtc.aar"
        }
    }
}

// Run before build
preBuild.dependsOn downloadWebRTC
```

## Verification

Check that classes are shadowed:

```bash
# Extract AAR
unzip -q libscxwebrtc.aar -d verify/

# Check for shadowed classes
jar -tf verify/classes.jar | grep "cx/smile/org/webrtc" | head -10

# Expected output:
# cx/smile/org/webrtc/AddIceObserver.class
# cx/smile/org/webrtc/AndroidVideoDecoder.class
# ...
```

## Updates

When a new WebRTC version is released:
1. Download new AAR: `wget https://github.com/smile-cx/webrtc-android-scx/releases/download/147/libscxwebrtc.aar`
2. Replace `libs/libscxwebrtc.aar` in your SDK
3. Release new VivochaSDK version

## Support

- **Issues**: https://github.com/smile-cx/webrtc-android-scx/issues
- **Releases**: https://github.com/smile-cx/webrtc-android-scx/releases
