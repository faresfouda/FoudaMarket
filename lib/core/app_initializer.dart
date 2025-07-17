import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../blocs/auth/index.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/address/address_bloc.dart';
import '../blocs/promo_code/index.dart';
import '../services/google_api_fix.dart';
import '../services/notification_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await GoogleApiFix.fixGoogleApiIssues();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
    await _requestNotificationPermissionsExplicitly();
    print('main(): FirebaseAuth.currentUser = \\${FirebaseAuth.instance.currentUser}');
  }

  static List<BlocProvider> get blocProviders => [
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc()..add(AuthCheckRequested()),
    ),
    BlocProvider<CategoryBloc>(
      create: (context) => CategoryBloc(),
    ),
    BlocProvider<ProductBloc>(
      create: (context) => ProductBloc(),
    ),
    BlocProvider<CartBloc>(
      create: (context) => CartBloc(),
    ),
    BlocProvider<AddressBloc>(
      create: (context) => AddressBloc(),
    ),
    BlocProvider<PromoCodeBloc>(
      create: (context) => PromoCodeBloc(),
    ),
  ];
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [FCM] Handling a background message: \\${message.messageId}');
  if (message.notification != null) {
    print('🔔 [FCM] Background notification: Title=\\${message.notification!.title}, Body=\\${message.notification!.body}');
  }
  if (message.data.isNotEmpty) {
    print('🔔 [FCM] Background message data: \\${message.data}');
  }
}

Future<void> _requestNotificationPermissionsExplicitly() async {
  try {
    print('🔔 [MAIN] Requesting notification permissions explicitly...');
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.getNotificationSettings();
    print('🔔 [MAIN] Current permission status: \\${settings.authorizationStatus}');
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
    print('🔔 [MAIN] Permission request result: \\${settings.authorizationStatus}');
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 [MAIN] Notification channels configured');
  } catch (e) {
    print('❌ [MAIN] Error requesting notification permissions: \\${e}');
  }
} 