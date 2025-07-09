# Complete Firebase App Check Disable Guide

## The Problem
You're getting these errors:
```
W/LocalRequestInterceptor(13371): Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: Too many attempts.
```

This happens because Firebase App Check is still enabled in your Firebase Console, even though we removed the code from your app.

## Solution: Disable App Check in Firebase Console

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your FoudaMarket project

### Step 2: Navigate to App Check Settings
1. In the left sidebar, click on **"App Check"** (under "Build" section)
2. If you don't see "App Check", click on the gear icon (⚙️) next to "Project Overview" and select "Project settings"
3. In Project settings, look for "App Check" tab

### Step 3: Disable App Check for All Apps
1. You'll see a list of your apps (Android, iOS, Web)
2. For each app, click on the three dots menu (⋮) and select **"Disable App Check"**
3. Confirm the action when prompted

### Step 4: Disable App Check Enforcement
1. In the App Check section, look for **"Enforcement"** settings
2. Disable enforcement for:
   - **Authentication** (Firebase Auth)
   - **Firestore Database**
   - **Realtime Database** (if you use it)
   - **Storage** (if you use it)
   - **Functions** (if you use it)

### Step 5: Update Firestore Rules (if needed)
If you have Firestore rules that check for App Check, update them:

**Before (with App Check):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null && request.app != null;
    }
  }
}
```

**After (without App Check):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 6: Update Authentication Settings
1. Go to **Authentication** in the left sidebar
2. Click on **"Settings"** tab
3. Scroll down to **"App Check"** section
4. Disable **"Enforce App Check"** if it's enabled

### Step 7: Clear App Data and Rebuild
1. Stop your Flutter app
2. Clear app data:
   ```bash
   flutter clean
   flutter pub get
   ```
3. For Android, also clear the app data from your device/emulator
4. Rebuild and run the app

### Step 8: Verify the Fix
After completing all steps:
1. Run your app
2. Try to sign up or sign in
3. Check the console logs - you should NOT see any App Check errors

## Alternative: Temporary Debug Token (if you can't disable App Check)

If you can't disable App Check in the console, you can use debug tokens:

### For Android:
1. In your Android app, add this to `android/app/src/main/kotlin/com/example/fodamarket/MainActivity.kt`:
```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Add debug token for App Check
        val debugToken = "YOUR_DEBUG_TOKEN_HERE"
        // Note: You'll need to get this token from Firebase Console
    }
}
```

### For iOS:
1. In your iOS app, add this to `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        
        // Add debug token for App Check
        // Note: You'll need to get this token from Firebase Console
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

## Important Notes

1. **App Check is a security feature** - disabling it makes your app less secure
2. **For production apps**, consider implementing App Check properly instead of disabling it
3. **The "Too many attempts" error** usually means App Check is rate-limiting your requests
4. **After disabling App Check**, your authentication and database operations should work normally

## If You Still Get Errors

If you still see App Check errors after following these steps:

1. **Check if you have multiple Firebase projects** - make sure you're disabling App Check in the correct project
2. **Wait a few minutes** - changes in Firebase Console can take time to propagate
3. **Clear all app data** and restart your device/emulator
4. **Check Firebase Console logs** to see if there are any other issues

## Contact Firebase Support

If none of the above works, you may need to contact Firebase Support:
1. Go to Firebase Console
2. Click on the help icon (?) in the top right
3. Select "Contact support"
4. Explain that you need to disable App Check for your project 