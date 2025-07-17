import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'views/onbording/OnBording.dart';
import 'views/admin/dashboard_screen.dart';
import 'views/admin/data_entry_home_screen.dart';
import 'views/home/main_screen.dart';
import 'views/profile/delivery_address_screen.dart';
import 'views/cart/checkout_screen.dart';
import 'views/cart/orders_screen.dart';
import 'views/cart/order_details_screen.dart';
import 'blocs/auth/index.dart';
import 'blocs/category/category_bloc.dart';
import 'blocs/product/product_bloc.dart';
import 'blocs/cart/cart_bloc.dart';
import 'blocs/address/address_bloc.dart';
import 'blocs/promo_code/index.dart';
import 'services/google_api_fix.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notification_service.dart';
import 'routes.dart';
import 'core/app_initializer.dart';
import 'core/onboarding_gate.dart';
import 'core/auth_wrapper.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [FCM] Handling a background message: ${message.messageId}');
  
  // طباعة تفاصيل الإشعار
  if (message.notification != null) {
    print('🔔 [FCM] Background notification: Title=${message.notification!.title}, Body=${message.notification!.body}');
  }
  
  // طباعة البيانات الإضافية
  if (message.data.isNotEmpty) {
    print('🔔 [FCM] Background message data: ${message.data}');
  }
}

Future<void> _requestNotificationPermissionsExplicitly() async {
  try {
    print('🔔 [MAIN] Requesting notification permissions explicitly...');
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // التحقق من الصلاحيات الحالية
    NotificationSettings settings = await messaging.getNotificationSettings();
    print('🔔 [MAIN] Current permission status: ${settings.authorizationStatus}');
    
    // طلب الصلاحيات بغض النظر عن الحالة الحالية
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
    
    print('🔔 [MAIN] Permission request result: ${settings.authorizationStatus}');
    
    // إعداد قنوات الإشعارات للأندرويد
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



void main() async {
  await AppInitializer.initialize();
  runApp(const FodaMarket());
}

class FodaMarket extends StatelessWidget {
  const FodaMarket({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: AppInitializer.blocProviders,
      child: MaterialApp(
        locale: const Locale('ar', 'SA'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          fontFamily: 'Gilroy',
        ),
        debugShowCheckedModeBanner: false,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: OnboardingGate(
            child: AuthWrapper(),
          ),
        ),
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }
}


