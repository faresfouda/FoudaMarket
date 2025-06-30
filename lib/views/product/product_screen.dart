import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fodamarket/components/Button.dart' show Button;
import 'package:fodamarket/theme/appcolors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  final String imageUrl;
  final String productName;
  final String quantityInfo;
  final String price;

  const ProductDetailScreen({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.quantityInfo,
    required this.price,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1; // State for the product quantity
  bool _isNutritionsExpanded = true; // State for Nutritions expansion
  bool _isReviewExpanded = false; // State for Review expansion
  final PageController _pageController = PageController();
  final List<String> banners = [
    'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
    'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
    'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
  ]; // Example image URLs for the product images
  List<bool> isSelected = [true, false];
  List<String> quantityOptions = ['100 جرام', '250 جرام'];
  String selectedQuantity = '100 جرام';




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload, color: Colors.black),
            onPressed: () {
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // Allows the body to extend behind the app bar
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section
        SizedBox(
        height: 300,
        width: double.infinity,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    banners[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.error)),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: banners.length,
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
      ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name and Favorite Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.productName,
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border, color: Colors.grey),
                            onPressed: () {
                              // Handle favorite button press
                              // ignore: avoid_print
                              print('Favorite button pressed');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),

                      // Quantity Info
                      Text(
                        widget.quantityInfo,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Quantity Selector and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quantity Selector
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      if (_quantity > 1) _quantity--;
                                    });
                                  },
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      _quantity++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Text(
                            widget.price,
                            style: const TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),



                      // Nutritions Section
                      _buildExpandableSection(
                        title: 'الكمية',
                        contentWidget: ToggleButtons(
                          borderRadius: BorderRadius.circular(8),
                          isSelected: isSelected,
                          onPressed: (index) {
                            setState(() {
                              for (int i = 0; i < isSelected.length; i++) {
                                isSelected[i] = i == index;
                              }
                              selectedQuantity = quantityOptions[index];
                            });
                          },
                          children: quantityOptions.map((q) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(q),
                          )).toList(),
                        ),

                        isExpanded: _isNutritionsExpanded,
                        onTap: () {
                          setState(() {
                            _isNutritionsExpanded = !_isNutritionsExpanded;
                          });
                        },
                        trailingText: selectedQuantity,
                      ),

                      const SizedBox(height: 16.0),

                      // Review Section
                      _buildExpandableSection(
                        title: 'التقييمات',
                        contentWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildReviewTile("أحمد", "منتج رائع! أنصح به", 5),
                          ],
                        ),
                        isExpanded: _isReviewExpanded,
                        onTap: () {
                          setState(() {
                            _isReviewExpanded = !_isReviewExpanded;
                          });
                        },
                        trailingWidget: RatingBarIndicator(
                          rating: 4.2,
                          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                      ),

                      const SizedBox(height: 100), // Space for the bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),
          // "Add To Basket" Button at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0, left: 16.0, right: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Button(
                  onPressed: () {
                    // Handle "Add To Basket" button press
                    // ignore: avoid_print
                    print('Add To Basket button pressed');
                  },
                  buttonContent: const Text(
                    'اضف للعربة',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  buttonColor: AppColors.orangeColor, // Use your defined color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildReviewTile(String user, String comment, double rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: 18.0,
          direction: Axis.horizontal,
        ),
        const SizedBox(height: 4),
        Text(
          comment,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }


  // Helper widget to build expandable sections (Product Detail, Nutritions, Review)
  Widget _buildExpandableSection({
    required String title,
    Widget? contentWidget,
    required bool isExpanded,
    required VoidCallback onTap,
    String? trailingText,
    Widget? trailingWidget,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    if (!isExpanded && trailingText != null)
                      Text(
                        trailingText,
                        style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                      ),
                    if (!isExpanded && trailingWidget != null) trailingWidget,
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && contentWidget != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: contentWidget,
          ),
      ],
    );
  }

}
