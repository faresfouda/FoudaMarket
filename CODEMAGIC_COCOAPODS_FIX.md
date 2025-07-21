# Codemagic CocoaPods Fix Guide

## Problem Description

You're encountering this error in Codemagic:
```
[!] CocoaPods could not find compatible versions for pod "GoogleUtilities/ISASwizzler":
  In Podfile:
    FirebasePerformance (~> 10.25.0) was resolved to 10.25.0, which depends on
      GoogleUtilities/ISASwizzler (~> 7.13)
```

## Root Cause

1. **Firebase Performance is disabled** in `pubspec.yaml` but the Podfile still has Firebase Performance overrides
2. **Codemagic's CocoaPods specs are out of date**
3. **Missing GoogleUtilities/ISASwizzler override** in Podfile

## Solution

### 1. Updated Podfile (Already Fixed)

The `ios/Podfile` has been updated to:
- Remove Firebase Performance overrides (since it's disabled)
- Add `GoogleUtilities/ISASwizzler` override
- Force all GoogleUtilities components to version 8.0

### 2. Updated Codemagic Post-Clone Script

Replace your current post-clone script with this optimized version:

```bash
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
```

### 3. Alternative: Re-enable Firebase Performance

If you need Firebase Performance monitoring, you can re-enable it:

1. **Uncomment in pubspec.yaml**:
```yaml
firebase_performance: ^0.9.4+7
```

2. **Update Podfile** to include Firebase Performance overrides:
```ruby
# Force Firebase Performance to use compatible versions
pod 'FirebasePerformance', '~> 10.25.0'
```

3. **Run Flutter pub get**:
```bash
flutter pub get
```

## Key Changes Made

### Podfile Changes:
- ✅ Removed `FirebasePerformance` override (since it's disabled)
- ✅ Added `GoogleUtilities/ISASwizzler` override
- ✅ All GoogleUtilities components forced to version 8.0

### Post-Clone Script Changes:
- ✅ Use `pod install --repo-update` instead of separate `pod repo update`
- ✅ Added cleanup of existing Pods and Podfile.lock
- ✅ Added fallback with cache cleanup if first attempt fails

## Testing the Fix

1. **Update your Codemagic post-clone script** with the new version
2. **Commit and push the changes**:
```bash
git add ios/Podfile codemagic_post_clone_script.sh CODEMAGIC_COCOAPODS_FIX.md
git commit -m "fix: update Podfile and Codemagic script for CI compatibility"
git push origin fares
```

3. **Trigger a new Codemagic build**

## Expected Result

After these changes, your Codemagic build should:
- ✅ Successfully install CocoaPods dependencies
- ✅ No more GoogleUtilities version conflicts
- ✅ Build proceed without CocoaPods errors

## Troubleshooting

### If you still get errors:

1. **Check if firebase_performance is being pulled in by other dependencies**:
```bash
flutter pub deps | grep firebase_performance
```

2. **Try completely removing firebase_performance**:
```bash
flutter pub remove firebase_performance
```

3. **Use a more aggressive Podfile cleanup**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
```

### If you need Firebase Performance:

1. **Re-enable it in pubspec.yaml**
2. **Update Podfile to include Firebase Performance overrides**
3. **Test locally first** before pushing to Codemagic

## Files Modified

1. `ios/Podfile` - Removed Firebase Performance overrides, added ISASwizzler
2. `codemagic_post_clone_script.sh` - Optimized for CI environment
3. `CODEMAGIC_COCOAPODS_FIX.md` - This guide

## Next Steps

1. Update your Codemagic post-clone script
2. Commit and push the changes
3. Test the build in Codemagic
4. Re-enable firebase_performance if needed (optional) 