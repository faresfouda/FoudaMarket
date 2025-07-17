# حل مشكلة صلاحيات الإشعارات في FoudaMarket

## المشكلة
التطبيق لا يطلب صلاحيات الإشعارات عند التشغيل، ويظهر فقط صلاحيات الكاميرا والملفات.

## الحلول المطبقة

### 1. تحديث إعدادات Android

#### أ. تحديث minSdk
```kotlin
// android/app/build.gradle.kts
minSdk = 26  // تم تحديثه من 23
```

#### ب. إضافة صلاحيات الإشعارات في AndroidManifest.xml
```xml
<!-- FCM Permissions -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- For Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### ج. تحسين MainActivity.kt
```kotlin
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "fouda_market_channel"
            val channelName = "Fouda Market Notifications"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "Notifications for Fouda Market app"
                enableLights(true)
                lightColor = Color.RED
                enableVibration(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
```

### 2. تحسين طلب الصلاحيات في Flutter

#### أ. طلب صريح للصلاحيات في main.dart
```dart
Future<void> _requestNotificationPermissionsExplicitly() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // التحقق من الصلاحيات الحالية
    NotificationSettings settings = await messaging.getNotificationSettings();
    
    // طلب الصلاحيات بغض النظر عن الحالة الحالية
    settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    // إعداد قنوات الإشعارات
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
  } catch (e) {
    print('❌ Error requesting notification permissions: $e');
  }
}
```

#### ب. إضافة أزرار طلب الصلاحيات في واجهة المستخدم
- في شاشة الملف الشخصي: "إعدادات الإشعارات"
- في شاشة الإشعارات: "طلب صلاحيات الإشعارات"

### 3. إنشاء خدمة إشعارات محسنة

#### أ. NotificationService
```dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  Future<void> initialize() async {
    await _requestPermissions();
    await _setupNotificationChannels();
    await _saveTokenToFirestore();
    _setupMessageHandlers();
  }
  
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.getNotificationSettings();
    
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}
```

### 4. إضافة عرض الإشعارات في التطبيق

#### أ. NotificationBanner
```dart
class NotificationBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [/* ... */],
      ),
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(message),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### ب. NotificationOverlay
```dart
class NotificationOverlay {
  static OverlayEntry? _currentEntry;
  
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    hide();
    
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: NotificationBanner(
          title: title,
          message: message,
          onTap: onTap,
          onDismiss: hide,
        ),
      ),
    );
    
    Overlay.of(context).insert(_currentEntry!);
    
    Future.delayed(duration, () => hide());
  }
  
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
```

## خطوات الاختبار

### 1. تشغيل التطبيق
```bash
flutter clean
flutter pub get
flutter run
```

### 2. مراقبة السجلات
ابحث عن هذه الرسائل في السجلات:
```
🔔 [MAIN] Requesting notification permissions explicitly...
🔔 [MAIN] Current permission status: AuthorizationStatus.denied
🔔 [MAIN] Permission request result: AuthorizationStatus.authorized
```

### 3. اختبار طلب الصلاحيات يدوياً
1. اذهب إلى شاشة الملف الشخصي
2. اضغط على "إعدادات الإشعارات"
3. يجب أن يظهر طلب صلاحيات الإشعارات

### 4. اختبار الإشعارات
1. اذهب إلى شاشة الطلبات في الإدارة
2. اضغط على "اختبار الإشعار" لأي طلب
3. يجب أن تظهر الإشعارات في التطبيق

## استكشاف الأخطاء

### إذا لم تظهر صلاحيات الإشعارات:

1. **تحقق من إعدادات الجهاز**:
   - اذهب إلى إعدادات الجهاز > التطبيقات > FoudaMarket > صلاحيات
   - تأكد من تفعيل "الإشعارات"

2. **إعادة تثبيت التطبيق**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **اختبار على جهاز حقيقي**:
   - بعض المحاكيات لا تدعم صلاحيات الإشعارات بشكل صحيح
   - جرب على هاتف حقيقي

4. **تحقق من إعدادات Firebase**:
   - تأكد من أن `google-services.json` محدث
   - تأكد من تفعيل Firebase Cloud Messaging في Firebase Console

### إذا لم تصل الإشعارات:

1. **تحقق من FCM Token**:
   - تأكد من أن التوكن يتم حفظه في Firestore
   - تأكد من أن التوكن صالح وغير منتهي الصلاحية

2. **تحقق من Vercel API**:
   - تأكد من أن متغيرات البيئة صحيحة
   - اختبر API باستخدام curl أو Postman

3. **تحقق من السجلات**:
   - ابحث عن أخطاء في سجلات التطبيق
   - ابحث عن أخطاء في سجلات Vercel

## النتيجة المتوقعة

بعد تطبيق هذه التحسينات:
- ✅ التطبيق سيطلب صلاحيات الإشعارات عند التشغيل
- ✅ ستظهر الإشعارات في التطبيق عند استلامها
- ✅ يمكن طلب الصلاحيات يدوياً من شاشة الإعدادات
- ✅ نظام إشعارات محسن ومستقر 