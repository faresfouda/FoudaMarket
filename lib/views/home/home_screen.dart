import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fodamarket/components/category_card.dart';
import 'package:fodamarket/components/item_container.dart';
import 'package:fodamarket/views/category/category_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'widgets/my_searchbutton.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final List<String> _banners = [
    'assets/home/offerbanner1.jpg',
    'assets/home/offerbanner1.jpg',
    'assets/home/offerbanner1.jpg',
  ];
  Timer? _autoScrollTimer;

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _banners.length) nextPage = 0;

        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Image.asset('assets/home/logo.jpg', height: 50),
              SizedBox(height: 10),
              _LocationRow(),
              SizedBox(height: 20),
              SearchButton(),
              SizedBox(height: 20),
              _BannerCarousel(controller: _pageController, banners: _banners),
              SizedBox(height: 30),
              _SectionHeader(title: 'عروض خاصة', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen(categoryName: 'عروض خاصة',)));
              }),
              SizedBox(height: 20),
              _HorizontalProductList(),
              SizedBox(height: 30),
              _SectionHeader(title: 'الاكثر مبيعاَ', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen(categoryName: 'الاكثر مبيعاَ',)));
              }),
              SizedBox(height: 20),
              _HorizontalProductList(),
              SizedBox(height: 30),
              _SectionHeader(title: 'الاقسام', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen(categoryName: 'الاقسام',)));
              }),
              SizedBox(height: 20),
              _CategoryList(),
              SizedBox(height: 20),
              _HorizontalProductList(),
            ],
          ),
        ),
      ),
    );
  }

}
class _LocationRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on, color: AppColors.lightGrayColor),
        SizedBox(width: 5),
        Text(
          'دمياط، السنانية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.lightGrayColor,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 22),
      ],
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final PageController controller;
  final List<String> banners;

  const _BannerCarousel({
    required this.controller,
    required this.banners,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: PageView.builder(
              controller: controller,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  banners[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: SmoothPageIndicator(
              controller: controller,
              count: banners.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 4,
                spacing: 10,
                activeDotColor: AppColors.orangeColor,
                dotColor: AppColors.lightGrayColor.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.blackColor,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'عرض الكل',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.orangeColor,
            ),
          ),
        ),
      ],
    );
  }
}
class _HorizontalProductList extends StatelessWidget {
  final List<Map<String, String>> products = const [
    {
      'name': 'موز عضوي',
      'quantity': '١ كجم',
      'price': '٤٥ ج.م',
      'image': 'https://i.pinimg.com/736x/7a/aa/a5/7aaaa545e00e8a434850e80b8910dd94.jpg',
    },
    {
      'name': 'تفاح أحمر',
      'quantity': '٢ كجم',
      'price': '٦٠ ج.م',
      'image': 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'برتقال عصير',
      'quantity': '١.٥ كجم',
      'price': '٣٥ ج.م',
      'image': 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=400&q=80',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index % products.length];
          return ProductCard(
            imageUrl: product['image']!,
            productName: product['name']!,
            quantityInfo: product['quantity']!,
            price: product['price']!,
            onAddPressed: () => print('${product['name']} أضيفت إلى العربة!'),
          );
        },
      ),
    );
  }
}
class _CategoryList extends StatelessWidget {
  final List<String> categories = const [
    'خضروات',
    'فواكه',
    'مشروبات',
    'مخبوزات',
  ];
  final List<String> categoryImages = const [
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', // Vegetables
    'https://i.pinimg.com/736x/7a/aa/a5/7aaaa545e00e8a434850e80b8910dd94.jpg', // Fruits
    'https://i.pinimg.com/736x/7a/aa/a5/7aaaa545e00e8a434850e80b8910dd94.jpg', // Drinks
    'https://images.unsplash.com/photo-1505250469679-203ad9ced0cb?auto=format&fit=crop&w=400&q=80', // Bakery
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryCard(
            imageUrl: categoryImages[index % categoryImages.length],
            categoryName: categories[index],
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen(categoryName: categories[index],)));
            },
          );
        },
      ),
    );
  }
}
