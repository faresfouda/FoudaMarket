import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> testNotificationPermissions() async {
  print('🔔 [TEST] Starting notification permission test...');
  
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // التحقق من الصلاحيات الحالية
    NotificationSettings settings = await messaging.getNotificationSettings();
    print('🔔 [TEST] Current permission status: ${settings.authorizationStatus}');
    
    // طلب الصلاحيات
    print('🔔 [TEST] Requesting notification permission...');
    settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('🔔 [TEST] Permission request result: ${settings.authorizationStatus}');
    
    // الحصول على التوكن
    String? token = await messaging.getToken();
    print('🔔 [TEST] FCM Token: $token');
    
    // إعداد قنوات الإشعارات
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('🔔 [TEST] Notification channels configured');
    
    // اختبار الاشتراك في مواضيع
    await messaging.subscribeToTopic('test');
    print('🔔 [TEST] Subscribed to test topic');
    
    print('🔔 [TEST] Notification permission test completed successfully');
    
  } catch (e) {
    print('❌ [TEST] Error in notification permission test: $e');
  }
}

void main() async {
  await testNotificationPermissions();
} 