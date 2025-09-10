@echo off
echo Starting deployment preparation...

echo Step 1: Building Flutter web app...
call flutter build web --release
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Step 2: Copying files to root directory...

:: Copy main files
copy "build\web\main.dart.js" "." >nul 2>&1
copy "build\web\flutter_service_worker.js" "." >nul 2>&1
copy "build\web\version.json" "." >nul 2>&1
copy "build\web\favicon.png" "." >nul 2>&1

:: Copy directories
xcopy "build\web\assets" "assets\" /E /I /Y >nul 2>&1
xcopy "build\web\canvaskit" "canvaskit\" /E /I /Y >nul 2>&1
xcopy "build\web\icons" "icons\" /E /I /Y >nul 2>&1
xcopy "build\web\splash" "splash\" /E /I /Y >nul 2>&1

echo Step 3: Files copied successfully!
echo Ready for Vercel deployment.
echo.
echo Next steps:
echo 1. Commit and push to GitHub
echo 2. Deploy to Vercel
echo.
pause
