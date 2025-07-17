import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/notification_banner.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // لتخزين context لعرض الإشعارات
  BuildContext? _context;
  
  void setContext(BuildContext context) {
    _context = context;
  }

  // Stream للاستماع للإشعارات
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    print('🔔 [NotificationService] Initializing...');
    
    // طلب الصلاحيات
    await _requestPermissions();
    
    // إعداد قنوات الإشعارات
    await _setupNotificationChannels();
    
    // حفظ التوكن
    await _saveTokenToFirestore();
    
    // إعداد معالجات الإشعارات
    _setupMessageHandlers();
    
    print('🔔 [NotificationService] Initialized successfully');
  }

  /// طلب صلاحيات الإشعارات
  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _messaging.getNotificationSettings();
      print('🔔 [NotificationService] Current permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        print('🔔 [NotificationService] Requesting notification permission...');
        
        settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        print('🔔 [NotificationService] Permission request result: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('❌ [NotificationService] Error requesting permissions: $e');
    }
  }

  /// إعداد قنوات الإشعارات
  Future<void> _setupNotificationChannels() async {
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('🔔 [NotificationService] Notification channels configured');
    } catch (e) {
      print('❌ [NotificationService] Error setting up notification channels: $e');
    }
  }

  /// حفظ التوكن في Firestore
  Future<void> _saveTokenToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ [NotificationService] Token saved to Firestore for user: ${user.uid}');
        }
      }
    } catch (e) {
      print('❌ [NotificationService] Error saving token to Firestore: $e');
    }
  }

  /// إعداد معالجات الإشعارات
  void _setupMessageHandlers() {
    // معالجة الإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 [NotificationService] Received foreground message: ${message.messageId}');
      _handleMessage(message, isForeground: true);
    });

    // معالجة النقر على الإشعارات
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 [NotificationService] App opened from notification: ${message.messageId}');
      _handleMessage(message, isForeground: false);
    });
  }

  /// معالجة الإشعارات
  void _handleMessage(RemoteMessage message, {required bool isForeground}) {
    try {
      // طباعة تفاصيل الإشعار
      if (message.notification != null) {
        print('🔔 [NotificationService] Notification: Title= [1m${message.notification!.title} [0m, Body=${message.notification!.body}');
      }
      
      // طباعة البيانات الإضافية
      if (message.data.isNotEmpty) {
        print('🔔 [NotificationService] Message data: ${message.data}');
      }

      // لا تحفظ الإشعار في Firestore هنا بعد الآن

      // معالجة أنواع مختلفة من الإشعارات
      final String? type = message.data['type'];
      final String? orderId = message.data['orderId'];
      
      switch (type) {
        case 'order_status_update':
          _handleOrderStatusUpdate(orderId, message);
          break;
        case 'new_order':
          _handleNewOrder(orderId, message);
          break;
        case 'test_notification':
          _handleTestNotification(message);
          break;
        default:
          print('🔔 [NotificationService] Unknown notification type: $type');
      }
    } catch (e) {
      print('❌ [NotificationService] Error handling message: $e');
    }
  }

  /// معالجة تحديث حالة الطلب
  void _handleOrderStatusUpdate(String? orderId, RemoteMessage message) {
    print('🔔 [NotificationService] Handling order status update for order: $orderId');
    
    // عرض الإشعار في التطبيق إذا كان context متاحاً
    if (_context != null && message.notification != null) {
      NotificationOverlay.show(
        context: _context!,
        title: message.notification!.title ?? 'تحديث حالة الطلب',
        message: message.notification!.body ?? 'تم تحديث حالة طلبك',
        onTap: () {
          // يمكنك هنا إضافة منطق للانتقال إلى صفحة الطلب
          print('🔔 [NotificationService] Tapped on order status notification');
        },
      );
    }
  }

  /// معالجة طلب جديد
  void _handleNewOrder(String? orderId, RemoteMessage message) {
    print('🔔 [NotificationService] Handling new order: $orderId');
    
    // عرض الإشعار في التطبيق إذا كان context متاحاً
    if (_context != null && message.notification != null) {
      NotificationOverlay.show(
        context: _context!,
        title: message.notification!.title ?? 'طلب جديد',
        message: message.notification!.body ?? 'لديك طلب جديد',
        onTap: () {
          // يمكنك هنا إضافة منطق للانتقال إلى صفحة الطلبات
          print('🔔 [NotificationService] Tapped on new order notification');
        },
      );
    }
  }

  /// معالجة الإشعار التجريبي
  void _handleTestNotification(RemoteMessage message) {
    print('🔔 [NotificationService] Handling test notification');
    
    // عرض الإشعار في التطبيق إذا كان context متاحاً
    if (_context != null && message.notification != null) {
      NotificationOverlay.show(
        context: _context!,
        title: message.notification!.title ?? 'إشعار تجريبي',
        message: message.notification!.body ?? 'هذا إشعار تجريبي',
        onTap: () {
          print('🔔 [NotificationService] Tapped on test notification');
        },
      );
    }
  }

  /// الحصول على التوكن الحالي
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ [NotificationService] Error getting token: $e');
      return null;
    }
  }

  /// تحديث التوكن في Firestore
  Future<void> updateTokenInFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ [NotificationService] Token updated in Firestore');
        }
      }
    } catch (e) {
      print('❌ [NotificationService] Error updating token: $e');
    }
  }

  /// إلغاء الاشتراك من جميع المواضيع
  Future<void> unsubscribeFromAllTopics() async {
    try {
      await _messaging.unsubscribeFromTopic('all');
      await _messaging.unsubscribeFromTopic('orders');
      await _messaging.unsubscribeFromTopic('admin');
      print('✅ [NotificationService] Unsubscribed from all topics');
    } catch (e) {
      print('❌ [NotificationService] Error unsubscribing from topics: $e');
    }
  }

  /// الاشتراك في مواضيع معينة
  Future<void> subscribeToTopics() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // الاشتراك في مواضيع عامة
        await _messaging.subscribeToTopic('all');
        
        // الاشتراك في مواضيع الطلبات
        await _messaging.subscribeToTopic('orders');
        
        // إذا كان المستخدم admin، اشترك في مواضيع الإدارة
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
          await _messaging.subscribeToTopic('admin');
        }
        
        print('✅ [NotificationService] Subscribed to topics');
      }
    } catch (e) {
      print('❌ [NotificationService] Error subscribing to topics: $e');
    }
  }
} 