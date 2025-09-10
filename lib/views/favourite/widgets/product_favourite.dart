import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../theme/appcolors.dart';
import '../../../../views/product/product_screen.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_event.dart';
import '../../../models/product_model.dart';

class FavoriteItemCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onRemove;

  const FavoriteItemCard({super.key, required this.product, this.onRemove});

  @override
  State<FavoriteItemCard> createState() => _FavoriteItemCardState();
}

class _FavoriteItemCardState extends State<FavoriteItemCard> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  void _toggleFavorite() {
    if (currentUserId != null) {
      context.read<ProductBloc>().add(
        RemoveFromFavorites(currentUserId!, widget.product.id),
      );
      if (widget.onRemove != null) {
        widget.onRemove!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: widget.product),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.product.images.isNotEmpty
                        ? Image.network(
                            widget.product.images.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 30),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.unit ?? 'وحدة',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.lightGrayColor2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.product.price.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orangeColor,
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
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: _toggleFavorite,
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
