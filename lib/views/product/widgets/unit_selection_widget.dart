import 'package:flutter/material.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/theme/appcolors.dart';

class UnitSelectionWidget extends StatelessWidget {
  final List<ProductUnit> units;
  final int selectedUnitIndex;
  final Function(int) onUnitSelected;

  const UnitSelectionWidget({
    super.key,
    required this.units,
    required this.selectedUnitIndex,
    required this.onUnitSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (units.length > 1) {
      return _buildMultipleUnits();
    } else {
      return _buildSingleUnit();
    }
  }

  Widget _buildMultipleUnits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر الوحدة المناسبة:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              final isSelected = index == selectedUnitIndex;
              final isAvailable = unit.isActive;
              final isMain = unit.isPrimary;

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: isAvailable ? () => onUnitSelected(index) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.orangeColor
                          : isAvailable
                              ? Colors.grey[100]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.orangeColor
                            : isAvailable
                                ? Colors.grey[300]!
                                : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              unit.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : isAvailable
                                        ? Colors.black
                                        : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isMain) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (unit.originalPrice != null && unit.price != unit.originalPrice)
                          Text(
                            '${unit.price.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          '${unit.originalPrice?.toStringAsFixed(0) ?? unit.price.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.orangeColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAvailable ? 'متوفر للطلب' : 'غير متوفر',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleUnit() {
    final selectedUnit = units[selectedUnitIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2,
            color: AppColors.orangeColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'الوحدة المتاحة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (selectedUnit.isPrimary) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${selectedUnit.name} - ${selectedUnit.originalPrice?.toStringAsFixed(0) ?? selectedUnit.price.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orangeColor,
                  ),
                ),
                if (selectedUnit.hasDiscount) ...[
                  const SizedBox(height: 2),
                  Text(
                    'السعر الأصلي: ${selectedUnit.originalPrice!.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: selectedUnit.isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedUnit.isActive ? 'متوفر للطلب' : 'غير متوفر',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selectedUnit.isActive ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
