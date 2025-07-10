import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import '../../theme/appcolors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../components/search_field.dart';
import 'category_items_screen.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firebase_service.dart';
import '../../models/category_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/products/category_bloc.dart';
import '../../blocs/products/category_event.dart';
import '../../blocs/products/category_state.dart';

class AdminProductsCategoriesScreen extends StatefulWidget {
  const AdminProductsCategoriesScreen({super.key});

  @override
  State<AdminProductsCategoriesScreen> createState() => _AdminProductsCategoriesScreenState();
}

class _AdminProductsCategoriesScreenState extends State<AdminProductsCategoriesScreen> {
  late TextEditingController _categoryNameController;
  static const int _pageLimit = 20;

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController();
    // Fetch categories using BLoC
    Future.microtask(() => context.read<CategoryBloc>().add(const FetchCategories(limit: _pageLimit)));
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryForm({int? editIndex, CategoryModel? editing}) async {
    _categoryNameController.text = editing?.name ?? '';
    Color selectedColor = editing?.color != null
        ? Color(int.parse(editing!.color!.replaceFirst('#', '0xff')))
        : _colorOptions[0];
    File? pickedImage;
    String? initialImageUrl = editing?.imageUrl;
    bool isUploading = false;
    try {
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
                  final photosStatus = await Permission.photos.request();
                  final cameraStatus = await Permission.camera.request();
                  if (photosStatus.isGranted || cameraStatus.isGranted) {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setModalState(() {
                        pickedImage = File(picked.path);
                        initialImageUrl = null;
                      });
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يجب السماح بالوصول للصور لاختيار صورة')),
                      );
                    }
                  }
                }
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(editing != null ? 'تعديل الفئة' : 'إضافة فئة',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _categoryNameController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'اسم الفئة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('صورة الفئة:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: pickImage,
                          child: pickedImage != null
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: FileImage(pickedImage!),
                                )
                              : (initialImageUrl?.isNotEmpty == true
                                  ? CircleAvatar(
                                      radius: 40,
                                      backgroundImage: NetworkImage(initialImageUrl!),
                                    )
                                  : CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AppColors.lightGrayColor3,
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                                    )),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('لون الفئة:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _colorOptions.map((color) {
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedColor = color),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedColor == color ? AppColors.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: color,
                                  radius: 18,
                                  child: selectedColor == color
                                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isUploading)
                        const Center(child: CircularProgressIndicator()),
                      if (!isUploading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Button(
                            buttonContent: Text(editing != null ? 'حفظ التعديلات' : 'إضافة'),
                            buttonColor: AppColors.primary,
                            onPressed: () async {
                              final name = _categoryNameController.text.trim();
                              if (name.isEmpty) return;
                              setModalState(() => isUploading = true);
                              String? imageUrl = initialImageUrl;
                              if (pickedImage != null) {
                                imageUrl = await CloudinaryService().uploadImage(pickedImage!.path);
                              }
                              setModalState(() => isUploading = false);
                              final now = DateTime.now();
                              final categoryId = editing?.id ?? now.millisecondsSinceEpoch.toString();
                              final categoryModel = CategoryModel(
                                id: categoryId,
                                name: name,
                                imageUrl: imageUrl,
                                color: '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}',
                                isActive: true,
                                createdAt: editing?.createdAt ?? now,
                                updatedAt: now,
                              );
                              if (editing != null) {
                                context.read<CategoryBloc>().add(UpdateCategory(categoryModel));
                              } else {
                                context.read<CategoryBloc>().add(AddCategory(categoryModel));
                              }
                              Navigator.pop(context);
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
    } finally {
      _categoryNameController.clear();
    }
  }

  final List<Color> _colorOptions = [
    AppColors.orangeColor,
    AppColors.primary,
    AppColors.lightBlueColor,
    AppColors.darkBlueColor,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.deepOrange,
    Colors.blueAccent,
    Colors.pinkAccent,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CategoriesLoaded) {
          final categories = state.categories;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                SearchField(
                  hintText: 'ابحث عن الفئات...',
                ),
                const SizedBox(height: 16),
                // Category list
                Expanded(
                  child: categories.isEmpty
                      ? Center(child: Text('لا توجد فئات متاحة حالياً'))
                      : ListView.separated(
                          itemCount: categories.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            Color bgColor = Colors.white;
                            if (category.color != null && category.color!.startsWith('#')) {
                              try {
                                bgColor = Color(int.parse(category.color!.replaceFirst('#', '0xff')));
                              } catch (e) {
                                bgColor = Colors.white;
                              }
                            }
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator()),
                                );
                                final products = await FirebaseService().getProductsForCategory(category.id);
                                Navigator.pop(context); // Remove loading dialog
                                final items = products.map((product) => CategoryItem(
                                  name: product.name,
                                  imageUrl: product.images.isNotEmpty ? product.images.first : null,
                                  price: product.price,
                                  available: product.isActive,
                                  hasOffer: product.isSpecialOffer,
                                  offerPrice: product.originalPrice,
                                )).toList();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryItemsScreen(
                                      categoryName: category.name,
                                      categoryId: category.id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                                          ? NetworkImage(category.imageUrl!)
                                          : null,
                                      child: (category.imageUrl == null || category.imageUrl!.isEmpty)
                                          ? const Icon(Icons.category, size: 32)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  category.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                                    tooltip: 'تعديل',
                                                    onPressed: () => _showCategoryForm(editing: category),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    tooltip: 'حذف',
                                                    onPressed: () {
                                                      context.read<CategoryBloc>().add(DeleteCategory(category.id));
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          FutureBuilder<int>(
                                            future: FirebaseService().getProductCountForCategory(category.id),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                              }
                                              if (snapshot.hasError) {
                                                return const Text('-', style: TextStyle(color: Colors.red, fontSize: 13));
                                              }
                                              return Text(
                                                '${snapshot.data ?? 0} منتج',
                                                style: TextStyle(fontSize: 13, color: AppColors.blackColor),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Add Category button (full width)
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: Button(
                    buttonContent: const Text('إضافة فئة', style: TextStyle(fontWeight: FontWeight.bold)),
                    buttonColor: AppColors.primary,
                    onPressed: () => _showCategoryForm(),
                  ),
                ),
                if (state.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<CategoryBloc>().add(FetchCategories(
                          limit: _pageLimit,
                          lastCategory: categories.isNotEmpty ? categories.last : null,
                        ));
                      },
                      child: const Text('تحميل المزيد'),
                    ),
                  ),
              ],
            ),
          );
        } else if (state is CategoriesError) {
          return Center(child: Text('خطأ: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }
} 