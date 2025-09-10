#!/bin/bash
# Deploy script for Vercel

echo "Building Flutter web app..."
flutter build web --release

echo "Deployment ready. Upload the build/web folder to Vercel."
