import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firebase_service.dart';
import '../../models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/products/product_bloc.dart';
import '../../blocs/products/product_event.dart';
import '../../blocs/products/product_state.dart';
import 'add_product_screen.dart';

class CategoryItem {
  String name;
  String? imageUrl;
  File? imageFile;
  double price;
  bool available;
  bool hasOffer;
  double? offerPrice;
  CategoryItem({
    required this.name,
    this.imageUrl,
    this.imageFile,
    required this.price,
    this.available = true,
    this.hasOffer = false,
    this.offerPrice,
  });
}

enum ItemAvailabilityFilter { all, available, unavailable }

class CategoryItemsScreen extends StatelessWidget {
  final String categoryName;
  final String categoryId;
  const CategoryItemsScreen({Key? key, required this.categoryName, required this.categoryId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productBloc = ProductBloc()..add(FetchProducts(categoryId));
    return BlocProvider<ProductBloc>(
      create: (_) => productBloc,
      child: _CategoryItemsScreenBody(
        categoryName: categoryName,
        categoryId: categoryId,
        productBloc: productBloc,
      ),
    );
  }
}

class _CategoryItemsScreenBody extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final ProductBloc productBloc;
  const _CategoryItemsScreenBody({Key? key, required this.categoryName, required this.categoryId, required this.productBloc}) : super(key: key);

  @override
  State<_CategoryItemsScreenBody> createState() => _CategoryItemsScreenBodyState();
}

class _CategoryItemsScreenBodyState extends State<_CategoryItemsScreenBody> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  ItemAvailabilityFilter selectedFilter = ItemAvailabilityFilter.all;
  bool isUploading = false;

  void _showEditBottomSheet({required ProductModel editing}) async {
    final nameController = TextEditingController(text: editing.name);
    final priceController = TextEditingController(text: editing.price.toString());
    File? pickedImage = null; // لا نحاول إنشاء File من URL
    String? imageUrl = (editing.images.isNotEmpty) ? editing.images.first : null;
    bool available = editing.isActive;
    bool hasOffer = editing.isSpecialOffer;
    final offerPriceController = TextEditingController(text: editing.originalPrice?.toString() ?? '');
    String? offerError;
    final parentContext = context;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> pickImage() async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                if (picked != null) {
                  setModalState(() {
                    pickedImage = File(picked.path);
                    imageUrl = null;
                  });
                }
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('تعديل المنتج',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    Row(
                      children: [
                        Switch(
                          value: hasOffer,
                          onChanged: (val) => setModalState(() {
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
                        onChanged: (_) => setModalState(() => offerError = null),
                      ),
                    ],
                    const SizedBox(height: 16),
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
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.image, size: 32, color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch(
                          value: available,
                          onChanged: (val) => setModalState(() => available = val),
                        ),
                        Text(available ? 'متوفر' : 'غير متوفر', style: TextStyle(color: available ? Colors.green : Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('جاري الحفظ...', style: TextStyle(color: Colors.white)),
                              ],
                            )
                          : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
                        buttonColor: isUploading ? Colors.grey : AppColors.orangeColor,
                        onPressed: () async {
                          try {
                            if (isUploading) return;
                          final name = nameController.text.trim();
                            final price = double.tryParse(priceController.text.trim());
                            if (price == null || price <= 0) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('يرجى إدخال سعر صحيح'),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            double? offerPrice;
                            if (hasOffer) {
                              offerPrice = double.tryParse(offerPriceController.text.trim());
                              if (offerPrice == null || offerPrice <= 0) {
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('يرجى إدخال سعر عرض صحيح'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('يرجى إدخال اسم المنتج'),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (pickedImage == null && (imageUrl == null || imageUrl!.isEmpty)) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('يرجى اختيار صورة للمنتج'),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (hasOffer && offerPrice! >= price) {
                                if (!mounted) return;
                            setModalState(() => offerError = 'سعر العرض يجب أن يكون أقل من السعر الأصلي');
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('سعر العرض يجب أن يكون أقل من السعر الأصلي'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            if (!mounted) return;
                            setModalState(() => isUploading = true);
                            String? uploadedImageUrl = imageUrl;
                            if (pickedImage != null) {
                              uploadedImageUrl = await CloudinaryService().uploadImage(pickedImage!.path);
                              if (!mounted) return;
                              if (uploadedImageUrl == null) {
                                setModalState(() => isUploading = false);
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('فشل رفع الصورة!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }
                            if (!mounted) return;
                            setModalState(() => isUploading = false);
                            if (uploadedImageUrl == null) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('الصورة غير موجودة!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            return;
                          }
                            // تحديث المنتج الموجود
                            final updatedProduct = editing.copyWith(
                              name: name,
                              images: uploadedImageUrl != null ? [uploadedImageUrl] : editing.images,
                              price: price,
                              originalPrice: hasOffer ? offerPrice : null,
                              isSpecialOffer: hasOffer,
                              isActive: available,
                              updatedAt: DateTime.now(),
                            );
                            parentContext.read<ProductBloc>().add(UpdateProduct(updatedProduct));
                            if (mounted) {
                              FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.pop(context);
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Text('تم تحديث المنتج بنجاح'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e, st) {
                            if (!mounted) return;
                            setModalState(() => isUploading = false);
                            print('Error in add/edit product: $e');
                            print(st);
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('حدث خطأ أثناء تحديث المنتج: $e'),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductsLoaded) {
              return Text('${widget.categoryName} (${state.products.length})');
            }
            return Text(widget.categoryName);
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('الكل'),
                      selected: selectedFilter == ItemAvailabilityFilter.all,
                      onSelected: (_) => setState(() => selectedFilter = ItemAvailabilityFilter.all),
                      selectedColor: AppColors.orangeColor,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: selectedFilter == ItemAvailabilityFilter.all ? Colors.white : AppColors.orangeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('متوفر'),
                      selected: selectedFilter == ItemAvailabilityFilter.available,
                      onSelected: (_) => setState(() => selectedFilter = ItemAvailabilityFilter.available),
                      selectedColor: Colors.green,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: selectedFilter == ItemAvailabilityFilter.available ? Colors.white : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('غير متوفر'),
                      selected: selectedFilter == ItemAvailabilityFilter.unavailable,
                      onSelected: (_) => setState(() => selectedFilter = ItemAvailabilityFilter.unavailable),
                      selectedColor: Colors.red,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: selectedFilter == ItemAvailabilityFilter.unavailable ? Colors.white : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductsLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'جاري تحميل المنتجات...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (state is ProductsLoaded) {
                    final products = state.products;
                    // فلترة حسب البحث والتوفر
                    final filtered = products.where((product) {
                      final matchesSearch = searchQuery.isEmpty || product.name.contains(searchQuery);
                      final matchesFilter = selectedFilter == ItemAvailabilityFilter.all
                        ? true
                        : selectedFilter == ItemAvailabilityFilter.available
                          ? product.isActive
                          : !product.isActive;
                      return matchesSearch && matchesFilter;
                    }).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty 
                                ? 'لا توجد منتجات تطابق البحث'
                                : 'لا توجد منتجات في هذه الفئة',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            if (searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'جرب البحث بكلمات مختلفة',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }
                    
                    return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                      itemCount: filtered.length,
                itemBuilder: (context, index) {
                        final product = filtered[index];
                  return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                  value: widget.productBloc,
                                  child: AddProductScreen(
                                    categoryId: widget.categoryId,
                                    categoryName: widget.categoryName,
                                    editing: product,
                                  ),
                                ),
                              ),
                            );
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: product.images.isNotEmpty
                                      ? Image.network(
                                            product.images.first,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image, size: 48, color: Colors.grey),
                                            ),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                                        )),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (product.isSpecialOffer && product.originalPrice != null) ...[
                                        Row(
                                          children: [
                                            Text('ج.م ${product.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                decoration: TextDecoration.lineThrough,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                                color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                              child: Text('ج.م ${product.originalPrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                        Text('ج.م ${product.price.toStringAsFixed(2)}', 
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          )
                                        ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                            product.isActive ? Icons.check_circle : Icons.cancel,
                                            color: product.isActive ? Colors.green : Colors.red,
                                            size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                          Text(
                                            product.isActive ? 'متوفر' : 'غير متوفر',
                                            style: TextStyle(
                                              color: product.isActive ? Colors.green : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            )
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                      },
                    );
                  } else if (state is ProductsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ أثناء تحميل المنتجات',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ProductBloc>().add(FetchProducts(widget.categoryId));
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: widget.productBloc,
                child: AddProductScreen(
                  categoryId: widget.categoryId,
                  categoryName: widget.categoryName,
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.orangeColor,
      ),
    );
  }
} 