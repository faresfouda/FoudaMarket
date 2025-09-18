import 'package:flutter/material.dart';
import 'package:fouda_market/components/cached_image.dart';

class CategoryCard extends StatelessWidget {
  final String imageUrl;
  final String categoryName;
  final VoidCallback onTap;
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
              width: 60, // Increased size from 50 to 60
              height: 60, // Increased size from 50 to 60
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.1), // Added transparency to the background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: bgColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _buildImageWidget(),
              ),
            ),
            const SizedBox(height: 8), // Increased space from 5 to 8
            Flexible(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 12.0, // Slightly reduced font size
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Check if image URL exists
    if (imageUrl.isEmpty || imageUrl == 'null') {
      return _buildDefaultIcon();
    }

    return CachedImage(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: _buildLoadingPlaceholder(),
      errorWidget: _buildDefaultIcon(),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(bgColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        Icons.category_outlined,
        size: 32,
        color: bgColor.withValues(alpha: 0.8),
      ),
    );
  }
}
