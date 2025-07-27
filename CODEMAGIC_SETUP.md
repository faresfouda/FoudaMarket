# Codemagic CI/CD Setup Guide for FoudaMarket

This guide explains how to set up and use the enhanced Codemagic configuration for the FoudaMarket Flutter app.

## 🚀 Available Workflows

### 1. **build_and_test** (Main Workflow)
- **Purpose**: Complete build with testing and quality assurance
- **Duration**: ~120 minutes
- **Features**:
  - Code analysis with `flutter analyze`
  - Unit tests with coverage reporting
  - iOS debug build (no code signing)
  - Android debug build
  - Test coverage reports as artifacts

### 2. **build_production** (Production Build)
- **Purpose**: Production-ready builds with proper signing
- **Duration**: ~120 minutes
- **Features**:
  - Quality checks (analysis + tests)
  - iOS code signing setup
  - iOS production build with IPA creation
  - Android release build
  - Properly signed artifacts

### 3. **test_only** (Quick Testing)
- **Purpose**: Fast testing for pull requests
- **Duration**: ~30 minutes
- **Features**:
  - Code analysis
  - Unit tests with coverage
  - No builds (testing only)

### 4. **build_development** (Device Testing)
- **Purpose**: Development builds for device testing
- **Duration**: ~90 minutes
- **Features**:
  - Quick quality check
  - iOS debug build for device installation
  - Android debug build

## 📱 iOS Device Installation Setup

### For Development Builds (No Code Signing Required)

1. **Use the `build_development` workflow**
2. **Download the `.app` file** from artifacts
3. **Install on your iPhone**:
   - Use Xcode to install the app
   - Or use tools like `ios-deploy`
   - The app will be in debug mode

### For Production Builds (Code Signing Required)

1. **Set up iOS Code Signing in Codemagic UI**:
   - Go to your project settings in Codemagic
   - Add these environment variables:
     ```
     CM_CERTIFICATE: Your iOS certificate (.p12 file)
     CM_CERTIFICATE_PASSWORD: Certificate password
     CM_PROVISIONING_PROFILE: Your provisioning profile
     CM_KEYCHAIN_PASSWORD: Keychain password
     ```

2. **Update `ios/exportOptions.plist`**:
   - Replace `YOUR_TEAM_ID` with your actual Apple Developer Team ID
   - Change `method` to `app-store` for App Store distribution
   - Change `method` to `ad-hoc` for internal testing

3. **Use the `build_production` workflow**
4. **Download the `.ipa` file** from artifacts
5. **Install on your iPhone**:
   - Use iTunes/Finder to install
   - Or use TestFlight for distribution

## 🧪 Testing Features

### Code Quality Checks
- **Flutter Analyze**: Static code analysis
- **Lint Rules**: Enforced through `analysis_options.yaml`
- **Code Coverage**: Generated HTML reports

### Test Coverage
- **Unit Tests**: Located in `test/` directory
- **Widget Tests**: UI component testing
- **Integration Tests**: App flow testing
- **Coverage Reports**: Available as build artifacts

### Running Tests Locally
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# Run code analysis
flutter analyze
```

## 🔧 Configuration Files

### `codemagic.yaml`
- Main CI/CD configuration
- Multiple workflows for different purposes
- Environment variables and scripts

### `ios/exportOptions.plist`
- iOS export configuration
- Code signing settings
- Distribution method settings

### `analysis_options.yaml`
- Dart/Flutter linting rules
- Code quality standards
- Custom lint configurations

## 📊 Build Artifacts

### Debug Builds
- `build/ios/iphoneos/*.app` - iOS app bundle
- `build/app/outputs/flutter-apk/app-debug.apk` - Android APK
- `coverage/html/**` - Test coverage reports
- `coverage/lcov.info` - Coverage data

### Production Builds
- `build/ios/iphoneos/*.app` - iOS app bundle
- `build/ios/*.ipa` - iOS IPA file
- `build/app/outputs/flutter-apk/app-release.apk` - Android APK

## 🚨 Troubleshooting

### iOS Build Issues
1. **CocoaPods Issues**:
   - The workflow includes CocoaPods cleanup
   - Check pod dependencies in `ios/Podfile`

2. **Code Signing Issues**:
   - Verify certificate and provisioning profile
   - Check Team ID in `exportOptions.plist`
   - Ensure certificates are valid and not expired

3. **Device Installation Issues**:
   - For debug builds: Use Xcode to install
   - For production builds: Ensure device is in provisioning profile

### Android Build Issues
1. **Gradle Issues**:
   - Check `android/build.gradle.kts`
   - Verify dependencies in `pubspec.yaml`

2. **Signing Issues**:
   - Configure keystore in Codemagic UI
   - Add signing configuration to `android/app/build.gradle.kts`

### Test Issues
1. **Test Failures**:
   - Check test files in `test/` directory
   - Verify model imports and dependencies
   - Run tests locally first

2. **Coverage Issues**:
   - Ensure `genhtml` is available
   - Check `lcov.info` file generation

## 🔄 Workflow Triggers

### Automatic Triggers
- **Push to main**: Triggers `build_and_test`
- **Pull Request**: Triggers `test_only`
- **Tag creation**: Triggers `build_production`

### Manual Triggers
- All workflows can be triggered manually
- Select appropriate workflow based on needs

## 📈 Best Practices

1. **Always run tests before merging**
2. **Use appropriate workflow for your needs**
3. **Monitor build times and optimize**
4. **Keep dependencies updated**
5. **Regular code quality checks**
6. **Test on real devices regularly**

## 🔐 Security Notes

- Never commit certificates or keys to repository
- Use Codemagic environment variables for sensitive data
- Regularly rotate certificates and keys
- Monitor build logs for sensitive information

## 📞 Support

For issues with:
- **Codemagic**: Check [Codemagic Documentation](https://docs.codemagic.io/)
- **Flutter**: Check [Flutter Documentation](https://docs.flutter.dev/)
- **iOS**: Check [Apple Developer Documentation](https://developer.apple.com/)
- **Android**: Check [Android Developer Documentation](https://developer.android.com/) 