import 'package:flutter/material.dart';
import 'package:fouda_market/views/admin/products_categories_screen.dart';
import 'package:fouda_market/views/admin/orders_screen.dart';
import 'package:fouda_market/views/admin/reviews_screen.dart';
import 'package:fouda_market/views/admin/profile_screen.dart';
import 'package:fouda_market/theme/appcolors.dart';

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
    ReviewsScreen(),
    ProfileScreen(),
  ];

  static const List<String> _titles = [
    'المنتجات',
    'الطلبات',
    'المراجعات',
    'الحساب',
  ];

  static const List<IconData> _icons = [
    Icons.inventory_2_outlined,
    Icons.shopping_bag_outlined,
    Icons.rate_review_outlined,
    Icons.person_outline,
  ];

  static const List<IconData> _selectedIcons = [
    Icons.inventory_2,
    Icons.shopping_bag,
    Icons.rate_review,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _selectedIndex == 3 // إخفاء AppBar في صفحة الحساب (index 3)
            ? null
            : AppBar(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage('assets/home/logo.jpg'),
                      radius: 18,
                    ),
                  ),
                ],
                iconTheme: const IconThemeData(color: Colors.black),
              ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.orangeColor,
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            items: List.generate(_titles.length, (index) {
              return BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == index
                        ? AppColors.orangeColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == index
                        ? _selectedIcons[index]
                        : _icons[index],
                    size: 24,
                  ),
                ),
                label: _titles[index],
              );
            }),
          ),
        ),
      ),
    );
  }
}