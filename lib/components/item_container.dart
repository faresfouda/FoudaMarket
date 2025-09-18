import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/components/cached_image.dart';
import 'package:fouda_market/blocs/cart/index.dart';
import 'package:fouda_market/models/cart_item_model.dart';

import '../views/product/product_screen.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onAddPressed;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onAddPressed,
  });

  bool _isBaseUnitAvailable() {
    if (product.units != null && product.units!.isNotEmpty) {
      final primaryUnit = product.units!.firstWhere(
            (unit) => unit.isPrimary,
        orElse: () => product.units!.first,
      );
      return primaryUnit.isActive;
    }
    return true; // إذا لم تكن هناك وحدات، نفترض أنها متوفرة
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280), // تقليل الارتفاع الأقصى
            child: Padding(
              padding: const EdgeInsets.all(8.0), // تقليل padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Image
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: product.images.isNotEmpty
                          ? CachedImage(
                        imageUrl: product.images.first,
                        width: 80, // تقليل حجم الصورة
                        height: 80,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6.0), // تقليل المسافة
                  // Product Name
                  Flexible(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13.0, // تقليل حجم الخط
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 2.0), // تقليل المسافة
                  // Quantity Info
                  Flexible(
                    child: Text(
                      product.unit,
                      style: const TextStyle(
                        fontSize: 11.0, // تقليل حجم الخط
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 4.0), // تقليل المسافة
                  // Discount Badge
                  if (product.hasDiscount) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 2), // تقليل margin
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // تقليل padding
                      decoration: BoxDecoration(
                        color: AppColors.orangeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'خصم ${product.discountPercentage.toStringAsFixed(0)}٪',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9, // تقليل حجم الخط
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4.0), // تقليل المسافة
                  // Price Section
                  if (product.originalPrice != null && product.price != product.originalPrice) ...[
                    Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      '${product.originalPrice?.toStringAsFixed(0) ?? product.price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ] else ...[
                    Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                        fontSize: 13.0, // تقليل حجم الخط
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ],
                  const SizedBox(height: 6.0), // تقليل المسافة
                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Favorite Button
                      InkWell(
                        onTap: onFavoritePressed,
                        borderRadius: BorderRadius.circular(16.0), // تقليل الحجم
                        child: Container(
                          width: 32, // تقليل الحجم
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: AppColors.orangeColor, width: 1.5),
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: AppColors.orangeColor,
                            size: 18, // تقليل حجم الأيقونة
                          ),
                        ),
                      ),
                      // Add Button
                      InkWell(
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // التحقق من توافر الوحدة الأساسية
                            bool isBaseUnitAvailable = true;
                            String selectedUnit;
                            double selectedPrice;

                            if (product.units != null && product.units!.isNotEmpty) {
                              // البحث عن الوحدة الأساسية أولاً
                              final primaryUnit = product.units!.firstWhere(
                                    (unit) => unit.isPrimary,
                                orElse: () => product.units!.first,
                              );
                              selectedUnit = primaryUnit.name;
                              selectedPrice = primaryUnit.price;
                              isBaseUnitAvailable = primaryUnit.isActive; // التحقق من توافر الوحدة الأساسية
                            } else {
                              // استخدام الوحدة الأساسية للمنتج
                              selectedUnit = product.unit;
                              selectedPrice = product.price;
                              // إذا لم تكن هناك وحدات، نفترض أن الوحدة الأساسية متوفرة
                              isBaseUnitAvailable = true;
                            }

                            if (!isBaseUnitAvailable) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('هذا المنتج غير متوفر حالياً'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final cartItem = CartItemModel(
                              id: '', // سيتم إنشاؤه تلقائياً من Firebase
                              userId: user.uid,
                              productId: product.id,
                              productName: product.name,
                              productImage: product.images.isNotEmpty ? product.images.first : null,
                              price: selectedPrice,
                              quantity: 1,
                              unit: selectedUnit,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            context.read<CartBloc>().add(AddToCart(cartItem));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم إضافة ${product.name} ($selectedUnit) إلى السلة'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى تسجيل الدخول أولاً'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16.0), // تقليل الحجم
                        child: Container(
                          width: 32, // تقليل الحجم
                          height: 32,
                          decoration: BoxDecoration(
                            color: _isBaseUnitAvailable() ? AppColors.orangeColor : Colors.grey,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ), // تقليل حجم الأيقونة
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}