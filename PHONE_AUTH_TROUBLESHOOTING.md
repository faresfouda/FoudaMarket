# Firebase Phone Authentication Setup Guide

## مشاكل تسجيل الدخول بالهاتف وحلولها:

### 1. مشكلة Certificate Hash:
```
E/FirebaseAuth: [GetAuthDomainTask] Error getting project config. Failed with INVALID_CERT_HASH 400
```

**الحل:**
1. تشغيل الأمر لإنشاء keystore:
```bash
keytool -genkeypair -v -keystore android/keystore/fouda-market-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fouda-market-key
```

2. الحصول على SHA-1 و SHA-256:
```bash
keytool -list -v -keystore android/keystore/fouda-market-keystore.jks -alias fouda-market-key
```

3. إضافة هذه البصمات في Firebase Console:
   - Project Settings > General > Your apps > Android app
   - SHA certificate fingerprints > Add fingerprint

### 2. مشكلة App Check:
```
W/LocalRequestInterceptor: Error getting App Check token; using placeholder token instead
```

**الحل:** تم إضافة Firebase App Check في `app_initializer.dart`

### 3. مشكلة reCAPTCHA:
```
E/zzb: Failed to initialize reCAPTCHA config: No Recaptcha Enterprise siteKey configured
```

**الحل:** 
1. تفعيل reCAPTCHA Enterprise في Firebase Console
2. إضافة Site Key في Firebase Auth settings

### 4. خطوات تشغيل التطبيق بعد الإصلاح:

1. تنظيف المشروع:
```bash
flutter clean && flutter pub get
```

2. إنشاء keystore جديد وإضافة البصمات لـ Firebase

3. تشغيل التطبيق:
```bash
flutter run
```

### 5. ملاحظات مهمة:
- تأكد من تفعيل Phone Authentication في Firebase Console
- أضف رقم الهاتف +2001060664231 في Test phone numbers إذا كان للاختبار
- تحقق من إعدادات Firebase App Check في Console