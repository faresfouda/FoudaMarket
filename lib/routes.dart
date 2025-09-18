import 'package:flutter/material.dart';
// استيراد الشاشات الأساسية
import 'views/admin/dashboard_screen.dart';
import 'views/admin/data_entry_home_screen.dart';
import 'views/auth/auth_selection_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/sign_up_screen.dart';
import 'views/auth/phone_login_screen.dart';
import 'views/auth/email_login_screen.dart';
import 'views/auth/linked_accounts_screen.dart';
import 'views/auth/otp_screen.dart';
import 'views/cart/order_accepted_screen.dart';
import 'views/cart/checkout_screen.dart';
import 'views/home/main_screen.dart';
import 'views/admin/orders_screen.dart' as admin;
import 'views/profile/orders_screen.dart' as profile;
import 'views/profile/delivery_address_screen.dart';
import 'views/profile/profile_screen.dart';
import 'core/auth_wrapper.dart';

class AppRoutes {
  // مسارات المصادقة
  static const String authSelection = '/auth-selection';
  static const String signIn = authSelection;
  static const String login = '/login';
  static const String signup = '/signup';
  static const String phoneLogin = '/phone-login';
  static const String emailLogin = '/email-login';
  static const String socialLogin = '/social-login';
  static const String linkedAccounts = '/linked-accounts';
  static const String otpVerification = '/otp-verification';

  // مسارات المستخدمين العاديين
  static const String checkout = '/checkout';
  static const String orderAccepted = '/order-accepted';
  static const String authWrapper = '/auth-wrapper';
  static const String main = '/main';
  static const String deliveryAddress = '/delivery-address';
  static const String profile = '/profile';
  static const String profileOrders = '/profile/orders';

  // مسارات الإدارة
  static const String adminDashboard = '/admin/dashboard';
  static const String dataEntryHome = '/data-entry/home';
  static const String adminOrders = '/admin/orders';
}

// دالة onGenerateRoute مبسطة
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '');
  final path = uri.path;

  switch (path) {
    // مسارات المصادقة
    case AppRoutes.authSelection:
    case AppRoutes.signIn:
    case AppRoutes.socialLogin:
      return MaterialPageRoute(builder: (_) => AuthSelectionScreen());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => LoginScreen());
    case AppRoutes.signup:
      return MaterialPageRoute(builder: (_) => SignUpScreen());
    case AppRoutes.phoneLogin:
      return MaterialPageRoute(builder: (_) => PhoneLoginScreen());
    case AppRoutes.emailLogin:
      return MaterialPageRoute(builder: (_) => EmailLoginScreen());
    case AppRoutes.linkedAccounts:
      return MaterialPageRoute(builder: (_) => LinkedAccountsScreen());
    case AppRoutes.otpVerification:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => OtpScreen(
          verificationId: args?['verificationId'] ?? '',
          phoneNumber: args?['phoneNumber'] ?? '',
        ),
      );

    // مسارات المستخدمين العاديين
    case AppRoutes.authWrapper:
      return MaterialPageRoute(builder: (_) => AuthWrapper());
    case AppRoutes.main:
      return MaterialPageRoute(builder: (_) => MainScreen());
    case AppRoutes.checkout:
      return MaterialPageRoute(builder: (_) => CheckoutScreen());
    case AppRoutes.orderAccepted:
      return MaterialPageRoute(builder: (_) => OrderAcceptedScreen());
    case AppRoutes.deliveryAddress:
      return MaterialPageRoute(builder: (_) => DeliveryAddressScreen());
    case AppRoutes.profile:
      return MaterialPageRoute(builder: (_) => ProfileScreen());
    case AppRoutes.profileOrders:
      return MaterialPageRoute(builder: (_) => profile.OrdersScreen());

    // مسارات الإدارة
    case AppRoutes.adminDashboard:
      return MaterialPageRoute(builder: (_) => DashboardScreen());
    case AppRoutes.dataEntryHome:
      return MaterialPageRoute(builder: (_) => DataEntryHomeScreen());
    case AppRoutes.adminOrders:
      return MaterialPageRoute(builder: (_) => admin.OrdersScreen());

    default:
      // التعامل مع المسارات التي تحتوي على معاملات
      if (path.startsWith('/order-accepted/')) {
        final orderId = path.split('/').last;
        return MaterialPageRoute(
          builder: (_) => OrderAcceptedScreen(orderId: orderId),
        );
      }

      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('الصفحة غير موجودة: ${settings.name}'),
          ),
        ),
      );
  }
}