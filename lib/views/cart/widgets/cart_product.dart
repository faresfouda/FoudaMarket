import 'package:flutter/material.dart';
import '../../../theme/appcolors.dart';
import '../../../components/cached_image.dart';

class ProductQuantityControl extends StatefulWidget {
  final String imageUrl;
  final String productName;
  final String quantityInfo;
  final String price;
  final VoidCallback? onRemove;

  const ProductQuantityControl({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.quantityInfo,
    required this.price,
    this.onRemove,
  });

  @override
  State<ProductQuantityControl> createState() => _ProductQuantityControlState();
}

class _ProductQuantityControlState extends State<ProductQuantityControl> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CachedImage(
                  imageUrl: widget.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // Product info and price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.quantityInfo,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        // + button
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.orangeColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _incrementQuantity,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Quantity
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // - button
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.orangeColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _decrementQuantity,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price
              Text(
                widget.price,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6F00), // Orange
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        // Remove button (top left)
        Positioned(
          top: 6,
          left: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
