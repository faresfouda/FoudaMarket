# CocoaPods Dependency Conflict Resolution Guide

## Problem Description

You encountered a CocoaPods dependency conflict error when trying to build your Flutter iOS app:

```
GoogleUtilities/Environment (~> 7.13)
GoogleUtilities/Environment (~> 8.0)
```

This conflict occurs because:
- `firebase_performance` requires `GoogleUtilities/Environment (~> 7.13)`
- `google_sign_in_ios` requires `GoogleUtilities/Environment (~> 8.0)`

## Solutions Applied

### 1. Updated Podfile (Primary Solution)

The `ios/Podfile` has been enhanced with:

```ruby
# Force GoogleUtilities to use version 8.0 to resolve conflicts
pod 'GoogleUtilities', '~> 8.0'
pod 'GoogleUtilities/Environment', '~> 8.0'
pod 'GoogleUtilities/Logger', '~> 8.0'
pod 'GoogleUtilities/MethodSwizzler', '~> 8.0'

# Force Firebase Performance to use compatible versions
pod 'FirebasePerformance', '~> 10.25.0'

# Ensure AppCheckCore uses compatible version
pod 'AppCheckCore', '~> 11.0'
```

### 2. Temporarily Disabled firebase_performance (Alternative Solution)

If the above doesn't work, `firebase_performance` has been temporarily commented out in `pubspec.yaml`:

```yaml
# firebase_performance: ^0.9.4+7  # Temporarily disabled due to GoogleUtilities conflict
```

## Steps to Resolve (When you have access to iOS build environment)

### Option A: Use the Enhanced Podfile

1. **Clean up existing CocoaPods cache**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
```

2. **Install dependencies**:
```bash
pod install
```

3. **If issues persist, try deintegration**:
```bash
cd ios
pod deintegrate
pod install
```

### Option B: Re-enable firebase_performance (if needed)

If you need Firebase Performance monitoring:

1. **Uncomment the dependency in pubspec.yaml**:
```yaml
firebase_performance: ^0.9.4+7
```

2. **Run Flutter pub get**:
```bash
flutter pub get
```

3. **Follow Option A steps above**

### Option C: Update to Latest Firebase Versions

If you want to use the latest Firebase versions (may require code changes):

```yaml
firebase_core: ^3.15.1
firebase_auth: ^5.6.2
cloud_firestore: ^5.6.11
firebase_messaging: ^15.2.9
firebase_analytics: ^11.5.2
firebase_crashlytics: ^4.3.9
firebase_performance: ^0.10.1+9
firebase_remote_config: ^5.4.7
google_sign_in: ^7.1.1
```

## Current Configuration

Your project is now configured with:
- Enhanced Podfile with dependency overrides
- Temporarily disabled firebase_performance
- All other Firebase dependencies working normally

## Testing the Fix

To test if the fix works:

1. **On a Mac or iOS build environment**:
```bash
cd ios
pod install
```

2. **If successful, you should see**:
- No dependency conflicts
- All pods installed successfully
- Build should proceed without errors

## Troubleshooting

### If you still get conflicts:

1. **Try removing firebase_performance completely**:
   - Keep it commented out in pubspec.yaml
   - Remove any firebase_performance imports from your code

2. **Check for other conflicting dependencies**:
   - Look for any other packages that might require different GoogleUtilities versions

3. **Use a specific CocoaPods version**:
```bash
sudo gem install cocoapods -v 1.16.2
```

### If you need Firebase Performance:

1. **Try the latest version**:
```yaml
firebase_performance: ^0.10.1+9
```

2. **Update all Firebase dependencies together**:
   - This ensures better compatibility between Firebase packages

## Notes

- The `firebase_dynamic_links` package is discontinued, consider removing it
- Always test your app thoroughly after making dependency changes
- Consider using Firebase App Distribution for testing iOS builds on Windows

## Files Modified

1. `ios/Podfile` - Enhanced with dependency overrides
2. `pubspec.yaml` - Temporarily disabled firebase_performance
3. `COCOAPODS_DEPENDENCY_FIX.md` - This guide

## Next Steps

1. Test the build on an iOS environment
2. Re-enable firebase_performance if needed
3. Update to latest Firebase versions when ready
4. Remove discontinued firebase_dynamic_links dependency 