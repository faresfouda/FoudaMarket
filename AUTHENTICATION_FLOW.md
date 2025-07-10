# FoudaMarket Authentication Flow

## Overview
The authentication system has been reorganized to provide a more managed and user-friendly experience with three distinct authentication methods.

## Authentication Methods

### 1. Email/Password Authentication
- **Entry Point**: Main SignIn screen → "تسجيل الدخول بالبريد الإلكتروني" button
- **Screens**:
  - `Login.dart` - Email and password login
  - `Signup.dart` - New account creation with email/password
- **Features**:
  - Email validation
  - Password strength requirements
  - Forgot password functionality
  - Role selection (user, admin, data_entry)
  - Form validation and error handling

### 2. Phone/OTP Authentication
- **Entry Point**: Main SignIn screen → "تسجيل الدخول برقم الهاتف" button
- **Screens**:
  - `Number.dart` - Phone number input
  - `OtpScreen` - OTP verification (embedded in Number.dart)
- **Features**:
  - Phone number validation
  - SMS OTP verification
  - Auto-verification support
  - Resend OTP with 60-second cooldown
  - Loading states and error handling

### 3. Google Authentication
- **Entry Point**: Main SignIn screen → "تسجيل الدخول بجوجل" button
- **Features**:
  - One-tap Google Sign-In
  - Automatic user profile creation
  - Seamless integration with Firebase Auth
  - Error handling for cancelled sign-in

## Screen Flow

```
SignIn.dart (Main Hub)
├── Email/Password Flow
│   ├── Login.dart
│   └── Signup.dart
├── Phone/OTP Flow
│   ├── Number.dart (Phone Input)
│   └── OtpScreen (OTP Verification)
└── Google Flow
    └── Direct authentication via Google Sign-In
```

## Key Features

### Centralized Management
- **SignIn.dart** serves as the main authentication hub
- All authentication methods are accessible from one screen
- Consistent navigation with back buttons
- Unified error handling and loading states

### User Experience
- Clear visual hierarchy with icons and colors
- Arabic language support throughout
- Responsive design for different screen sizes
- Loading indicators for all async operations

### Security
- Firebase Authentication integration
- Secure token management
- Role-based access control
- Input validation and sanitization

## Technical Implementation

### Dependencies
```yaml
dependencies:
  firebase_auth: ^latest
  google_sign_in: ^6.2.1
  flutter_bloc: ^8.1.4
  get: ^4.7.2
```

### State Management
- **BLoC Pattern** for authentication state management
- **AuthBloc** handles all authentication events
- **AuthState** tracks authentication status
- **AuthEvent** defines user actions

### Services
- **FirebaseService** - Email/password authentication
- **GoogleAuthService** - Google Sign-In integration
- **PhoneAuthService** - OTP verification (embedded)

## Navigation Flow

1. **App Launch** → SignIn.dart (Main Hub)
2. **User selects authentication method**:
   - Email/Password → Login.dart or Signup.dart
   - Phone/OTP → Number.dart → OtpScreen
   - Google → Direct authentication
3. **Successful authentication** → Role-based navigation:
   - Admin → AdminDashboardMain
   - User → MainScreen
   - Data Entry → Data Entry Screen

## Error Handling

### Common Error Scenarios
- Invalid email format
- Weak password
- Phone number validation
- OTP timeout/incorrect code
- Network connectivity issues
- Google Sign-In cancellation

### Error Messages
- Localized Arabic error messages
- User-friendly error descriptions
- Actionable error recovery options

## Future Enhancements

### Planned Features
- Facebook authentication
- Apple Sign-In (iOS)
- Biometric authentication
- Two-factor authentication
- Account linking (merge email and phone accounts)

### Security Improvements
- Rate limiting for OTP requests
- Advanced password policies
- Session management
- Audit logging

## Configuration

### Firebase Setup
1. Enable Authentication in Firebase Console
2. Configure Email/Password provider
3. Configure Phone Number provider
4. Configure Google Sign-In provider
5. Set up Firestore security rules

### Google Sign-In Setup
1. Configure OAuth 2.0 client ID
2. Add SHA-1 fingerprint to Firebase project
3. Update google-services.json
4. Configure iOS bundle ID (if applicable)

## Testing

### Test Scenarios
- Email/password registration and login
- Phone number verification flow
- Google Sign-In integration
- Error handling and edge cases
- Role-based navigation
- Form validation

### Test Data
- Valid/invalid email addresses
- Strong/weak passwords
- Valid/invalid phone numbers
- Test OTP codes
- Different user roles

## Maintenance

### Regular Tasks
- Monitor authentication success rates
- Review error logs
- Update dependencies
- Test authentication flows
- Monitor Firebase usage

### Troubleshooting
- Check Firebase configuration
- Verify Google Sign-In setup
- Review network connectivity
- Validate phone number format
- Check OTP delivery status 