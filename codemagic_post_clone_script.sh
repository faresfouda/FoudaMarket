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
echo "Installing CocoaPods dependencies..."
pod install --repo-update

# If the above fails, try with more aggressive cleanup
if [ $? -ne 0 ]; then
    echo "First pod install failed, trying with cache cleanup..."
    rm -rf ~/Library/Caches/CocoaPods
    rm -rf ~/.cocoapods
    pod cache clean --all
    echo "Retrying pod install with clean cache..."
    pod install --repo-update
fi

# Final verification - check if GoogleUtilities conflicts are resolved
if [ -f Podfile.lock ]; then
    echo "Checking for GoogleUtilities version conflicts..."
    if grep -q "GoogleUtilities/Environment.*~> 8" Podfile.lock; then
        echo "WARNING: GoogleUtilities/Environment version 8.x found - this may cause conflicts"
        grep "GoogleUtilities/Environment" Podfile.lock
    else
        echo "SUCCESS: No GoogleUtilities version 8.x conflicts found"
    fi
    
    if grep -q "FirebasePerformance" Podfile.lock; then
        echo "WARNING: FirebasePerformance still found in Podfile.lock"
        cat Podfile.lock | grep -i firebase
    else
        echo "SUCCESS: No FirebasePerformance references found"
    fi
else
    echo "ERROR: Podfile.lock not found after pod install"
    exit 1
fi

echo "CocoaPods installation completed successfully!" 