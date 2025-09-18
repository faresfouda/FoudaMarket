// Test script for notification permissions
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> testNotificationPermissions() async {
  print('🧪 اختبار صلاحيات الإشعارات...');
  
  try {
    // 1. التحقق من الصلاحيات الحالية
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.getNotificationSettings();
    
    print('📋 حالة الصلاحيات الحالية:');
    print('   Authorization Status: ${settings.authorizationStatus}');
    print('   Alert: ${settings.alert}');
    print('   Badge: ${settings.badge}');
    print('   Sound: ${settings.sound}');
    
    // 2. طلب الصلاحيات إذا لم تكن ممنوحة
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('\n🔔 طلب صلاحيات الإشعارات...');
      settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('📋 نتيجة طلب الصلاحيات:');
      print('   Authorization Status: ${settings.authorizationStatus}');
    }
    
    // 3. الحصول على FCM Token
    print('\n🔑 الحصول على FCM Token...');
    String? token = await messaging.getToken();
    
    if (token != null) {
      print('✅ FCM Token: ${token.substring(0, 20)}...');
    } else {
      print('❌ فشل في الحصول على FCM Token');
    }
    
    // 4. اختبار استقبال الإشعارات
    print('\n📡 اختبار استقبال الإشعارات...');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('✅ تم استقبال إشعار في Foreground:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
    });
    
    // 5. النتيجة النهائية
    print('\n🏁 النتيجة النهائية:');
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ الصلاحيات ممنوحة بنجاح!');
      print('✅ يمكن استقبال الإشعارات');
    } else {
      print('❌ الصلاحيات غير ممنوحة');
      print('❌ لا يمكن استقبال الإشعارات');
    }
    
  } catch (error) {
    print('💥 خطأ في اختبار الصلاحيات: $error');
  }
}

// تشغيل الاختبار
void main() async {
  await testNotificationPermissions();
} 