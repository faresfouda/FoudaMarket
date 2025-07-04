import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';

import '../views/product/product_screen.dart';

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final String quantityInfo;
  final String? originalPrice;
  final String? discountedPrice;
  final VoidCallback onAddPressed;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.quantityInfo,
    this.originalPrice,
    this.discountedPrice,
    required this.onAddPressed,
    required this.isFavorite,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate discount percent if both prices are present
    String? discountBadge;
    if (originalPrice != null && discountedPrice != null) {
      // Extract numbers from Arabic prices
      final orig = int.tryParse(originalPrice!.replaceAll(RegExp(r'[^0-9]'), ''));
      final disc = int.tryParse(discountedPrice!.replaceAll(RegExp(r'[^0-9]'), ''));
      if (orig != null && disc != null && orig > disc) {
        final percent = ((orig - disc) / orig * 100).round();
        discountBadge = 'خصم $percent٪';
      }
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            imageUrl: imageUrl,
            productName: productName,
            quantityInfo: quantityInfo,
            price: discountedPrice ?? originalPrice ?? '',
          ),
        ));
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Card(
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.0),
                  child: Image.network(
                    imageUrl,
                    height: 90.0,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90.0,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                // Product Name
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
                const Spacer(),
                if (discountBadge != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orangeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      discountBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
                // Price + Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: (originalPrice != null && discountedPrice != null)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  originalPrice!,
                                  style: const TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  discountedPrice!,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.orangeColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : Text(
                              discountedPrice ?? originalPrice ?? '',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orangeColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: onFavoritePressed,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18.0),
                              border: Border.all(color: AppColors.orangeColor, width: 1.5),
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: AppColors.orangeColor,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onAddPressed,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.orangeColor,
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
