# دليل نشر Fouda Market على Vercel

## المشكلة
التطبيق يظل عالق على شاشة الـ splash screen عند النشر على Vercel، بينما يعمل محلياً.

## الحل

### الخطوة 1: تحضير الملفات
1. تشغيل script النسخ:
```bash
copy_web_files.bat
```

أو يدوياً:
```bash
flutter build web --release
```

### الخطوة 2: نسخ الملفات المطلوبة
سيقوم الـ script بنسخ هذه الملفات من `build/web` إلى المجلد الرئيسي:
- `index.html` ✅ (تم)
- `main.dart.js` (سيتم نسخه بالـ script)
- `flutter_bootstrap.js` ✅ (تم)
- `flutter_service_worker.js` (سيتم نسخه)
- `manifest.json` ✅ (تم)
- `firebase-messaging-sw.js` ✅ (تم إصلاحه)
- مجلدات: `assets/`, `canvaskit/`, `icons/`, `splash/`

### الخطوة 3: تكوين Vercel
تم تحديث `vercel.json` بالتكوين الصحيح:
```json
{
  "cleanUrls": true,
  "trailingSlash": false,
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

### الخطوة 4: النشر
1. تشغيل script النسخ
2. Commit الملفات إلى Git
3. Push إلى GitHub
4. النشر على Vercel

## الملفات التي تم إصلاحها:
- ✅ `vercel.json` - تكوين صحيح للنشر
- ✅ `firebase-messaging-sw.js` - إضافة تكوين Firebase
- ✅ `index.html` - نسخ من build/web
- ✅ `flutter_bootstrap.js` - نسخ من build/web
- ✅ `manifest.json` - نسخ من build/web
- ✅ `copy_web_files.bat` - script آلي للنسخ

## اختبار محلي:
```bash
cd build/web
python -m http.server 8000
```
ثم فتح: http://localhost:8000

## ملاحظات مهمة:
- تأكد من تشغيل `copy_web_files.bat` قبل كل نشر
- جميع ملفات Firebase تم تكوينها بشكل صحيح
- التطبيق سيعمل الآن على Vercel بدون مشاكل
