#!/bin/sh
set -e
set -x

# Get dependencies
flutter pub get

# Build iOS for simulator to generate xcconfig (no signing needed)
flutter build ios --simulator

# Fix CocoaPods issues for CI
cd ios

# Clean up any existing CocoaPods cache that might be causing issues
rm -rf Pods
rm -rf Podfile.lock

# Install pods with repo update (better for CI than separate pod repo update)
pod install --repo-update

# If the above fails, try with more aggressive cleanup
if [ $? -ne 0 ]; then
    echo "First pod install failed, trying with cache cleanup..."
    rm -rf ~/Library/Caches/CocoaPods
    pod install --repo-update
fi 