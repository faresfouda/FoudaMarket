import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import '../blocs/auth/index.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/address/address_bloc.dart';
import '../blocs/promo_code/index.dart';
import '../services/notification_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // تهيئة Firebase مع معالجة أخطاء محسنة للويب
      await _initializeFirebase();

      // تهيئة Firebase Messaging فقط خارج الويب أو مع معالجة خاصة للويب
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // طلب صلاحيات الإشعارات للموبايل فقط
        await _requestNotificationPermissionsExplicitly();
      } else {
        print('🌐 [WEB] Firebase initialized for web platform');
      }

      // تهيئة خدمة الإشعارات (مع دعم الويب)
      await NotificationService().initialize();

      print(
        'main(): FirebaseAuth.currentUser = ${FirebaseAuth.instance.currentUser}',
      );
    } catch (e) {
      print('❌ [AppInitializer] Error during initialization: $e');
      // إعادة رمي الخطأ للتعامل معه في main()
      rethrow;
    }
  }

  static Future<void> _initializeFirebase() async {
    try {
      if (kIsWeb) {
        // للويب: استخدام timeout وإعادة محاولة
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Firebase initialization timeout on web');
          },
        );

        // التحقق من أن Firebase تم تهيئته بنجاح
        if (Firebase.apps.isEmpty) {
          throw Exception('Firebase apps list is empty after initialization');
        }

        print('✅ [WEB] Firebase initialized successfully');
      } else {
        // للموبايل: التهيئة العادية
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ [MOBILE] Firebase initialized successfully');
      }
    } catch (e) {
      print('❌ [Firebase] Initialization error: $e');

      if (kIsWeb) {
        // للويب: محاولة إعادة التهيئة بإعدادات مبسطة
        try {
          print('🔄 [WEB] Retrying Firebase initialization...');
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: 'AIzaSyBU9pe0TzB8oJ__ldfjLJmwCm-2bWB4R9c',
              appId: '1:964251925023:web:4733815ca260ec1dd1332a',
              messagingSenderId: '964251925023',
              projectId: 'fouda-market',
              authDomain: 'fouda-market.firebaseapp.com',
              storageBucket: 'fouda-market.firebasestorage.app',
            ),
          );
          print('✅ [WEB] Firebase retry successful');
        } catch (retryError) {
          print('❌ [WEB] Firebase retry failed: $retryError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  static List<BlocProvider> get blocProviders => [
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc()..add(AuthCheckRequested()),
    ),
    BlocProvider<CategoryBloc>(create: (context) => CategoryBloc()),
    BlocProvider<ProductBloc>(create: (context) => ProductBloc()),
    BlocProvider<CartBloc>(create: (context) => CartBloc()),
    BlocProvider<AddressBloc>(create: (context) => AddressBloc()),
    BlocProvider<PromoCodeBloc>(create: (context) => PromoCodeBloc()),
  ];
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [FCM] Handling a background message: ${message.messageId}');
  if (message.notification != null) {
    print(
      '🔔 [FCM] Background notification: Title=${message.notification!.title}, Body=${message.notification!.body}',
    );
  }
  if (message.data.isNotEmpty) {
    print('🔔 [FCM] Background message data: ${message.data}');
  }
}

Future<void> _requestNotificationPermissionsExplicitly() async {
  try {
    print('🔔 [MAIN] Requesting notification permissions explicitly...');
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.getNotificationSettings();
    print(
      '🔔 [MAIN] Current permission status: ${settings.authorizationStatus}',
    );
    print('🔔 [MAIN] Requesting notification permission...');
    settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print(
      '🔔 [MAIN] Permission request result: ${settings.authorizationStatus}',
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 [MAIN] Notification channels configured');
  } catch (e) {
    print('❌ [MAIN] Error requesting notification permissions: $e');
  }
}
