import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/category_model.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/category/category_event.dart';
import '../../blocs/category/category_state.dart';
import '../../blocs/auth/index.dart';
import '../../services/cloudinary_service.dart';
import '../../services/image_compression_service.dart';
import 'category_items_screen.dart';

class ProductsCategoriesScreen extends StatefulWidget {
  const ProductsCategoriesScreen({super.key});

  @override
  State<ProductsCategoriesScreen> createState() => _ProductsCategoriesScreenState();
}

class _ProductsCategoriesScreenState extends State<ProductsCategoriesScreen> {
  final TextEditingController _categoryNameController = TextEditingController();
  File? _pickedImage;
  Color _pickedColor = Colors.orange;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const FetchCategories());
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoriesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoriesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('خطأ: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CategoryBloc>().add(const FetchCategories());
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (state is CategoriesLoaded) {
              return Column(
                children: [
                  // Header with add button
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.category, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'الفئات المتاحة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditCategoryDialog(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'إضافة فئة',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Categories list
                  Expanded(
                    child: state.categories.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'لا توجد فئات مضافة بعد',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.categories.length,
                            itemBuilder: (context, index) {
                              final category = state.categories[index];
                              return _buildCategoryCard(category);
                            },
                          ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        // Navigate to category items screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryItemsScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                    ? Image.network(
                        category.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.category, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.category, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),
              // Category details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (category.color != null && category.color!.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _parseColor(category.color!),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'لون الفئة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'تعديل',
                    onPressed: () => _showAddEditCategoryDialog(editing: category),
                  ),
                  // Delete button - only for admin
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated &&
                          authState.userProfile != null &&
                          authState.userProfile!.role == 'admin') {
                        return IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'حذف',
                          onPressed: () => _showDeleteDialog(category),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.orange;
    }
  }

  Future<void> _showAddEditCategoryDialog({CategoryModel? editing}) async {
    _categoryNameController.clear();
    _pickedImage = null;
    String? imageUrl;

    if (editing != null) {
      _categoryNameController.text = editing.name;
      imageUrl = editing.imageUrl;

      if (editing.color != null && editing.color!.isNotEmpty) {
        _pickedColor = _parseColor(editing.color!);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Text(
                  editing != null ? 'تعديل الفئة' : 'إضافة فئة جديدة',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Category name field
                TextField(
                  controller: _categoryNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() {
                        _pickedImage = File(picked.path);
                        imageUrl = null;
                      });
                    }
                  },
                  child: Center(
                    child: _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _pickedImage!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (imageUrl != null && imageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                // Color picker
                Row(
                  children: [
                    const Text('لون الفئة *:'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await _showColorPicker(setState);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _pickedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _saveCategory(editing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(editing != null ? 'تحديث' : 'إضافة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPicker(StateSetter setState) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر لون الفئة'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _pickedColor,
            onColorChanged: (color) {
              setState(() {
                _pickedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory(CategoryModel? editing) async {
    if (_categoryNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفئة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final colorString = '#${_pickedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      String? uploadedImageUrl;

      // رفع الصورة إذا تم اختيار صورة جديدة
      if (_pickedImage != null) {
        try {
          uploadedImageUrl = await _uploadCategoryImage(_pickedImage!);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في رفع الصورة: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (editing != null) {
        // Update existing category
        final updatedCategory = CategoryModel(
          id: editing.id,
          name: _categoryNameController.text.trim(),
          imageUrl: uploadedImageUrl ?? editing.imageUrl, // استخدام الصورة الجديدة أو الموجودة
          color: colorString,
          createdAt: editing.createdAt,
          updatedAt: DateTime.now(),
        );

        context.read<CategoryBloc>().add(UpdateCategory(updatedCategory));
      } else {
        // Add new category
        final newCategory = CategoryModel(
          id: '', // Will be generated by Firebase
          name: _categoryNameController.text.trim(),
          imageUrl: uploadedImageUrl, // استخدام الصورة المرفوعة
          color: colorString,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        context.read<CategoryBloc>().add(AddCategory(newCategory));
      }

      Navigator.pop(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadCategoryImage(File imageFile) async {
    try {
      // ضغط الصورة أولاً قبل الرفع (كما في رفع صور المنتجات)
      final ImageCompressionService compressionService = ImageCompressionService();
      final compressedImage = await compressionService.compressImageFile(imageFile);

      // استخدام الصورة المضغوطة أو الأصلية في حالة فشل الضغط
      final imageToUpload = compressedImage ?? imageFile;

      // رفع الصورة إلى Cloudinary
      final CloudinaryService cloudinaryService = CloudinaryService();
      final imageUrl = await cloudinaryService.uploadImage(imageToUpload.path);

      if (imageUrl == null) {
        throw Exception('فشل في رفع الصورة إلى الخدمة');
      }

      return imageUrl;
    } catch (e) {
      print('Error uploading category image: $e');
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  Future<void> _showDeleteDialog(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('تأكيد حذف الفئة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️ حذف الفئة سيؤدي إلى حذف جميع المنتجات المرتبطة بها!'),
              const SizedBox(height: 12),
              const Text('للتأكيد، اكتب اسم الفئة بالضبط:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: category.name,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد الحذف'),
              onPressed: () {
                if (controller.text.trim() == category.name.trim()) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يجب كتابة اسم الفئة بشكل مطابق للتأكيد!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      context.read<CategoryBloc>().add(DeleteCategory(category.id));
    }
  }
}
