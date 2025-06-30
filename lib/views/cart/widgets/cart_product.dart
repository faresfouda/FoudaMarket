import 'package:flutter/material.dart';
import '../../../theme/appcolors.dart';

class ProductQuantityControl extends StatefulWidget {
  final String imageUrl;
  final String productName;
  final String quantityInfo;
  final String price;
  final VoidCallback? onClosePressed;

  const ProductQuantityControl({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.quantityInfo,
    required this.price,
    this.onClosePressed,
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.lightGrayColor3, width: 1),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.remove, color: AppColors.orangeColor, size: 20),
                              onPressed: _decrementQuantity,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$_quantity',
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.lightGrayColor3, width: 1),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: AppColors.orangeColor, size: 20),
                              onPressed: _incrementQuantity,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const Spacer(),
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
                    ],
                  ),
                ),

              ],
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: widget.onClosePressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
