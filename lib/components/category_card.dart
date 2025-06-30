import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';

class CategoryCard extends StatelessWidget {
  final String imageUrl; // URL for the category image
  final String categoryName; // Name of the category
  final VoidCallback onTap; // Callback function when the card is tapped

  // Constructor for the CategoryCard widget, requiring all parameters.
  const CategoryCard({
    super.key,
    required this.imageUrl,
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 105,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: Color(0xFFFEF2E4),
          elevation: 2.0, // Lighter shadow for category cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners for the card
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Category Image
                ClipOval(
                  child: Image.network(
                    imageUrl,
                    height: 60.0, // Fixed height for the circular image
                    width: 60.0,
                    fit: BoxFit.cover, // Cover the circular area
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.category, color: Colors.grey, size: 30),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16.0), // Space between image and text

                // Category Name
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
