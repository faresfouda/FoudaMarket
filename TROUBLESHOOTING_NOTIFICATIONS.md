# استكشاف أخطاء نظام الإشعارات - Fouda Market

## المشاكل الشائعة وحلولها

### 1. لا تصل الإشعارات عند تغيير حالة الطلب

#### الأعراض:
- تم تغيير حالة الطلب بنجاح
- لا تصل إشعارات للمستخدم
- لا تظهر أخطاء في التطبيق

#### الحلول:

**أولاً: تحقق من Firebase Functions**

1. **تحقق من نشر Functions:**
```bash
firebase functions:list
```

2. **تحقق من السجلات:**
```bash
firebase functions:log
```

3. **إعادة نشر Functions:**
```bash
firebase deploy --only functions
```

**ثانياً: تحقق من FCM Token**

1. **تحقق من وجود Token:**
```dart
// في main.dart
Future<void> _printFcmToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print('🔑 [FCM] Device Token: ${token}');
}
```

2. **تحقق من حفظ Token في Firestore:**
```dart
// في Firestore
collection('users').doc(userId).get()
// تحقق من وجود حقل fcmToken
```

**ثالثاً: تحقق من إعدادات التطبيق**

1. **إذن الإشعارات:**
```dart
NotificationSettings settings = await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

2. **استقبال الإشعارات:**
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('🔔 [FCM] Received message: ${message.messageId}');
});
```

### 2. خطأ في Firebase Functions

#### الأعراض:
- أخطاء في سجلات Firebase Functions
- فشل في إرسال الإشعارات

#### الحلول:

**أولاً: تحقق من التكوين**

1. **تحقق من Service Account:**
```bash
firebase functions:config:get
```

2. **إعادة تعيين التكوين:**
```bash
firebase functions:config:unset
firebase functions:config:set
```

**ثانياً: تحقق من الكود**

1. **تحقق من ملف functions/index.js:**
```javascript
exports.sendOrderStatusNotification = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
        // تأكد من صحة الكود
    });
```

2. **اختبار Function محلياً:**
```bash
firebase functions:shell
```

### 3. خطأ في HTTP API

#### الأعراض:
- أخطاء 401, 403, 500
- فشل في استدعاء API

#### الحلول:

**أولاً: تحقق من Vercel API**

1. **تحقق من النشر:**
```bash
vercel ls
```

2. **تحقق من السجلات:**
```bash
vercel logs
```

3. **إعادة نشر:**
```bash
vercel --prod
```

**ثانياً: تحقق من المتغيرات**

1. **تحقق من Environment Variables:**
```bash
vercel env ls
```

2. **إضافة متغير جديد:**
```bash
vercel env add FCM_SERVICE_ACCOUNT_JSON
```

### 4. الإشعارات تصل في Foreground فقط

#### الأعراض:
- الإشعارات تصل عندما التطبيق مفتوح
- لا تصل عندما التطبيق في الخلفية

#### الحلول:

**أولاً: تحقق من Background Handler**

```dart
// في main.dart
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [FCM] Handling background message: ${message.messageId}');
}

// تسجيل Background Handler
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

**ثانياً: تحقق من إعدادات الجهاز**

1. **إعدادات التطبيق:**
- اذهب إلى إعدادات الجهاز
- اختر التطبيق
- تأكد من تفعيل الإشعارات

2. **إعدادات البطارية:**
- تأكد من عدم تقييد التطبيق في الخلفية

### 5. خطأ في FCM Token

#### الأعراض:
- Token فارغ أو null
- Token غير صالح

#### الحلول:

**أولاً: إعادة توليد Token**

```dart
// حذف Token الحالي
await FirebaseMessaging.instance.deleteToken();

// توليد Token جديد
String? newToken = await FirebaseMessaging.instance.getToken();

// حفظ Token في Firestore
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({'fcmToken': newToken});
```

**ثانياً: تحقق من Google Services**

1. **Android:**
- تأكد من وجود `google-services.json`
- تأكد من صحة `package_name`

2. **iOS:**
- تأكد من وجود `GoogleService-Info.plist`
- تأكد من صحة `Bundle ID`

### 6. خطأ في Firestore Rules

#### الأعراض:
- أخطاء في قراءة/كتابة البيانات
- فشل في حفظ FCM Token

#### الحلول:

**أولاً: تحقق من Rules**

```javascript
// في firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /orders/{orderId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**ثانياً: اختبار Rules**

```bash
firebase deploy --only firestore:rules
firebase firestore:rules:test
```

## أدوات التشخيص

### 1. Firebase Console

1. **Functions:**
- اذهب إلى Functions > Logs
- ابحث عن `sendOrderStatusNotification`

2. **Firestore:**
- اذهب إلى Firestore Database
- تحقق من بيانات المستخدمين والطلبات

3. **Analytics:**
- اذهب إلى Analytics > Events
- ابحث عن أحداث FCM

### 2. Vercel Dashboard

1. **Functions:**
- اذهب إلى Functions
- تحقق من الاستدعاءات والأخطاء

2. **Environment Variables:**
- اذهب إلى Settings > Environment Variables
- تحقق من `FCM_SERVICE_ACCOUNT_JSON`

### 3. Flutter Debug

```dart
// إضافة سجلات مفصلة
print('[FCM] Token: $fcmToken');
print('[FCM] User ID: $userId');
print('[FCM] Order ID: $orderId');
print('[FCM] Status: $status');
```

## الأوامر المفيدة للتشخيص

```bash
# Firebase
firebase functions:log --only sendOrderStatusNotification
firebase firestore:rules:test
firebase deploy --only functions --force

# Vercel
vercel logs --follow
vercel env ls
vercel --prod --force

# Flutter
flutter logs
flutter run --verbose
```

## منع المشاكل المستقبلية

### 1. المراقبة المستمرة

- تحقق من سجلات Firebase Functions يومياً
- راقب معدل نجاح الإشعارات
- تحقق من صحة FCM Tokens

### 2. الاختبار المنتظم

- اختبر الإشعارات على أجهزة حقيقية
- اختبر في حالات مختلفة (foreground, background)
- اختبر مع مستخدمين مختلفين

### 3. النسخ الاحتياطية

- احتفظ بنسخة من Firebase Functions
- احتفظ بنسخة من Vercel API
- احتفظ بنسخة من Service Account

### 4. التوثيق

- وثق جميع التغييرات
- وثق إعدادات البيئة
- وثق خطوات النشر 