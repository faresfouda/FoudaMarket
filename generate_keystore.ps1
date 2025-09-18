# PowerShell script to generate Android keystore and get SHA fingerprints for Firebase

Write-Host "Creating Android keystore for Firebase authentication..." -ForegroundColor Green

# Create keystore directory if it doesn't exist
$keystoreDir = "android\keystore"
if (!(Test-Path $keystoreDir)) {
    New-Item -ItemType Directory -Path $keystoreDir -Force
    Write-Host "Created keystore directory: $keystoreDir" -ForegroundColor Yellow
}

# Generate keystore file
$keystorePath = "android\keystore\fouda-market-keystore.jks"
$keytoolCmd = "keytool -genkeypair -v " +
    "-keystore `"$keystorePath`" " +
    "-keyalg RSA " +
    "-keysize 2048 " +
    "-validity 10000 " +
    "-alias fouda-market-key " +
    "-dname `"CN=Fouda Market, OU=Mobile App, O=Fouda Market, L=Cairo, ST=Cairo, C=EG`" " +
    "-storepass fouda123 " +
    "-keypass fouda123"

Write-Host "Generating keystore..." -ForegroundColor Yellow
Invoke-Expression $keytoolCmd

if (Test-Path $keystorePath) {
    Write-Host "Keystore created successfully!" -ForegroundColor Green
    
    # Get SHA-1 and SHA-256 fingerprints
    Write-Host "`nGetting SHA fingerprints for Firebase Console:" -ForegroundColor Green
    
    $fingerprintCmd = "keytool -list -v -keystore `"$keystorePath`" -alias fouda-market-key -storepass fouda123"
    $output = Invoke-Expression $fingerprintCmd
    
    Write-Host "`nFull keystore details:" -ForegroundColor Cyan
    Write-Host $output
    
    # Extract and highlight SHA fingerprints
    $sha1 = ($output | Select-String "SHA1:").ToString().Split(":")[1].Trim()
    $sha256 = ($output | Select-String "SHA256:").ToString().Split(":")[1].Trim()
    
    Write-Host "`n" + "="*60 -ForegroundColor Yellow
    Write-Host "IMPORTANT: Add these fingerprints to Firebase Console" -ForegroundColor Red
    Write-Host "="*60 -ForegroundColor Yellow
    Write-Host "SHA-1: $sha1" -ForegroundColor Green
    Write-Host "SHA-256: $sha256" -ForegroundColor Green
    Write-Host "="*60 -ForegroundColor Yellow
    
    Write-Host "`nSteps to add to Firebase:" -ForegroundColor Cyan
    Write-Host "1. Go to Firebase Console (console.firebase.google.com)" -ForegroundColor White
    Write-Host "2. Select your project: fouda-market" -ForegroundColor White
    Write-Host "3. Go to Project Settings > General" -ForegroundColor White
    Write-Host "4. Find your Android app" -ForegroundColor White
    Write-Host "5. Click 'Add fingerprint' in SHA certificate fingerprints section" -ForegroundColor White
    Write-Host "6. Add both SHA-1 and SHA-256 fingerprints above" -ForegroundColor White
    
} else {
    Write-Host "Failed to create keystore!" -ForegroundColor Red
    Write-Host "Make sure you have Java JDK installed and keytool is in your PATH" -ForegroundColor Yellow
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")