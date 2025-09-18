@echo off
echo Installing CMake and NDK for Android development...

REM Navigate to Android SDK directory
cd /d "C:\Users\fares\AppData\Local\Android\sdk\cmdline-tools\latest\bin"

REM Install CMake
sdkmanager "cmake;3.22.1"

REM Install NDK if not already installed
sdkmanager "ndk;27.0.12077973"

echo Installation complete!
pause
