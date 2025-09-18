import 'package:flutter/material.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/theme/appcolors.dart';

class TotalPriceDisplay extends StatelessWidget {
  final ProductUnit selectedUnit;
  final int quantity;

  const TotalPriceDisplay({
    super.key,
    required this.selectedUnit,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'السعر الإجمالي',
          style: TextStyle(
            fontSize: 11.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        if (selectedUnit.hasDiscount) ...[
          Text(
            '${(selectedUnit.originalPrice! * quantity).toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            '${((selectedUnit.originalPrice ?? selectedUnit.price) * quantity).toStringAsFixed(0)} ج.م',
            key: ValueKey(
              (selectedUnit.originalPrice ?? selectedUnit.price) * quantity,
            ),
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.orangeColor,
            ),
          ),
        ),
      ],
    );
  }
}
