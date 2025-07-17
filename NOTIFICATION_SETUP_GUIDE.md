# دليل إعداد نظام الإشعارات - Fouda Market

## المشكلة
تم تغيير حالة الطلب ولم تصل الإشعارات للمستخدمين. هذا الدليل يوضح كيفية إصلاح وإعداد نظام الإشعارات.

## الحلول المتاحة

### 1. Firebase Functions (الحل المفضل)

Firebase Functions موجودة بالفعل في `functions/index.js` وتعمل تلقائياً عند تحديث حالة الطلب.

#### كيفية التأكد من عمل Firebase Functions:

1. **تأكد من نشر Firebase Functions:**
```bash
cd functions
npm install
firebase deploy --only functions
```

2. **تحقق من سجلات Firebase Functions:**
- اذهب إلى [Firebase Console](https://console.firebase.google.com/)
- اختر مشروعك
- اذهب إلى Functions > Logs
- ابحث عن `sendOrderStatusNotification`

3. **اختبار Firebase Functions:**
```bash
firebase functions:log
```

### 2. HTTP API (الحل البديل)

إذا لم تعمل Firebase Functions، يمكن استخدام HTTP API.

#### إعداد Vercel API:

1. **إنشاء مشروع Vercel جديد:**
```bash
# انسخ مجلد fcm-api إلى مشروع Vercel منفصل
cp -r fcm-api/ fouda-market-api/
cd fouda-market-api
```

2. **إعداد متغيرات البيئة في Vercel:**
- اذهب إلى [Vercel Dashboard](https://vercel.com/dashboard)
- اختر مشروعك
- اذهب إلى Settings > Environment Variables
- أضف:
  - `FCM_SERVICE_ACCOUNT_JSON`: محتوى ملف `fouda-market-60e939162657.json`

3. **نشر API:**
```bash
vercel --prod
```

4. **تحديث الرابط في الكود:**
في `lib/core/services/order_service.dart`، السطر 144:
```dart
final endpoint = 'https://YOUR-VERCEL-URL.vercel.app/api/send-fcm';
```

### 3. Firebase Admin SDK (الحل المحلي)

#### إعداد Firebase Admin SDK:

1. **تحميل Service Account Key:**
- اذهب إلى [Firebase Console](https://console.firebase.google.com/)
- اذهب إلى Project Settings > Service Accounts
- انقر على "Generate new private key"
- احفظ الملف كـ `service-account-key.json`

2. **إضافة التبعية:**
```yaml
# في pubspec.yaml
dependencies:
  firebase_admin: ^0.2.0
```

3. **استخدام Admin SDK:**
```dart
import 'package:firebase_admin/firebase_admin.dart';

// تهيئة Admin SDK
final serviceAccount = ServiceAccount.fromFile('service-account-key.json');
FirebaseAdmin.instance.initializeApp(
  credential: serviceAccount,
  projectId: 'fouda-market',
);

// إرسال إشعار
await FirebaseAdmin.instance.messaging().sendToDevice(
  fcmToken,
  Message(
    notification: Notification(
      title: 'تحديث حالة الطلب',
      body: 'تم تحديث حالة طلبك',
    ),
    data: {'orderId': orderId, 'status': status},
  ),
);
```

## اختبار الإشعارات

### 1. اختبار Firebase Functions:
```dart
// في أي مكان في التطبيق
final orderService = OrderService();
await orderService.updateOrderStatus('ORDER_ID', 'preparing');
```

### 2. اختبار HTTP API:
```dart
final orderService = OrderService();
await orderService.testNotification(
  fcmToken: 'USER_FCM_TOKEN',
  orderId: 'ORDER_ID',
  status: 'preparing',
);
```

### 3. التحقق من FCM Token:
```dart
// في main.dart
Future<void> _printFcmToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print('🔑 [FCM] Device Token: ${token}');
}
```

## استكشاف الأخطاء

### 1. لا يوجد FCM Token:
- تأكد من أن المستخدم سجل الدخول
- تأكد من إعطاء إذن الإشعارات
- تحقق من حفظ Token في Firestore

### 2. Firebase Functions لا تعمل:
- تحقق من نشر Functions
- تحقق من سجلات Firebase Console
- تأكد من إعدادات Firestore Rules

### 3. HTTP API لا يعمل:
- تحقق من نشر Vercel API
- تحقق من متغيرات البيئة
- تحقق من سجلات Vercel

### 4. الإشعارات لا تصل:
- تحقق من إعدادات التطبيق
- تأكد من أن التطبيق في الخلفية
- تحقق من إعدادات الجهاز

## الأوامر المفيدة

```bash
# نشر Firebase Functions
firebase deploy --only functions

# عرض سجلات Firebase Functions
firebase functions:log

# نشر Vercel API
vercel --prod

# عرض سجلات Vercel
vercel logs

# اختبار FCM Token
curl -X POST https://fcm.googleapis.com/v1/projects/fouda-market/messages:send \
  -H "Authorization: Bearer YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "USER_FCM_TOKEN",
      "notification": {
        "title": "Test",
        "body": "Test notification"
      }
    }
  }'
```

## ملاحظات مهمة

1. **Firebase Functions** هي الحل المفضل لأنها تعمل تلقائياً
2. **HTTP API** مفيد للاختبار والتحكم المباشر
3. **Admin SDK** مفيد للتطبيقات المحلية
4. تأكد من حفظ FCM Token عند تسجيل الدخول
5. اختبر الإشعارات على أجهزة حقيقية وليس محاكيات فقط 