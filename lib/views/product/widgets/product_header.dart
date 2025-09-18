import 'package:flutter/material.dart';
import 'package:fouda_market/models/product_model.dart';

class ProductHeader extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final bool favoriteLoading;
  final VoidCallback onFavoritePressed;

  const ProductHeader({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.favoriteLoading,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            product.name,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
          ),
          tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
          onPressed: favoriteLoading ? null : onFavoritePressed,
        ),
      ],
    );
  }
}
