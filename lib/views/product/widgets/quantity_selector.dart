import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onMaxQuantityReached;
  final bool isShaking;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.minQuantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
    required this.onMaxQuantityReached,
    required this.isShaking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.orangeColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر النقصان
          _buildQuantityButton(
            icon: Icons.remove,
            isEnabled: quantity > minQuantity,
            onTap: () => onQuantityChanged(quantity - 1),
          ),
          // عرض الكمية
          Container(
            width: 60,
            height: 40,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isShaking
                  ? Matrix4.translationValues(3, 0, 0)
                  : Matrix4.translationValues(0, 0, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          // زر الزيادة
          _buildQuantityButton(
            icon: Icons.add,
            isEnabled: quantity < maxQuantity,
            onTap: quantity < maxQuantity
                ? () => onQuantityChanged(quantity + 1)
                : onMaxQuantityReached,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.orangeColor : Colors.grey[100],
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.orangeColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: onTap,
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.grey[400],
            size: 20,
          ),
        ),
      ),
    );
  }
}
