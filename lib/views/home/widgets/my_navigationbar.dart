import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/blocs/cart/index.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/bottomnavigationbar/home.svg',
              color: selectedIndex == 0
                  ?  AppColors.orangeColor
                  : AppColors.mediumGrayColor,
            ),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/bottomnavigationbar/categories.svg',
              color: selectedIndex == 1
                  ? AppColors.orangeColor
                  : AppColors.mediumGrayColor,
            ),
            label: 'الاقسام',
          ),
          BottomNavigationBarItem(
            icon: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                int cartCount = 0;
                if (state is CartLoaded) {
                  cartCount = state.itemsCount;
                }
                return Stack(
                  children: [
                    SvgPicture.asset(
                      'assets/bottomnavigationbar/cart.svg',
                      color: selectedIndex == 2
                          ? AppColors.orangeColor
                          : AppColors.mediumGrayColor,
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'العربة',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/bottomnavigationbar/favourite.svg',
              color: selectedIndex == 3
                  ? AppColors.orangeColor
                  : AppColors.mediumGrayColor,
            ),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/bottomnavigationbar/profile.svg',
              color: selectedIndex == 4
                  ? AppColors.orangeColor
                  : AppColors.mediumGrayColor,
            ),
            label: 'الحساب',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        selectedItemColor: AppColors.orangeColor,
        unselectedItemColor: AppColors.mediumGrayColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
