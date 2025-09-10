import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../../theme/appcolors.dart';
import 'product_text_field.dart';

class UnifiedUnitsManager extends StatefulWidget {
  final String? initialBaseUnit;
  final double? initialBasePrice;
  final double? initialBaseOfferPrice;
  final int? initialBaseStock;
  final bool? initialBaseHasOffer;
  final bool? initialBaseIsActive; // إضافة معامل جديد
  final List<ProductUnit>? initialAdditionalUnits;
  final ValueChanged<UnifiedUnitsData> onUnitsChanged;

  const UnifiedUnitsManager({
    super.key,
    this.initialBaseUnit,
    this.initialBasePrice,
    this.initialBaseOfferPrice,
    this.initialBaseStock,
    this.initialBaseHasOffer,
    this.initialBaseIsActive, // إضافة معامل جديد
    this.initialAdditionalUnits,
    required this.onUnitsChanged,
  });

  @override
  State<UnifiedUnitsManager> createState() => _UnifiedUnitsManagerState();
}

class _UnifiedUnitsManagerState extends State<UnifiedUnitsManager> {
  late TextEditingController baseUnitController;
  late TextEditingController basePriceController;
  late TextEditingController baseOfferPriceController;
  late TextEditingController baseStockController;
  late bool baseHasOffer;
  late bool baseIsActive;
  late bool baseIsPrimary; // للتمييز بين الوحدة الأساسية والوحدات الإضافية
  late bool baseIsBestSeller;

  late List<ProductUnit> additionalUnits;
  final List<TextEditingController> additionalNameControllers = [];
  final List<TextEditingController> additionalPriceControllers = [];
  final List<TextEditingController> additionalOfferPriceControllers = [];
  final List<TextEditingController> additionalStockControllers = [];
  final List<bool> additionalHasOfferList = [];
  final List<bool> additionalIsActiveList = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // تهيئة الوحدة الأساسية
    baseUnitController = TextEditingController(
      text: widget.initialBaseUnit ?? 'قطعة',
    );
    basePriceController = TextEditingController(
      text: widget.initialBasePrice?.toString() ?? '',
    );
    baseOfferPriceController = TextEditingController(
      text: widget.initialBaseOfferPrice?.toString() ?? '',
    );
    baseStockController = TextEditingController(
      text: widget.initialBaseStock?.toString() ?? '0',
    );
    baseHasOffer = widget.initialBaseHasOffer ?? false;
    baseIsActive =
        widget.initialBaseIsActive ??
        true; // استخدام القيمة المرسلة بدلاً من true ثابتة
    baseIsPrimary = true; // الوحدة الأساسية دائماً primary
    baseIsBestSeller = false;

    // تهيئة الوحدات الإضافية
    additionalUnits = widget.initialAdditionalUnits?.toList() ?? [];
    _initializeAdditionalControllers();
  }

  void _initializeAdditionalControllers() {
    // تنظيف القوائم
    additionalNameControllers.clear();
    additionalPriceControllers.clear();
    additionalOfferPriceControllers.clear();
    additionalStockControllers.clear();
    additionalHasOfferList.clear();
    additionalIsActiveList.clear();

    // تهيئة القوائم للوحدات الموجودة
    for (int i = 0; i < additionalUnits.length; i++) {
      final unit = additionalUnits[i];
      additionalNameControllers.add(TextEditingController(text: unit.name));
      additionalPriceControllers.add(
        TextEditingController(text: unit.price.toString()),
      );
      additionalOfferPriceControllers.add(
        TextEditingController(text: unit.originalPrice?.toString() ?? ''),
      );
      additionalStockControllers.add(
        TextEditingController(text: unit.stockQuantity.toString()),
      );
      additionalHasOfferList.add(unit.isSpecialOffer);
      additionalIsActiveList.add(unit.isActive);
    }
  }

  @override
  void dispose() {
    baseUnitController.dispose();
    basePriceController.dispose();
    baseOfferPriceController.dispose();
    baseStockController.dispose();

    for (var controller in additionalNameControllers) {
      controller.dispose();
    }
    for (var controller in additionalPriceControllers) {
      controller.dispose();
    }
    for (var controller in additionalOfferPriceControllers) {
      controller.dispose();
    }
    for (var controller in additionalStockControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateBaseUnit() {
    final baseUnitData = UnifiedUnitsData(
      baseUnit: baseUnitController.text.trim(),
      basePrice: double.tryParse(basePriceController.text.trim()) ?? 0,
      baseOfferPrice: baseHasOffer
          ? double.tryParse(baseOfferPriceController.text.trim())
          : null,
      baseStock: int.tryParse(baseStockController.text.trim()) ?? 0,
      baseHasOffer: baseHasOffer,
      baseIsActive: baseIsActive,
      baseIsPrimary: baseIsPrimary,
      baseIsBestSeller: baseIsBestSeller,
      additionalUnits: additionalUnits,
    );
    widget.onUnitsChanged(baseUnitData);
  }

  void _addAdditionalUnit() {
    setState(() {
      final newUnit = ProductUnit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        price: 0,
        stockQuantity: 0,
        isActive: true,
        isPrimary: false, // الوحدات الإضافية ليست أساسية
      );
      additionalUnits.add(newUnit);

      // إضافة controllers للوحدة الجديدة
      additionalNameControllers.add(TextEditingController());
      additionalPriceControllers.add(TextEditingController());
      additionalOfferPriceControllers.add(TextEditingController());
      additionalStockControllers.add(TextEditingController(text: '0'));
      additionalHasOfferList.add(false);
      additionalIsActiveList.add(true);
    });
    _updateBaseUnit();
  }

  void _removeAdditionalUnit(int index) {
    setState(() {
      additionalUnits.removeAt(index);
      additionalNameControllers[index].dispose();
      additionalPriceControllers[index].dispose();
      additionalOfferPriceControllers[index].dispose();
      additionalStockControllers[index].dispose();
      additionalNameControllers.removeAt(index);
      additionalPriceControllers.removeAt(index);
      additionalOfferPriceControllers.removeAt(index);
      additionalStockControllers.removeAt(index);
      additionalHasOfferList.removeAt(index);
      additionalIsActiveList.removeAt(index);
    });
    _updateBaseUnit();
  }

  void _updateAdditionalUnit(int index) {
    if (index < additionalUnits.length) {
      final name = additionalNameControllers[index].text.trim();
      final price =
          double.tryParse(additionalPriceControllers[index].text.trim()) ?? 0;
      final offerPrice = additionalHasOfferList[index]
          ? double.tryParse(additionalOfferPriceControllers[index].text.trim())
          : null;
      final stock =
          int.tryParse(additionalStockControllers[index].text.trim()) ?? 0;

      additionalUnits[index] = additionalUnits[index].copyWith(
        name: name,
        price: price,
        originalPrice: offerPrice,
        isSpecialOffer: additionalHasOfferList[index],
        stockQuantity: stock,
        isActive: additionalIsActiveList[index],
        isPrimary: false, // الوحدات الإضافية ليست أساسية
      );
      _updateBaseUnit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الوحدة الأساسية
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'الوحدة الأساسية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // اسم الوحدة الأساسية
              ProductTextField(
                controller: baseUnitController,
                labelText: 'اسم الوحدة الأساسية *',
                prefixIcon: Icons.label,
                hintText: 'مثال: قطعة، كيلو، لتر',
                onChanged: () => _updateBaseUnit(),
              ),
              const SizedBox(height: 12),

              // سعر الوحدة الأساسية
              ProductTextField(
                controller: basePriceController,
                labelText: 'سعر الوحدة الأساسية *',
                prefixIcon: Icons.attach_money,
                suffixText: 'ج.م',
                keyboardType: TextInputType.number,
                onChanged: () => _updateBaseUnit(),
              ),
              const SizedBox(height: 12),

              // عرض خاص للوحدة الأساسية
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
                          value: baseHasOffer,
                          onChanged: (value) {
                            setState(() {
                              baseHasOffer = value;
                              if (!value) {
                                baseOfferPriceController.clear();
                              }
                            });
                            _updateBaseUnit();
                          },
                          activeColor: AppColors.orangeColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'عرض خاص للوحدة الأساسية',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    if (baseHasOffer) ...[
                      const SizedBox(height: 12),
                      ProductTextField(
                        controller: baseOfferPriceController,
                        labelText: 'سعر العرض *',
                        prefixIcon: Icons.local_offer,
                        suffixText: 'ج.م',
                        keyboardType: TextInputType.number,
                        onChanged: () => _updateBaseUnit(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // الكمية المتوفرة للوحدة الأساسية
              ProductTextField(
                controller: baseStockController,
                labelText: 'الكمية المتوفرة',
                prefixIcon: Icons.inventory_2,
                keyboardType: TextInputType.number,
                onChanged: () => _updateBaseUnit(),
              ),
              const SizedBox(height: 12),

              // حالة توفر الوحدة الأساسية
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Switch(
                      value: baseIsActive,
                      onChanged: (value) {
                        setState(() {
                          baseIsActive = value;
                        });
                        _updateBaseUnit();
                      },
                      activeColor: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'توافر الوحدة الأساسية',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'التحكم في توافر هذه الوحدة للبيع',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // خيار أكثر مبيعاً
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Switch(
                      value: baseIsBestSeller,
                      onChanged: (value) {
                        setState(() {
                          baseIsBestSeller = value;
                        });
                        _updateBaseUnit();
                      },
                      activeColor: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'منتج من الأكثر مبيعاً',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // الوحدات الإضافية
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
              onPressed: _addAdditionalUnit,
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

        if (additionalUnits.isEmpty)
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
            itemCount: additionalUnits.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildAdditionalUnitCard(index);
            },
          ),
      ],
    );
  }

  Widget _buildAdditionalUnitCard(int index) {
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
                'الوحدة الإضافية ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // زر حذف الوحدة
              IconButton(
                onPressed: () => _removeAdditionalUnit(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'حذف الوحدة',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // اسم الوحدة الإضافية
          ProductTextField(
            controller: additionalNameControllers[index],
            labelText: 'اسم الوحدة *',
            prefixIcon: Icons.label,
            hintText: 'مثال: 2 كيلو، 500 جرام',
            onChanged: () => _updateAdditionalUnit(index),
          ),
          const SizedBox(height: 12),

          // السعر
          ProductTextField(
            controller: additionalPriceControllers[index],
            labelText: 'السعر *',
            prefixIcon: Icons.attach_money,
            suffixText: 'ج.م',
            keyboardType: TextInputType.number,
            onChanged: () => _updateAdditionalUnit(index),
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
                      value: additionalHasOfferList[index],
                      onChanged: (value) {
                        setState(() {
                          additionalHasOfferList[index] = value;
                          if (!value) {
                            additionalOfferPriceControllers[index].clear();
                          }
                        });
                        _updateAdditionalUnit(index);
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
                if (additionalHasOfferList[index]) ...[
                  const SizedBox(height: 12),
                  ProductTextField(
                    controller: additionalOfferPriceControllers[index],
                    labelText: 'سعر العرض *',
                    prefixIcon: Icons.local_offer,
                    suffixText: 'ج.م',
                    keyboardType: TextInputType.number,
                    onChanged: () => _updateAdditionalUnit(index),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // الكمية المتوفرة
          ProductTextField(
            controller: additionalStockControllers[index],
            labelText: 'الكمية المتوفرة',
            prefixIcon: Icons.inventory_2,
            keyboardType: TextInputType.number,
            onChanged: () => _updateAdditionalUnit(index),
          ),
          const SizedBox(height: 12),

          // حالة توفر الوحدة الإضافية
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Switch(
                  value: additionalIsActiveList[index],
                  onChanged: (value) {
                    setState(() {
                      additionalIsActiveList[index] = value;
                    });
                    _updateAdditionalUnit(index);
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'توافر الوحدة الإضافية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'التحكم في توافر هذه الوحدة للبيع',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UnifiedUnitsData {
  final String baseUnit;
  final double basePrice;
  final double? baseOfferPrice;
  final int baseStock;
  final bool baseHasOffer;
  final bool baseIsActive;
  final bool baseIsPrimary;
  final bool baseIsBestSeller;
  final List<ProductUnit> additionalUnits;

  UnifiedUnitsData({
    required this.baseUnit,
    required this.basePrice,
    this.baseOfferPrice,
    required this.baseStock,
    required this.baseHasOffer,
    required this.baseIsActive,
    this.baseIsPrimary = true,
    this.baseIsBestSeller = false,
    required this.additionalUnits,
  });
}
