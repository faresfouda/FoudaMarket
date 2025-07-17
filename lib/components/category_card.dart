import 'package:flutter/material.dart';
import 'package:fouda_market/components/cached_image.dart';

class CategoryCard extends StatelessWidget {
  final String imageUrl; // URL for the category image
  final String categoryName; // Name of the category
  final VoidCallback onTap; // Callback function when the card is tapped
  final Color bgColor;

  const CategoryCard({
    super.key,
    required this.imageUrl,
    required this.categoryName,
    required this.onTap,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedImage(
                          imageUrl: imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.category,
                        size: 30,
                        color: Colors.grey[600],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              categoryName,
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
