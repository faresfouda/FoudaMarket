import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../blocs/cart/index.dart';
import '../../services/notification_service.dart';

import '../cart/cart_screen.dart';
import '../categories/categories_screen.dart';
import '../favourite/favourite_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';
import 'widgets/my_navigationbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List <Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const CartScreen(),
    const FavouriteScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
      // تعيين context لخدمة الإشعارات
      NotificationService().setContext(context);
    });
  }

  void _loadCart() {
    final user = FirebaseAuth.instance.currentUser;
    print('🔍 [MAIN_SCREEN] Current user: $user');
    if (user != null) {
      print('🔍 [MAIN_SCREEN] User ID: ${user.uid}');
      print('🔍 [MAIN_SCREEN] Loading cart for user: ${user.uid}');
      context.read<CartBloc>().add(LoadCart(user.uid));
    } else {
      print('❌ [MAIN_SCREEN] No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: SizedBox(
          height: 100,
          child: CustomBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}

