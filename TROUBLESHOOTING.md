# Troubleshooting Firebase Authentication Issues

## LocalRequestInterceptor Error

If you encounter the error:
```
W/LocalRequestInterceptor: Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.
```

### What This Means
This error occurs when Firebase App Check is not properly configured. App Check helps protect your Firebase resources from abuse.

### Solutions

#### 1. **Firebase App Check Configuration (Already Fixed)**
The main.dart has been updated to properly configure App Check:

```dart
// Configure Firebase App Check
await FirebaseAppCheck.instance.activate(
  // Use debug provider for development
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
```

#### 2. **Development vs Production**
- **Development**: Uses `AndroidProvider.debug` and `AppleProvider.debug`
- **Production**: Should use `AndroidProvider.playIntegrity` and `AppleProvider.deviceCheck`

#### 3. **Firebase Console Configuration**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **App Check** in the left sidebar
4. Enable App Check for your app
5. Configure the providers (Debug for development)

#### 4. **Network Issues**
If you're still having issues:
- Check your internet connection
- Ensure Firebase project is properly configured
- Verify API keys are correct

### Testing the Fix

1. **Clean and rebuild the app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test signup with these credentials:**
   - Email: `test@example.com`
   - Password: `password123`
   - Name: `Test User`
   - Phone: `0123456789`
   - Role: `user`

3. **Check the console logs** for:
   - "Starting signup process for: test@example.com"
   - "Signup successful, user ID: [some-id]"
   - "User profile retrieved: [profile-data]"

### Common Issues and Solutions

#### Issue 1: App Check Still Failing
**Solution**: Ensure you're using the debug provider in development:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
```

#### Issue 2: Firestore Permission Denied
**Solution**: Check your Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Issue 3: Network Timeout
**Solution**: Add timeout handling:
```dart
try {
  final credential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  ).timeout(Duration(seconds: 30));
} catch (e) {
  // Handle timeout
}
```

### Debug Mode

To see detailed logs, add this to your main.dart:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable debug mode
  if (kDebugMode) {
    print('Running in debug mode');
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
  runApp(FodaMarket());
}
```

### Production Deployment

When deploying to production:

1. **Update App Check providers:**
   ```dart
   await FirebaseAppCheck.instance.activate(
     androidProvider: AndroidProvider.playIntegrity,
     appleProvider: AppleProvider.deviceCheck,
   );
   ```

2. **Configure Firebase Console:**
   - Enable App Check for production
   - Add your app's SHA-1 fingerprint
   - Configure Play Integrity API (Android)
   - Configure Device Check API (iOS)

3. **Test thoroughly** before releasing

### Still Having Issues?

If you're still experiencing problems:

1. **Check Firebase Console** for any error messages
2. **Verify your google-services.json** is up to date
3. **Ensure all Firebase dependencies** are properly configured
4. **Test on a different device** or emulator
5. **Check your Firebase project settings** and billing status

### Contact Support

If none of the above solutions work:
1. Check the [Firebase documentation](https://firebase.google.com/docs/app-check)
2. Review the [Flutter Firebase documentation](https://firebase.flutter.dev/docs/overview/)
3. Check the [GitHub issues](https://github.com/FirebaseExtended/flutterfire/issues) for similar problems 