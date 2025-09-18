import 'package:flutter/material.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/components/loading_indicator.dart';
import 'package:fouda_market/components/error_view.dart';
import 'package:fouda_market/core/services/product_service.dart';
import 'package:fouda_market/theme/appcolors.dart';
import '../product_screen.dart';

class SimilarProductsSection extends StatefulWidget {
  final String categoryId;
  final String currentProductId;

  const SimilarProductsSection({
    super.key,
    required this.categoryId,
    required this.currentProductId,
  });

  @override
  State<SimilarProductsSection> createState() => _SimilarProductsSectionState();
}

class _SimilarProductsSectionState extends State<SimilarProductsSection>
    with AutomaticKeepAliveClientMixin {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProductService().getProductsForCategory(
      widget.categoryId,
      limit: 10,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'منتجات مشابهة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.orangeColor,
            ),
          ),
        ),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<ProductModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: ErrorView(message: 'لا توجد منتجات مشابهة'),
                );
              }
              final similarProducts = snapshot.data!
                  .where((p) => p.id != widget.currentProductId)
                  .toList();
              if (similarProducts.isEmpty) {
                return const Center(
                  child: ErrorView(message: 'لا توجد منتجات مشابهة'),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similarProducts.length,
                itemBuilder: (context, index) {
                  final product = similarProducts[index];
                  return SimilarProductCard(
                    product: product,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SimilarProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const SimilarProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: 160,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 160,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${product.price.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (product.hasDiscount)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    Text(
                      '${product.originalPrice?.toStringAsFixed(2) ?? ''} ج.م',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
