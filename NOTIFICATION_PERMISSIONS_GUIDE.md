# دليل حل مشكلة صلاحيات الإشعارات - Fouda Market

## المشكلة
لا يوجد صلاحية لاستقبال الإشعارات من الهاتف.

## الحلول المطبقة

### 1. إضافة صلاحيات Android ✅

تم إضافة الصلاحيات التالية في `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- FCM Permissions -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- For Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 2. إضافة إعدادات FCM ✅

تم إضافة إعدادات FCM في `AndroidManifest.xml`:

```xml
<!-- FCM Service -->
<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT"/>
    </intent-filter>
</service>

<!-- FCM Default Channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="fouda_market_channel"/>

<!-- FCM Default Icon -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification"/>

<!-- FCM Default Color -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color"/>
```

### 3. تحسين طلب الصلاحيات ✅

تم تحسين دالة طلب الصلاحيات في `lib/main.dart`:

```dart
Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // التحقق من الصلاحيات الحالية
  NotificationSettings settings = await messaging.getNotificationSettings();
  print('🔔 [FCM] Current permission status: ${settings.authorizationStatus}');
  
  // إذا لم تكن الصلاحيات ممنوحة، اطلبها
  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print('🔔 [FCM] Requesting notification permission...');
    settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('🔔 [FCM] Permission request result: ${settings.authorizationStatus}');
  }
  
  print('🔔 [FCM] Final permission status: ${settings.authorizationStatus}');
}
```

## خطوات التطبيق

### 1. تثبيت التبعيات
```bash
flutter pub get
```

### 2. إعادة بناء التطبيق
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### 3. اختبار الصلاحيات
```bash
flutter run
```

## اختبار الصلاحيات

### 1. من التطبيق
1. شغل التطبيق
2. تحقق من السجلات في Terminal
3. يجب أن ترى:
   ```
   🔔 [FCM] Current permission status: AuthorizationStatus.authorized
   ```

### 2. من إعدادات الجهاز
1. اذهب إلى إعدادات الجهاز
2. اختر التطبيق "deliveryapp"
3. تأكد من تفعيل "الإشعارات"

### 3. اختبار الإشعارات
1. اذهب إلى شاشة إدارة الطلبات
2. اختر طلب
3. انقر على "اختبار الإشعار"
4. تحقق من وصول الإشعار

## استكشاف الأخطاء

### مشكلة 1: الصلاحيات مرفوضة
**الأعراض:**
```
🔔 [FCM] Current permission status: AuthorizationStatus.denied
```

**الحل:**
1. اذهب إلى إعدادات الجهاز
2. اختر التطبيق
3. فعّل الإشعارات

### مشكلة 2: لا تظهر نافذة طلب الصلاحيات
**الحل:**
1. احذف التطبيق
2. أعد تثبيته
3. شغله مرة أخرى

### مشكلة 3: الإشعارات لا تصل
**الحل:**
1. تحقق من إعدادات البطارية
2. تأكد من عدم تقييد التطبيق
3. تحقق من إعدادات Do Not Disturb

### مشكلة 4: مشاكل في Android 13+
**الحل:**
1. تأكد من وجود صلاحية `POST_NOTIFICATIONS`
2. تحقق من إعدادات الإشعارات في النظام

## الأوامر المفيدة

```bash
# تنظيف وإعادة بناء
flutter clean
flutter pub get

# بناء للتطبيق
flutter build apk --debug

# تشغيل مع سجلات مفصلة
flutter run --verbose

# اختبار على جهاز حقيقي
flutter run -d <device-id>
```

## التحقق من النجاح

### 1. في السجلات
```
🔔 [FCM] Current permission status: AuthorizationStatus.authorized
🔔 [FCM] Final permission status: AuthorizationStatus.authorized
🔑 [FCM] Device Token: <token>
✅ [FCM] Token saved to Firestore for user: <user-id>
```

### 2. في إعدادات الجهاز
- الإشعارات مفعلة للتطبيق
- لا توجد قيود على البطارية

### 3. اختبار الإشعارات
- الإشعارات تصل عند الاختبار
- الإشعارات تصل عند تغيير حالة الطلب

## ملاحظات مهمة

1. **Android 13+**: يتطلب صلاحية `POST_NOTIFICATIONS` صريحة
2. **إعدادات البطارية**: قد تقيد الإشعارات في الخلفية
3. **Do Not Disturb**: قد يمنع الإشعارات
4. **إعدادات التطبيق**: تحقق من إعدادات الإشعارات في النظام

## الدعم

إذا استمرت المشكلة:

1. تحقق من إعدادات الجهاز
2. اختبر على جهاز آخر
3. تحقق من سجلات التطبيق
4. تأكد من إعدادات Firebase 