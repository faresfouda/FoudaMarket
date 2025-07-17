import 'package:flutter/material.dart';
// استيراد جميع الشاشات الرئيسية
import 'views/onbording/OnBording.dart';
import 'views/admin/dashboard_screen.dart';
import 'views/admin/data_entry_home_screen.dart';
import 'views/home/main_screen.dart';
import 'views/profile/delivery_address_screen.dart';
import 'views/cart/checkout_screen.dart';
import 'views/profile/orders_screen.dart';
import 'views/cart/order_details_screen.dart';
import 'views/cart/order_accepted_screen.dart';
import 'views/auth/auth_selection_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/sign_up_screen.dart';
import 'views/auth/phone_login_screen.dart';
import 'views/role_selection_screen.dart';
import 'views/profile/profile_screen.dart';
import 'views/home/home_screen.dart';
import 'views/categories/categories_screen.dart';
import 'views/cart/cart_screen.dart';
import 'views/favourite/favourite_screen.dart';
import 'views/product/product_screen.dart';

// تعريف أسماء المسارات
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String authSelection = '/auth-selection';
  static const String signIn = authSelection; // دعم التوافق مع الاسم القديم
  static const String login = '/login';
  static const String signup = '/signup';
  static const String main = '/main';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String favourite = '/favourite';
  static const String profile = '/profile';
  static const String deliveryAddress = '/delivery-address';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';
  static const String adminDashboard = '/admin/dashboard';
  static const String dataEntryHome = '/data-entry/home';
  static const String product = '/product';
  // أضف المزيد حسب الحاجة
}

// دالة onGenerateRoute مركزية
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.onboarding:
      return MaterialPageRoute(builder: (_) => OnBording(onFinish: (){}));
    case AppRoutes.authSelection:
      return MaterialPageRoute(builder: (_) => AuthSelectionScreen());
    case AppRoutes.signIn:
      return MaterialPageRoute(builder: (_) => AuthSelectionScreen());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => LoginScreen());
    case AppRoutes.signup:
      return MaterialPageRoute(builder: (_) => SignUpScreen());
    case AppRoutes.main:
      return MaterialPageRoute(builder: (_) => MainScreen());
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => HomeScreen());
    case AppRoutes.categories:
      return MaterialPageRoute(builder: (_) => CategoriesScreen());
    case AppRoutes.cart:
      return MaterialPageRoute(builder: (_) => CartScreen());
    case AppRoutes.favourite:
      return MaterialPageRoute(builder: (_) => FavouriteScreen());
    case AppRoutes.profile:
      return MaterialPageRoute(builder: (_) => ProfileScreen());
    case AppRoutes.deliveryAddress:
      return MaterialPageRoute(builder: (_) => DeliveryAddressScreen());
    case AppRoutes.checkout:
      return MaterialPageRoute(builder: (_) => CheckoutScreen());
    case AppRoutes.orders:
      return MaterialPageRoute(builder: (_) => OrdersScreen());
    case AppRoutes.adminDashboard:
      return MaterialPageRoute(builder: (_) => DashboardScreen());
    case AppRoutes.dataEntryHome:
      return MaterialPageRoute(builder: (_) => DataEntryHomeScreen());
    case AppRoutes.product:
      // هذا المسار يتطلب دائماً تمرير كائن المنتج، استخدم MaterialPageRoute مباشرة عند الحاجة
      assert(false, 'ProductDetailScreen يتطلب كائن منتج. استخدم MaterialPageRoute يدوياً.');
      return null;
    // مثال لمسار ديناميكي (تفاصيل الطلب)
    default:
      if (settings.name != null && settings.name!.startsWith(AppRoutes.orderDetails)) {
        final orderId = settings.name!.replaceFirst(AppRoutes.orderDetails + '/', '');
        return MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId));
      }
      // مسار شاشة الطلب المقبول
      if (settings.name != null && settings.name!.contains('${AppRoutes.orders}/accepted/')) {
        final orderId = settings.name!.split('${AppRoutes.orders}/accepted/').last;
        return MaterialPageRoute(builder: (_) => OrderAcceptedScreen(orderId: orderId));
      }
      return null;
  }
} 