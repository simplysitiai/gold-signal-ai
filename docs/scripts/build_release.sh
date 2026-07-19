#!/bin/bash
# Signal Pro — Release Build Script
# Builds a signed release APK

set -e

echo "=== Building Release APK ==="

# Check keystore
if [ ! -f android/app/keystore.jks ]; then
    echo "Warning: No keystore found. Building unsigned release."
    flutter build apk --release --no-shrink
else
    flutter build apk --release
fi

echo "=== Release APK built ==="
ls -lh build/app/outputs/flutter-apk/app-release.apk
