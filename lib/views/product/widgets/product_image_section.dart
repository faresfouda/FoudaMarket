import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fouda_market/components/cached_image.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/theme/appcolors.dart';

class ProductImageSection extends StatefulWidget {
  final ProductModel product;

  const ProductImageSection({super.key, required this.product});

  @override
  State<ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends State<ProductImageSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.product.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return CachedImage(
                  imageUrl: widget.product.images[index],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          if (widget.product.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.product.images.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 10,
                    expansionFactor: 4,
                    activeDotColor: AppColors.orangeColor,
                    dotColor: AppColors.lightGrayColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
