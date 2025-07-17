import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fouda_market/theme/appcolors.dart';

class BannerCarousel extends StatelessWidget {
  final PageController controller;
  final List<String> banners;

  const BannerCarousel({required this.controller, required this.banners});

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
              itemBuilder: (context, index) => Image.asset(banners[index], fit: BoxFit.cover, width: double.infinity),
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