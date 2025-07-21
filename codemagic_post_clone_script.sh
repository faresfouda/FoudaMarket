#!/bin/sh
set -e
set -x

# Get dependencies
flutter pub get

# Build iOS for simulator to generate xcconfig (no signing needed)
flutter build ios --simulator

# Fix CocoaPods issues for CI
cd ios

# Aggressive cleanup of CocoaPods cache and files
rm -rf Pods
rm -rf Podfile.lock
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/.cocoapods

# Clean any Firebase Performance references from Podfile.lock if it exists
if [ -f Podfile.lock ]; then
    sed -i '' '/FirebasePerformance/d' Podfile.lock
    sed -i '' '/firebase_performance/d' Podfile.lock
fi

# Install pods with repo update (better for CI than separate pod repo update)
pod install --repo-update

# If the above fails, try with more aggressive cleanup
if [ $? -ne 0 ]; then
    echo "First pod install failed, trying with cache cleanup..."
    rm -rf ~/Library/Caches/CocoaPods
    rm -rf ~/.cocoapods
    pod cache clean --all
    pod install --repo-update
fi

# Final verification - check if Firebase Performance is still referenced
if grep -q "FirebasePerformance" Podfile.lock; then
    echo "WARNING: FirebasePerformance still found in Podfile.lock"
    cat Podfile.lock | grep -i firebase
else
    echo "SUCCESS: No FirebasePerformance references found"
fi 