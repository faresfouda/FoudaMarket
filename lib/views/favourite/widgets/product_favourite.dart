import 'package:flutter/material.dart';
import '../../../../theme/appcolors.dart';
import '../../../../views/product/product_screen.dart';

class FavoriteItemCard extends StatefulWidget {
  final String imageUrl;
  final String productName;
  final String quantityInfo;
  final String price;
  final VoidCallback? onRemove;

  const FavoriteItemCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.quantityInfo,
    required this.price,
    this.onRemove,
  });

  @override
  State<FavoriteItemCard> createState() => _FavoriteItemCardState();
}

class _FavoriteItemCardState extends State<FavoriteItemCard> {
  bool isFav = true;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              imageUrl: widget.imageUrl,
              productName: widget.productName,
              quantityInfo: widget.quantityInfo,
              price: widget.price,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product Image
                  Image.network(
                    widget.imageUrl,
                    height: 80.0,
                    width: 80.0,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 60.0,
                      width: 60.0,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    ),
                  ),
                  const SizedBox(width: 30),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.quantityInfo,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.lightGrayColor2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.price,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Favorite toggle (heart icon) in top-left corner
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    isFav = !isFav;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
