import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../theme/appcolors.dart';
import '../../../components/Button.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/image_compression_service.dart';
import '../../../models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_event.dart';
import '../../../components/cached_image.dart';
import '../../../components/connection_aware_widget.dart';

class ProductEditBottomSheet extends StatefulWidget {
  final ProductModel product;
  final BuildContext parentContext;

  const ProductEditBottomSheet({
    super.key,
    required this.product,
    required this.parentContext,
  });

  @override
  State<ProductEditBottomSheet> createState() => _ProductEditBottomSheetState();
}

class _ProductEditBottomSheetState extends State<ProductEditBottomSheet> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController offerPriceController;
  File? pickedImage;
  String? imageUrl;
  bool available = true;
  bool hasOffer = false;
  String? offerError;
  bool isUploading = false;
  bool _isOffline = false; // جديد

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    offerPriceController = TextEditingController(
      text: widget.product.originalPrice?.toString() ?? '',
    );
    available = widget.product.isVisible;
    hasOffer = widget.product.isSpecialOffer;
    imageUrl = (widget.product.images.isNotEmpty)
        ? widget.product.images.first
        : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    offerPriceController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (picked != null) {
      final compressed = await ImageCompressionService().compressImageFile(
        File(picked.path),
      );
      setState(() {
        pickedImage = compressed ?? File(picked.path);
        imageUrl = null;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveProduct() async {
    try {
      if (isUploading) return;

      final name = nameController.text.trim();
      final price = double.tryParse(priceController.text.trim());

      if (price == null || price <= 0) {
        _showError('يرجى إدخال سعر صحيح');
        return;
      }

      double? offerPrice;
      if (hasOffer) {
        offerPrice = double.tryParse(offerPriceController.text.trim());
        if (offerPrice == null || offerPrice <= 0) {
          _showError('يرجى إدخال سعر عرض صحيح');
          return;
        }
      }

      if (name.isEmpty) {
        _showError('يرجى إدخال اسم المنتج');
        return;
      }

      if (pickedImage == null && (imageUrl == null || imageUrl!.isEmpty)) {
        _showError('يرجى اختيار صورة للمنتج');
        return;
      }

      if (hasOffer && offerPrice! >= price) {
        setState(
          () => offerError = 'سعر العرض يجب أن يكون أقل من السعر الأصلي',
        );
        _showError('سعر العرض يجب أن يكون أقل من السعر الأصلي');
        return;
      }

      if (!mounted) return;
      setState(() => isUploading = true);

      String? uploadedImageUrl = imageUrl;
      if (pickedImage != null) {
        uploadedImageUrl = await CloudinaryService().uploadImage(
          pickedImage!.path,
        );
        if (!mounted) return;
        if (uploadedImageUrl == null) {
          setState(() => isUploading = false);
          _showError('فشل رفع الصورة!');
          return;
        }
      }

      if (!mounted) return;
      setState(() => isUploading = false);

      if (uploadedImageUrl == null) {
        _showError('الصورة غير موجودة!');
        return;
      }

      // تحديث المنتج الموجود
      final updatedProduct = widget.product.copyWith(
        name: name,
        images: uploadedImageUrl != null
            ? [uploadedImageUrl]
            : widget.product.images,
        price: price,
        originalPrice: hasOffer ? offerPrice : null,
        isSpecialOffer: hasOffer,
        isVisible: available,
        updatedAt: DateTime.now(),
      );

      widget.parentContext.read<ProductBloc>().add(
        UpdateProduct(updatedProduct),
      );

      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث المنتج بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => isUploading = false);
      print('Error in edit product: $e');
      print(st);
      _showError('حدث خطأ أثناء تحديث المنتج: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionAwareWidget(
      onConnectionChanged: (offline) {
        if (_isOffline != offline) {
          setState(() {
            _isOffline = offline;
          });
        }
      },
      child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تعديل المنتج',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),

            // اسم المنتج
            TextField(
              controller: nameController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // السعر
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'السعر',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // عرض خاص
            Row(
              children: [
                Switch(
                  value: hasOffer,
                  onChanged: (val) => setState(() {
                    hasOffer = val;
                    if (!hasOffer) offerPriceController.text = '';
                  }),
                ),
                const Text('هل يوجد عرض على هذا المنتج؟'),
              ],
            ),

            if (hasOffer) ...[
              const SizedBox(height: 8),
              TextField(
                controller: offerPriceController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'سعر العرض',
                  border: const OutlineInputBorder(),
                  errorText: offerError,
                ),
                onChanged: (_) => setState(() => offerError = null),
              ),
            ],
            const SizedBox(height: 16),

            // صورة المنتج
            Text('صورة المنتج:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          pickedImage!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (imageUrl != null && imageUrl!.isNotEmpty
                          ? CachedImage(
                              imageUrl: imageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 32,
                              ),
                            )),
              ),
            ),
            const SizedBox(height: 16),

            // حالة التوفر
            Row(
              children: [
                Switch(
                  value: available,
                  onChanged: (val) => setState(() => available = val),
                ),
                Text(
                  available ? 'متوفر' : 'غير متوفر',
                  style: TextStyle(
                    color: available ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // زر الحفظ
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Button(
                buttonContent: isUploading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'جاري الحفظ...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(color: Colors.white),
                      ),
                buttonColor: isUploading ? Colors.grey : AppColors.orangeColor,
                  onPressed: (isUploading || _isOffline) ? null : _saveProduct,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ),
        ),
      ),
    );
  }
}
