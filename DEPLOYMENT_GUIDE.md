# دليل نشر نظام الإشعارات - Fouda Market

## نظرة عامة
هذا الدليل يوضح كيفية نشر وإعداد نظام الإشعارات لتطبيق Fouda Market.

## الحلول المتاحة

### 1. Firebase Functions (مُوصى به)

#### الخطوات:

1. **تأكد من تثبيت Firebase CLI:**
```bash
npm install -g firebase-tools
```

2. **تسجيل الدخول إلى Firebase:**
```bash
firebase login
```

3. **تهيئة المشروع:**
```bash
firebase init functions
```

4. **تثبيت التبعيات:**
```bash
cd functions
npm install
```

5. **نشر Functions:**
```bash
firebase deploy --only functions
```

6. **التحقق من النشر:**
```bash
firebase functions:list
```

#### اختبار Firebase Functions:
```bash
# عرض السجلات
firebase functions:log

# اختبار Function
firebase functions:shell
```

### 2. Vercel API (بديل)

#### الخطوات:

1. **إعداد مشروع Vercel:**
```bash
cd fcm-api
npm install
```

2. **إعداد متغيرات البيئة:**
- اذهب إلى [Vercel Dashboard](https://vercel.com/dashboard)
- اختر مشروعك
- اذهب إلى Settings > Environment Variables
- أضف:
  - **Name**: `FCM_SERVICE_ACCOUNT_JSON`
  - **Value**: محتوى ملف `fouda-market-60e939162657.json`

3. **نشر API:**
```bash
vercel --prod
```

4. **اختبار API:**
```bash
npm run test
```

#### تحديث الرابط في التطبيق:
في `lib/core/services/order_service.dart`:
```dart
final endpoint = 'https://YOUR-VERCEL-URL.vercel.app/api/send-fcm';
```

## اختبار النظام

### 1. اختبار Firebase Functions:

```dart
// في التطبيق
final orderService = OrderService();
await orderService.updateOrderStatus('ORDER_ID', 'preparing');
```

### 2. اختبار HTTP API:

```dart
// في التطبيق
final orderService = OrderService();
await orderService.testNotification(
  fcmToken: 'USER_FCM_TOKEN',
  orderId: 'ORDER_ID',
  status: 'preparing',
);
```

### 3. اختبار من لوحة التحكم:

1. اذهب إلى شاشة إدارة الطلبات
2. اختر طلب
3. انقر على "اختبار الإشعار"
4. تحقق من وصول الإشعار

## استكشاف الأخطاء

### Firebase Functions:

1. **خطأ في النشر:**
```bash
firebase functions:log
```

2. **خطأ في التكوين:**
```bash
firebase functions:config:get
```

3. **إعادة نشر:**
```bash
firebase deploy --only functions --force
```

### Vercel API:

1. **خطأ في النشر:**
```bash
vercel logs
```

2. **خطأ في المتغيرات:**
```bash
vercel env ls
```

3. **إعادة نشر:**
```bash
vercel --prod --force
```

### التطبيق:

1. **لا يوجد FCM Token:**
- تحقق من تسجيل الدخول
- تحقق من إذن الإشعارات
- تحقق من حفظ Token في Firestore

2. **الإشعارات لا تصل:**
- تحقق من إعدادات الجهاز
- تأكد من أن التطبيق في الخلفية
- تحقق من سجلات Firebase Console

## الأوامر المفيدة

```bash
# Firebase Functions
firebase deploy --only functions
firebase functions:log
firebase functions:config:get
firebase functions:delete sendOrderStatusNotification

# Vercel API
vercel --prod
vercel logs
vercel env ls
vercel env add FCM_SERVICE_ACCOUNT_JSON

# اختبار
npm run test
curl -X POST https://your-api.vercel.app/api/send-fcm \
  -H "Content-Type: application/json" \
  -d '{"fcmToken":"TOKEN","title":"Test","body":"Test"}'
```

## مراقبة الأداء

### Firebase Functions:
- اذهب إلى [Firebase Console](https://console.firebase.google.com/)
- اختر مشروعك
- اذهب إلى Functions > Usage
- تحقق من الاستدعاءات والأخطاء

### Vercel API:
- اذهب إلى [Vercel Dashboard](https://vercel.com/dashboard)
- اختر مشروعك
- اذهب إلى Analytics
- تحقق من الطلبات والاستجابات

## الأمان

### Firebase Functions:
- استخدم Firestore Rules لتقييد الوصول
- تحقق من صلاحيات المستخدم
- استخدم Authentication

### Vercel API:
- استخدم متغيرات البيئة
- لا تشارك Service Account JSON
- قم بتقييد الوصول للـ API

## النسخ الاحتياطية

### Firebase Functions:
```bash
# تصدير Functions
firebase functions:config:get > functions-config.json

# استيراد Functions
firebase functions:config:set --config-file functions-config.json
```

### Vercel API:
```bash
# تصدير المتغيرات
vercel env pull .env.local

# استيراد المتغيرات
vercel env push
```

## الدعم

إذا واجهت مشاكل:

1. تحقق من السجلات
2. تأكد من الإعدادات
3. اختبر على جهاز حقيقي
4. تحقق من التوثيق الرسمي 