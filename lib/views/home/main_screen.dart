import 'package:flutter/material.dart';

import '../cart/cart_screen.dart';
import '../categories/categories_screen.dart';
import '../favourite/favourite_screen.dart';
import 'home_screen.dart';
import 'widgets/my_navigationbar.dart';

class MainScreen extends StatefulWidget {

  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List <Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const CartScreen(),
    const FavouriteScreen(),
    const Center(
      child: Text('Profile Screen'),
    ),
  ];
  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
    );
  }
}

