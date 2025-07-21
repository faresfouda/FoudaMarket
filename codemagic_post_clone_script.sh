#!/bin/sh
set -e
set -x

echo "🚀 Starting BEST PRACTICE Codemagic build process..."

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Clean Flutter build cache
echo "🧹 Cleaning Flutter build cache..."
flutter clean

# Build iOS for simulator to generate xcconfig (no signing needed)
echo "🔨 Building iOS simulator to generate xcconfig..."
flutter build ios --simulator

# Fix CocoaPods issues for CI
cd ios

# Patch all plugin podspecs to require iOS 14.0
find .symlinks/plugins -name "*.podspec" -exec sed -i 's/s.ios.deployment_target = .*/s.ios.deployment_target = "14.0"/' {} +
# Patch all podspecs in the iOS directory tree to require iOS 14.0
find . -name "*.podspec" -exec sed -i 's/s.ios.deployment_target = .*/s.ios.deployment_target = "14.0"/' {} +

echo "🧹 Performing BEST PRACTICE CocoaPods cleanup..."

# BEST PRACTICE: Complete cleanup of all CocoaPods artifacts
echo "🗑️  Removing all CocoaPods artifacts..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/ephemeral
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/.cocoapods
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean CocoaPods cache
echo "🧽 Cleaning CocoaPods cache..."
pod cache clean --all

# BEST PRACTICE: Update specs repository first
echo "📱 Updating CocoaPods specs repository..."
pod repo update

echo "📱 Installing CocoaPods dependencies with BEST PRACTICE strategy..."

# Strategy 1: Install with repo update (BEST PRACTICE)
echo "🔄 Attempt 1: pod install --repo-update (BEST PRACTICE)"
pod install --repo-update

# If the above fails, try Strategy 2: More aggressive cleanup
if [ $? -ne 0 ]; then
    echo "⚠️  Attempt 1 failed, trying Strategy 2..."
    echo "🔄 Attempt 2: Aggressive cleanup + pod install"
    rm -rf ~/Library/Caches/CocoaPods
    rm -rf ~/.cocoapods
    pod cache clean --all
    pod repo update
    pod install --repo-update
fi

# If still fails, try Strategy 3: Verbose debugging
if [ $? -ne 0 ]; then
    echo "⚠️  Attempt 2 failed, trying Strategy 3..."
    echo "🔄 Attempt 3: Verbose pod install for debugging"
    pod install --repo-update --verbose
fi

# If still fails, try Strategy 4: Remove all overrides temporarily
if [ $? -ne 0 ]; then
    echo "⚠️  Attempt 3 failed, trying Strategy 4..."
    echo "🔄 Attempt 4: pod install without any overrides"
    
    # Backup current Podfile
    cp Podfile Podfile.backup
    
    # Create a minimal Podfile without any overrides
    cat > Podfile.minimal << 'EOF'
source 'https://cdn.cocoapods.org/'
platform :ios, '14.0'
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter build ios is executed first."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting the file and running flutter build ios."
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['SWIFT_VERSION'] = '5.0'
    end
  end
end
EOF
    
    # Try with minimal Podfile
    mv Podfile.minimal Podfile
    pod install --repo-update
    
    # Restore original Podfile
    mv Podfile.backup Podfile
fi

# Final verification
echo "✅ Final verification..."
if [ -f Podfile.lock ]; then
    echo "📋 Podfile.lock created successfully"
    
    echo "🔍 Checking for GoogleUtilities version conflicts..."
    if grep -q "GoogleUtilities/Environment.*~> 8" Podfile.lock; then
        echo "⚠️  WARNING: GoogleUtilities/Environment version 8.x found"
        grep "GoogleUtilities/Environment" Podfile.lock
    else
        echo "✅ SUCCESS: No GoogleUtilities version 8.x conflicts found"
    fi
    
    if grep -q "FirebasePerformance" Podfile.lock; then
        echo "⚠️  WARNING: FirebasePerformance still found in Podfile.lock"
        cat Podfile.lock | grep -i firebase
    else
        echo "✅ SUCCESS: No FirebasePerformance references found"
    fi
    
    echo "📱 Checking deployment target compatibility..."
    if grep -q "IPHONEOS_DEPLOYMENT_TARGET.*14" Podfile.lock; then
        echo "✅ SUCCESS: iOS 14.0 deployment target found"
    else
        echo "ℹ️  INFO: Deployment target not explicitly set in Podfile.lock"
    fi
    
    echo "🎉 BEST PRACTICE CocoaPods installation completed successfully!"
else
    echo "❌ ERROR: Podfile.lock not found after all attempts"
    echo "📊 Build status: FAILED"
    exit 1
fi

echo "🚀 BEST PRACTICE build process completed!" 