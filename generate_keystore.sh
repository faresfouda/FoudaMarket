#!/bin/bash
# Script to generate Android keystore and get SHA fingerprints

echo "Creating Android keystore for Firebase authentication..."

# Create keystore directory
mkdir -p android/keystore

# Generate keystore
keytool -genkeypair -v \
  -keystore android/keystore/fouda-market-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias fouda-market-key \
  -dname "CN=Fouda Market, OU=Mobile App, O=Fouda Market, L=Cairo, ST=Cairo, C=EG" \
  -storepass fouda123 \
  -keypass fouda123

echo "Getting SHA-1 and SHA-256 fingerprints:"
keytool -list -v -keystore android/keystore/fouda-market-keystore.jks -alias fouda-market-key -storepass fouda123

echo ""
echo "Add these SHA fingerprints to Firebase Console:"
echo "Project Settings > General > Your apps > Android app > SHA certificate fingerprints"