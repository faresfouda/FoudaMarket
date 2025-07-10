import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';
import '../../services/cloudinary_service.dart';
import '../../models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/products/product_bloc.dart';
import '../../blocs/products/product_event.dart';

class AddProductScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final ProductModel? editing;
  
  const AddProductScreen({
    Key? key, 
    required this.categoryId, 
    required this.categoryName,
    this.editing,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController offerPriceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController stockQuantityController = TextEditingController();
  
  File? pickedImage;
  bool isUploading = false;
  bool hasOffer = false;
  bool isAvailable = true;
  String? offerError;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      final p = widget.editing!;
      nameController.text = p.name;
      priceController.text = p.price.toString();
      offerPriceController.text = p.originalPrice?.toString() ?? '';
      descriptionController.text = p.description ?? '';
      unitController.text = p.unit;
      stockQuantityController.text = p.stockQuantity.toString();
      hasOffer = p.isSpecialOffer;
      isAvailable = p.isActive;
      imageUrl = (p.images.isNotEmpty) ? p.images.first : null;
    } else {
      unitController.text = 'قطعة';
      stockQuantityController.text = '0';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    offerPriceController.dispose();
    descriptionController.dispose();
    unitController.dispose();
    stockQuantityController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (mounted && picked != null) {
      setState(() {
        pickedImage = File(picked.path);
        imageUrl = null;
      });
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> saveProduct() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showValidationError('يرجى إدخال اسم المنتج');
      return;
    }
    final price = double.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      _showValidationError('يرجى إدخال سعر صحيح');
      return;
    }
    double? offerPrice;
    if (hasOffer) {
      offerPrice = double.tryParse(offerPriceController.text.trim());
      if (offerPrice == null || offerPrice <= 0) {
        _showValidationError('يرجى إدخال سعر عرض صحيح');
        return;
      }
      if (offerPrice >= price) {
        _showValidationError('سعر العرض يجب أن يكون أقل من السعر الأصلي');
        return;
      }
    }
    final stockQuantity = int.tryParse(stockQuantityController.text.trim()) ?? 0;
    final unit = unitController.text.trim();
    final description = descriptionController.text.trim();
    setState(() { isUploading = true; });
    try {
      String? uploadedImageUrl = imageUrl;
      if (pickedImage != null) {
        uploadedImageUrl = await CloudinaryService().uploadImage(pickedImage!.path);
        if (uploadedImageUrl == null) {
          setState(() { isUploading = false; });
          _showValidationError('فشل رفع الصورة');
          return;
        }
      }
      final now = DateTime.now();
      if (widget.editing != null) {
        // تعديل منتج
        final updatedProduct = widget.editing!.copyWith(
          name: name,
          images: uploadedImageUrl != null ? [uploadedImageUrl] : widget.editing!.images,
          price: price,
          originalPrice: hasOffer ? offerPrice : null,
          unit: unit,
          description: description.isNotEmpty ? description : null,
          isSpecialOffer: hasOffer,
          isActive: isAvailable,
          stockQuantity: stockQuantity,
          updatedAt: now,
        );
        context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
        setState(() { isUploading = false; });
        _showSuccessMessage('تم حفظ التعديلات بنجاح');
        if (mounted) Navigator.pop(context);
      } else {
        // إضافة منتج جديد
        if (uploadedImageUrl == null) {
          setState(() { isUploading = false; });
          _showValidationError('يرجى اختيار صورة للمنتج');
          return;
        }
        final productId = now.millisecondsSinceEpoch.toString();
        final product = ProductModel(
          id: productId,
          name: name,
          description: description.isNotEmpty ? description : null,
          images: [uploadedImageUrl],
          price: price,
          originalPrice: hasOffer ? offerPrice : null,
          unit: unit,
          categoryId: widget.categoryId,
          isSpecialOffer: hasOffer,
          isActive: isAvailable,
          stockQuantity: stockQuantity,
          createdAt: now,
          updatedAt: now,
        );
        context.read<ProductBloc>().add(AddProduct(product));
        setState(() { isUploading = false; });
        _showSuccessMessage('تم إضافة المنتج بنجاح');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() { isUploading = false; });
      _showValidationError('حدث خطأ أثناء حفظ المنتج: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEdit ? 'تعديل منتج - ${widget.categoryName}' : 'إضافة منتج - ${widget.categoryName}',
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.orangeColor),
                      const SizedBox(width: 8),
                      Text(
                        'معلومات المنتج',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // اسم المنتج
                  TextField(
                    controller: nameController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'اسم المنتج *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.inventory),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // السعر
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'السعر *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'ج.م',
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الوصف
                  TextField(
                    controller: descriptionController,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'وصف المنتج',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // تفاصيل إضافية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: AppColors.orangeColor),
                      const SizedBox(width: 8),
                      Text(
                        'تفاصيل إضافية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // الوحدة
                  TextField(
                    controller: unitController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'الوحدة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.category),
                      hintText: 'مثال: قطعة، كيلو، لتر',
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الكمية المتوفرة
                  TextField(
                    controller: stockQuantityController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'الكمية المتوفرة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.inventory_2),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // عرض خاص
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer, color: AppColors.orangeColor),
                      const SizedBox(width: 8),
                      Text(
                        'عرض خاص',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Switch(
                          value: hasOffer,
                          onChanged: (val) {
                            setState(() {
                              hasOffer = val;
                              if (!hasOffer) {
                                offerPriceController.clear();
                                offerError = null;
                              }
                            });
                          },
                          activeColor: AppColors.orangeColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تفعيل عرض خاص على هذا المنتج',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (hasOffer) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: offerPriceController,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: 'سعر العرض *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.local_offer),
                        suffixText: 'ج.م',
                        errorText: offerError,
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (_) {
                        if (offerError != null) {
                          setState(() {
                            offerError = null;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // صورة المنتج
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: AppColors.orangeColor),
                      const SizedBox(width: 8),
                      Text(
                        'صورة المنتج *',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  pickedImage!,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (imageUrl != null && imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      imageUrl!,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 48)),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(child: CircularProgressIndicator());
                                      },
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 48,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'اضغط لاختيار صورة',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // حالة التوفر
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.orangeColor),
                      const SizedBox(width: 8),
                      Text(
                        'حالة التوفر',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAvailable ? Colors.green[200]! : Colors.red[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Switch(
                          value: isAvailable,
                          onChanged: (val) {
                            setState(() {
                              isAvailable = val;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          isAvailable ? Icons.check_circle : Icons.cancel,
                          color: isAvailable ? Colors.green : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isAvailable ? 'متوفر للطلب' : 'غير متوفر',
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
  onPressed: isUploading ? () {} : saveProduct,
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
  buttonColor: isUploading ? Colors.grey : AppColors.orangeColor,
),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} 