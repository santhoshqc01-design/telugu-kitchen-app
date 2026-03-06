Write-Host "Starting Fast Build (ARM64)..." -ForegroundColor Cyan

# Ensure we are in the project root
$rootDir = (Get-Item -Path ".\").FullName
if (!(Test-Path "$rootDir\pubspec.yaml")) {
    Write-Error "Please run this script from the project root directory."
    exit
}

# Run Flutter build with optimizations
# - ARM64 only (standard for modern phones)
# - Split debug info (reduces APK size and improves build speed)
# - Obfuscate (optional but recommended for release)
flutter build apk --release --target-platform android-arm64 --split-debug-info=./build/app/outputs/debug_info --obfuscate

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[DONE] Build Successful!" -ForegroundColor Green
    Write-Host "Location: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Yellow
}
else {
    Write-Host "`n[ERROR] Build Failed!" -ForegroundColor Red
}
