import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';
import '../../services/cloudinary_service.dart';
import '../../services/image_compression_service.dart';
import '../../models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import 'widgets/index.dart';
import 'widgets/unified_units_manager.dart';
import '../../components/connection_aware_widget.dart';

class AddProductScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final ProductModel? editing;

  const AddProductScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.editing,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? pickedImage;
  bool isUploading = false;
  bool isVisible = true; // للتحكم في إظهار/إخفاء المنتج
  String? imageUrl;
  UnifiedUnitsData? unitsData;
  bool _isOffline = false; // جديد

  @override
  void initState() {
    super.initState();

    // تعيين الفئة الحالية في ProductBloc
    context.read<ProductBloc>().add(SetCurrentCategory(widget.categoryId));

    if (widget.editing != null) {
      final p = widget.editing!;
      nameController.text = p.name;
      descriptionController.text = p.description ?? '';
      isVisible = p.isVisible;
      imageUrl = (p.images.isNotEmpty) ? p.images.first : null;

      // تهيئة بيانات الوحدات الموحدة
      unitsData = UnifiedUnitsData(
        baseUnit: p.unit,
        basePrice: p.price,
        baseOfferPrice: p.originalPrice,
        baseStock: p.stockQuantity,
        baseHasOffer: p.isSpecialOffer,
        baseIsActive: _getBaseUnitIsActive(p.units), // استخراج baseIsActive من الوحدة الأساسية
        baseIsPrimary: true, // الوحدة الأساسية دائماً primary
        baseIsBestSeller: p.isBestSeller,
        additionalUnits: p.units?.where((unit) => !unit.isPrimary).toList() ?? [],
      );
    } else {
      // تهيئة بيانات الوحدات الافتراضية
      unitsData = UnifiedUnitsData(
        baseUnit: 'قطعة',
        basePrice: 0,
        baseStock: 0,
        baseHasOffer: false,
        baseIsActive: true,
        baseIsPrimary: true, // الوحدة الأساسية دائماً primary
        baseIsBestSeller: false,
        additionalUnits: [],
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (mounted && picked != null) {
      final compressed = await ImageCompressionService().compressImageFile(
        File(picked.path),
      );
      setState(() {
        pickedImage = compressed ?? File(picked.path);
        imageUrl = null;
      });
    }
  }

  void _showValidationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> saveProduct() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showValidationError('يرجى إدخال اسم المنتج');
      return;
    }

    final description = descriptionController.text.trim();
    setState(() {
      isUploading = true;
    });
    final now = DateTime.now();

    if (widget.editing != null) {
      // تعديل منتج
      final updatedProduct = widget.editing!.copyWith(
        name: name,
        price: unitsData?.basePrice ?? 0,
        originalPrice: unitsData?.baseHasOffer == true
            ? unitsData?.baseOfferPrice
            : null,
        unit: unitsData?.baseUnit ?? 'قطعة',
        description: description.isNotEmpty ? description : null,
        isSpecialOffer: unitsData?.baseHasOffer ?? false,
        isBestSeller: unitsData?.baseIsBestSeller ?? false,
        isVisible: isVisible, // استخدام isVisible بدلاً من baseIsActive
        stockQuantity: unitsData?.baseStock ?? 0,
        units: _buildUpdatedUnits(), // بناء الوحدات مع baseIsActive
        updatedAt: now,
      );
      if (pickedImage != null) {
        context.read<ProductBloc>().add(
          UpdateProductWithImage(updatedProduct, pickedImage!),
        );
      } else {
        context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
      }
    } else {
      // إضافة منتج جديد
      if (pickedImage == null) {
        setState(() {
          isUploading = false;
        });
        _showValidationError('يرجى اختيار صورة للمنتج');
        return;
      }
      final productId = now.millisecondsSinceEpoch.toString();
      final product = ProductModel(
        id: productId,
        name: name,
        description: description.isNotEmpty ? description : null,
        images: [], // سيتم تعبئتها في الـ Bloc
        price: unitsData?.basePrice ?? 0,
        originalPrice: unitsData?.baseHasOffer == true
            ? unitsData?.baseOfferPrice
            : null,
        unit: unitsData?.baseUnit ?? 'قطعة',
        categoryId: widget.categoryId,
        isSpecialOffer: unitsData?.baseHasOffer ?? false,
        isBestSeller: unitsData?.baseIsBestSeller ?? false,
        isVisible: isVisible, // استخدام isVisible بدلاً من baseIsActive
        stockQuantity: unitsData?.baseStock ?? 0,
        units: _buildUpdatedUnits(), // بناء الوحدات مع baseIsActive
        createdAt: now,
        updatedAt: now,
      );
      context.read<ProductBloc>().add(
        AddProductWithImage(product, pickedImage!),
      );
    }
  }

  bool _getBaseUnitIsActive(List<ProductUnit>? units) {
    if (units == null || units.isEmpty) return true; // افتراضياً متوفر إذا لم تكن هناك وحدات
    final baseUnit = units.firstWhere(
      (unit) => unit.isPrimary,
      orElse: () => units.first, // إذا لم تكن هناك وحدة أساسية، استخدم الأولى
    );
    return baseUnit.isActive;
  }

  List<ProductUnit> _buildUpdatedUnits() {
    final List<ProductUnit> updatedUnits = [];
    if (unitsData?.baseUnit != null) {
      updatedUnits.add(
        ProductUnit(
          id: 'base',
          name: unitsData!.baseUnit!,
          price: unitsData!.basePrice,
          originalPrice: unitsData!.baseOfferPrice,
          stockQuantity: unitsData!.baseStock,
          isSpecialOffer: unitsData!.baseHasOffer,
          isActive: unitsData!.baseIsActive,
          isPrimary: unitsData!.baseIsPrimary,
        ),
      );
    }
    if (unitsData?.additionalUnits.isNotEmpty == true) {
      updatedUnits.addAll(unitsData!.additionalUnits);
    }
    return updatedUnits;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return ConnectionAwareWidget(
      onConnectionChanged: (offline) {
        if (_isOffline != offline) {
          setState(() {
            _isOffline = offline;
          });
        }
      },
      child: BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsError) {
          setState(() {
            isUploading = false;
          });
          _showValidationError(state.message);
        } else if (state is ProductsLoaded) {
          setState(() {
            isUploading = false;
          });
          _showSuccessMessage(
            isEdit ? 'تم حفظ التعديلات بنجاح' : 'تم إضافة المنتج بنجاح',
          );
          if (mounted) {
            // تأخير قليل قبل العودة للخلف لضمان ظهور الرسالة
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context);
            });
          }
        } else if (state is ProductsLoading) {
          setState(() {
            isUploading = true;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            isEdit
                ? 'تعديل منتج - ${widget.categoryName}'
                : 'إضافة منتج - ${widget.categoryName}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                backgroundImage: const AssetImage('assets/home/logo.jpg'),
                radius: 18,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // معلومات المنتج الأساسية
              ProductFormSection(
                title: 'معلومات المنتج',
                icon: Icons.info_outline,
                children: [
                  ProductTextField(
                    controller: nameController,
                    labelText: 'اسم المنتج *',
                    prefixIcon: Icons.inventory,
                  ),
                  const SizedBox(height: 16),
                  ProductTextField(
                    controller: descriptionController,
                    labelText: 'وصف المنتج',
                    prefixIcon: Icons.description,
                    maxLines: 3,
                    alignLabelWithHint: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // صورة المنتج
              ProductFormSection(
                title: 'صورة المنتج *',
                icon: Icons.image,
                children: [
                  ProductImagePicker(
                    pickedImage: pickedImage,
                    imageUrl: imageUrl,
                    onTap: pickImage,
                  ),
                  if (pickedImage != null) ...[
                    const SizedBox(height: 16),
                    ImageCompressionInfoWidget(
                      imageFile: pickedImage,
                      onCompress: () async {
                        // ضغط الصورة
                        final compressedFile = await ImageCompressionService()
                            .compressImageSmart(pickedImage!);
                        if (compressedFile != null && mounted) {
                          setState(() {
                            pickedImage = compressedFile;
                          });
                          _showSuccessMessage('تم ضغط الصورة بنجاح');
                        } else {
                          _showValidationError('فشل في ضغط الصورة');
                        }
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // حالة التوفر
              ProductFormSection(
                title: 'حالة التوفر',
                icon: Icons.check_circle_outline,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Switch(
                          value: isVisible,
                          onChanged: (val) {
                            setState(() {
                              isVisible = val;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إظهار المنتج للمستخدمين',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'إذا كان معطلاً، لن يظهر المنتج في التطبيق',
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
                ],
              ),
              const SizedBox(height: 16),

              // إدارة الوحدات الموحدة
              ProductFormSection(
                title: 'إدارة الوحدات',
                icon: Icons.layers,
                children: [
                  UnifiedUnitsManager(
                    initialBaseUnit: unitsData?.baseUnit,
                    initialBasePrice: unitsData?.basePrice,
                    initialBaseOfferPrice: unitsData?.baseOfferPrice,
                    initialBaseStock: unitsData?.baseStock,
                    initialBaseHasOffer: unitsData?.baseHasOffer,
                    initialBaseIsActive: unitsData?.baseIsActive, // إضافة معامل منفصل
                    initialAdditionalUnits: unitsData?.additionalUnits,
                    onUnitsChanged: (data) {
                      setState(() {
                        unitsData = data;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // زر الإضافة
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orangeColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Button(
                    onPressed: (isUploading || _isOffline) ? null : saveProduct,
                  buttonContent: isUploading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'جاري الحفظ...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              isEdit ? 'حفظ التعديلات' : 'إضافة المنتج',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                  buttonColor: isUploading
                      ? Colors.grey
                      : AppColors.orangeColor,
                ),
              ),
              const SizedBox(height: 20),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
