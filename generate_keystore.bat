@echo off
echo Creating Android keystore for Firebase authentication...

REM Create keystore directory if it doesn't exist
if not exist "android\keystore" mkdir "android\keystore"

REM Generate keystore file
keytool -genkeypair -v -keystore android/keystore/fouda-market-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fouda-market-key -dname "CN=Fouda Market, OU=Mobile App, O=Fouda Market, L=Cairo, ST=Cairo, C=EG" -storepass fouda123 -keypass fouda123

echo.
echo Keystore created successfully!
echo.
echo Getting SHA-1 fingerprint for Firebase Console:
keytool -list -v -keystore android/keystore/fouda-market-keystore.jks -alias fouda-market-key -storepass fouda123

echo.
echo Getting SHA-256 fingerprint for Firebase Console:
keytool -list -v -keystore android/keystore/fouda-market-keystore.jks -alias fouda-market-key -storepass fouda123 | findstr SHA256

echo.
echo Add these fingerprints to your Firebase project settings:
echo Project Settings > General > Your apps > Android app > SHA certificate fingerprints
echo.
pause