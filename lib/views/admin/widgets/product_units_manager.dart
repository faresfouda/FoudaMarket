import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../../theme/appcolors.dart';
import 'product_text_field.dart';

class ProductUnitsManager extends StatefulWidget {
  final List<ProductUnit>? initialUnits;
  final ValueChanged<List<ProductUnit>> onUnitsChanged;

  const ProductUnitsManager({
    Key? key,
    this.initialUnits,
    required this.onUnitsChanged,
  }) : super(key: key);

  @override
  State<ProductUnitsManager> createState() => _ProductUnitsManagerState();
}

class _ProductUnitsManagerState extends State<ProductUnitsManager> {
  late List<ProductUnit> units;
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> priceControllers = [];
  final List<TextEditingController> offerPriceControllers = [];
  final List<TextEditingController> stockControllers = [];
  final List<bool> hasOfferList = [];
  final List<bool> isActiveList = [];

  @override
  void initState() {
    super.initState();
    units = widget.initialUnits?.toList() ?? [];
    _initializeControllers();
  }

  void _initializeControllers() {
    // تنظيف القوائم
    nameControllers.clear();
    priceControllers.clear();
    offerPriceControllers.clear();
    stockControllers.clear();
    hasOfferList.clear();
    isActiveList.clear();

    // تهيئة القوائم للوحدات الموجودة
    for (int i = 0; i < units.length; i++) {
      final unit = units[i];
      nameControllers.add(TextEditingController(text: unit.name));
      priceControllers.add(TextEditingController(text: unit.price.toString()));
      offerPriceControllers.add(
        TextEditingController(text: unit.originalPrice?.toString() ?? ''),
      );
      stockControllers.add(
        TextEditingController(text: unit.stockQuantity.toString()),
      );
      hasOfferList.add(unit.isSpecialOffer);
      isActiveList.add(unit.isActive);
    }
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in priceControllers) {
      controller.dispose();
    }
    for (var controller in offerPriceControllers) {
      controller.dispose();
    }
    for (var controller in stockControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addUnit() {
    setState(() {
      final newUnit = ProductUnit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        price: 0,
        stockQuantity: 0,
        isActive: true,
      );
      units.add(newUnit);

      // إضافة controllers للوحدة الجديدة
      nameControllers.add(TextEditingController());
      priceControllers.add(TextEditingController());
      offerPriceControllers.add(TextEditingController());
      stockControllers.add(TextEditingController(text: '0'));
      hasOfferList.add(false);
      isActiveList.add(true);
    });
    _updateUnits();
  }

  void _removeUnit(int index) {
    setState(() {
      units.removeAt(index);
      nameControllers[index].dispose();
      priceControllers[index].dispose();
      offerPriceControllers[index].dispose();
      stockControllers[index].dispose();
      nameControllers.removeAt(index);
      priceControllers.removeAt(index);
      offerPriceControllers.removeAt(index);
      stockControllers.removeAt(index);
      hasOfferList.removeAt(index);
      isActiveList.removeAt(index);
    });
    _updateUnits();
  }

  void _updateUnit(int index) {
    if (index < units.length) {
      final name = nameControllers[index].text.trim();
      final price = double.tryParse(priceControllers[index].text.trim()) ?? 0;
      final offerPrice = hasOfferList[index]
          ? double.tryParse(offerPriceControllers[index].text.trim())
          : null;
      final stock = int.tryParse(stockControllers[index].text.trim()) ?? 0;

      units[index] = units[index].copyWith(
        name: name,
        price: price,
        originalPrice: offerPrice,
        isSpecialOffer: hasOfferList[index],
        stockQuantity: stock,
        isActive: isActiveList[index],
      );
      _updateUnits();
    }
  }

  void _updateUnits() {
    // تحديث جميع الوحدات
    for (int i = 0; i < units.length; i++) {
      _updateUnit(i);
    }
    widget.onUnitsChanged(units);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الوحدات الإضافية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addUnit,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة وحدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (units.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'لا توجد وحدات إضافية',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: units.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildUnitCard(index);
            },
          ),
      ],
    );
  }

  Widget _buildUnitCard(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الوحدة ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // زر تفعيل/إلغاء الوحدة
                  Switch(
                    value: isActiveList[index],
                    onChanged: (value) {
                      setState(() {
                        isActiveList[index] = value;
                      });
                      _updateUnit(index);
                    },
                    activeColor: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  // زر حذف الوحدة
                  IconButton(
                    onPressed: () => _removeUnit(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف الوحدة',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // اسم الوحدة
          ProductTextField(
            controller: nameControllers[index],
            labelText: 'اسم الوحدة *',
            prefixIcon: Icons.label,
            hintText: 'مثال: 2 كيلو، 500 جرام',
            onChanged: () => _updateUnit(index),
          ),
          const SizedBox(height: 12),

          // السعر
          ProductTextField(
            controller: priceControllers[index],
            labelText: 'السعر *',
            prefixIcon: Icons.attach_money,
            suffixText: 'ج.م',
            keyboardType: TextInputType.number,
            onChanged: () => _updateUnit(index),
          ),
          const SizedBox(height: 12),

          // العرض الخاص
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Switch(
                      value: hasOfferList[index],
                      onChanged: (value) {
                        setState(() {
                          hasOfferList[index] = value;
                          if (!value) {
                            offerPriceControllers[index].clear();
                          }
                        });
                        _updateUnit(index);
                      },
                      activeColor: AppColors.orangeColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'عرض خاص لهذه الوحدة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (hasOfferList[index]) ...[
                  const SizedBox(height: 12),
                  ProductTextField(
                    controller: offerPriceControllers[index],
                    labelText: 'سعر العرض *',
                    prefixIcon: Icons.local_offer,
                    suffixText: 'ج.م',
                    keyboardType: TextInputType.number,
                    onChanged: () => _updateUnit(index),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // الكمية المتوفرة
          ProductTextField(
            controller: stockControllers[index],
            labelText: 'الكمية المتوفرة',
            prefixIcon: Icons.inventory_2,
            keyboardType: TextInputType.number,
            onChanged: () => _updateUnit(index),
          ),
        ],
      ),
    );
  }
}
