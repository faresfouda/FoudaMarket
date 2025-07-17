import 'package:flutter/material.dart';
import 'package:fouda_market/views/admin/products_categories_screen.dart';
import 'package:fouda_market/views/admin/orders_screen.dart';
import 'package:fouda_market/views/admin/reviews_screen.dart';
import 'package:fouda_market/views/admin/profile_screen.dart';
import 'package:fouda_market/views/admin/promo_codes_screen.dart';
import 'package:fouda_market/views/profile/notifications_screen.dart';

class DataEntryHomeScreen extends StatefulWidget {
  const DataEntryHomeScreen({super.key});

  @override
  State<DataEntryHomeScreen> createState() => _DataEntryHomeScreenState();
}

class _DataEntryHomeScreenState extends State<DataEntryHomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
      ProductsCategoriesScreen(),
      OrdersScreen(),
      PromoCodesScreen(),
      ReviewsScreen(),
      ProfileScreen(),
    ];

  static const List<String> _titles = [
    'المنتجات',
    'الطلبات',
    'أكواد الخصم',
    'المراجعة',
    'الحساب',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.orange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/home/logo.jpg'),
                radius: 18,
              ),
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'المنتجات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.discount),
              label: 'أكواد الخصم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review),
              label: 'المراجعة',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحساب'),
          ],
        ),
      ),
    );
  }
}
