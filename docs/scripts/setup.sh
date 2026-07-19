#!/bin/bash
# Signal Pro — Development Setup Script
# Run this to set up the Flutter development environment

set -e

echo "=== Signal Pro Setup ==="

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Install from https://flutter.dev"
    exit 1
fi

# Install dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# Generate Firebase options (if needed)
echo "Checking Firebase config..."
if [ ! -f lib/firebase_options.dart ]; then
    echo "Note: Firebase options not found. Using placeholder."
fi

# Build debug APK
echo "Building debug APK..."
flutter build apk --debug

echo "=== Setup complete! ==="
echo "APK: build/app/outputs/flutter-apk/app-debug.apk"
