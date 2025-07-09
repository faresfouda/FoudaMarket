# Firebase Authentication with BLoC Integration

This document explains how Firebase authentication has been integrated with the BLoC pattern in the FoudaMarket app.

## Overview

The authentication system uses:
- **Firebase Auth** for authentication
- **Cloud Firestore** for user profile storage
- **BLoC pattern** for state management
- **Flutter BLoC** for reactive state management

## Architecture

### BLoC Structure

```
lib/blocs/auth/
├── auth_bloc.dart      # Main authentication BLoC
├── auth_event.dart     # Authentication events
├── auth_state.dart     # Authentication states
└── index.dart         # Export file
```

### Key Components

#### 1. AuthEvent (auth_event.dart)
Defines all authentication events:
- `SignInRequested` - User sign in
- `SignUpRequested` - User registration
- `SignOutRequested` - User sign out
- `PasswordResetRequested` - Password reset
- `AuthCheckRequested` - Check authentication status

#### 2. AuthState (auth_state.dart)
Defines all authentication states:
- `AuthInitial` - Initial state
- `AuthLoading` - Loading state
- `Authenticated` - User is authenticated
- `Unauthenticated` - User is not authenticated
- `AuthError` - Authentication error
- `PasswordResetSent` - Password reset email sent

#### 3. AuthBloc (auth_bloc.dart)
Handles all authentication logic:
- Manages authentication state
- Integrates with FirebaseService
- Provides Arabic error messages
- Handles user role-based navigation

## Usage Examples

### 1. Basic Authentication Check

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is Authenticated) {
      return HomeScreen();
    } else if (state is Unauthenticated) {
      return LoginScreen();
    } else {
      return LoadingScreen();
    }
  },
)
```

### 2. Sign In

```dart
// Trigger sign in
context.read<AuthBloc>().add(
  SignInRequested(
    email: 'user@example.com',
    password: 'password123',
  ),
);

// Listen for results
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is Authenticated) {
      // Navigate to home
    } else if (state is AuthError) {
      // Show error message
    }
  },
  child: YourWidget(),
)
```

### 3. Sign Up

```dart
context.read<AuthBloc>().add(
  SignUpRequested(
    email: 'user@example.com',
    password: 'password123',
    name: 'User Name',
    phone: '0123456789',
    role: 'user', // 'user', 'admin', 'data_entry'
  ),
);
```

### 4. Sign Out

```dart
context.read<AuthBloc>().add(SignOutRequested());
```

### 5. Password Reset

```dart
context.read<AuthBloc>().add(
  PasswordResetRequested(email: 'user@example.com'),
);
```

## Integration Points

### 1. Main App (main.dart)
The app provides the AuthBloc at the root level:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc()..add(AuthCheckRequested()),
    ),
  ],
  child: GetMaterialApp(
    home: AuthWrapper(),
  ),
)
```

### 2. Login Screen (lib/views/login/Login.dart)
- Form validation
- Real-time password visibility toggle
- Loading states
- Error handling
- Role-based navigation

### 3. Signup Screen (lib/views/signup/Signup.dart)
- Complete registration form
- Password confirmation
- Role selection
- Form validation
- Loading states

### 4. Profile Screen (lib/views/profile/profile_screen.dart)
- Display user information
- Sign out functionality
- Role-based UI

## User Roles

The system supports three user roles:

1. **user** - Regular customer
2. **admin** - Administrator with full access
3. **data_entry** - Data entry operator

Role-based navigation:
- `user` → MainScreen (customer interface)
- `admin` → AdminDashboardMain (admin interface)
- `data_entry` → DataEntryHomeScreen (data entry interface)

## Error Handling

The system provides Arabic error messages for common Firebase Auth errors:

- `user-not-found` → "لا يوجد مستخدم بهذا البريد الإلكتروني"
- `wrong-password` → "كلمة المرور غير صحيحة"
- `email-already-in-use` → "البريد الإلكتروني مستخدم بالفعل"
- `weak-password` → "كلمة المرور ضعيفة جداً"
- `invalid-email` → "البريد الإلكتروني غير صحيح"
- `too-many-requests` → "تم تجاوز الحد الأقصى للمحاولات، يرجى المحاولة لاحقاً"

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5
  firebase_auth: ^latest
  cloud_firestore: ^latest
```

## Security Rules

Ensure your Firestore security rules allow authenticated users to access their data:

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

## Testing

To test the authentication:

1. **Sign Up**: Create a new account with different roles
2. **Sign In**: Test with valid and invalid credentials
3. **Password Reset**: Test password reset functionality
4. **Sign Out**: Verify proper logout and navigation
5. **Role Navigation**: Test different user roles and their respective screens

## Best Practices

1. **Always use BlocListener** for side effects (navigation, showing messages)
2. **Use BlocBuilder** for UI updates based on state
3. **Validate forms** before sending authentication events
4. **Handle loading states** to provide good UX
5. **Provide meaningful error messages** in Arabic
6. **Use proper disposal** of controllers and BLoCs

## Troubleshooting

### Common Issues

1. **Firebase not initialized**: Ensure Firebase is initialized in main.dart
2. **Missing dependencies**: Run `flutter pub get` after adding dependencies
3. **Permission errors**: Check Firestore security rules
4. **Navigation issues**: Ensure proper context and route definitions

### Debug Mode

Enable debug mode to see BLoC events and state changes:

```dart
BlocOverrides.runZoned(
  () => runApp(MyApp()),
  blocObserver: SimpleBlocObserver(),
);
```

## Future Enhancements

1. **Social Authentication**: Add Google, Facebook, Apple sign-in
2. **Email Verification**: Require email verification for new accounts
3. **Two-Factor Authentication**: Add 2FA support
4. **Session Management**: Implement session timeout and refresh tokens
5. **Offline Support**: Cache user data for offline access 