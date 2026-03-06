# Build Scripts for Telugu Cooking App

This directory contains scripts to speed up your Flutter build process.

## 🚀 Faster APK Building

Instead of the standard `flutter build apk`, use these scripts to save time:

### 1. Fast Build (ARM64 only) - **Recommended**
Most modern Android phones (last 5-7 years) use ARM64. Building only for this architecture is significantly faster.
*   **Command**: `powershell ./scripts/build_fast.ps1`
*   **What it does**: Builds a release APK specifically for ARM64, skips unnecessary architectures, and generates debug info symbols separately.

### 2. Standard Release (All Architectures)
Use this only when you need an APK that works on *any* Android device (older phones or tablets).
*   **Command**: `powershell ./scripts/build_release.ps1`

---

## 💡 Pro Tips for Speed
*   **Avoid `flutter clean`**: Only use it if you have actual errors. Gradle is now configured to use a cache.
*   **Model Management**: If you are not testing voice features, you can temporarily comment out the `assets/models/` line in `pubspec.yaml`.
