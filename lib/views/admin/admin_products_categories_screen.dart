import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import '../../theme/appcolors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../components/search_field.dart';

class AdminProductsCategoriesScreen extends StatefulWidget {
  const AdminProductsCategoriesScreen({super.key});

  @override
  State<AdminProductsCategoriesScreen> createState() => _AdminProductsCategoriesScreenState();
}

class _Category {
  final String name;
  final int productCount;
  final Color color;
  final String? imageUrl;
  final File? imageFile;

  const _Category({
    required this.name,
    required this.productCount,
    required this.color,
    this.imageUrl,
    this.imageFile,
  });

  _Category copyWith({String? name, int? productCount, Color? color, String? imageUrl, File? imageFile}) {
    return _Category(
      name: name ?? this.name,
      productCount: productCount ?? this.productCount,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFile: imageFile ?? this.imageFile,
    );
  }
}

class _AdminProductsCategoriesScreenState extends State<AdminProductsCategoriesScreen> {
  List<_Category> categories = [
    _Category(
      name: 'الفواكه والخضروات',
      productCount: 45,
      color: const Color(0xFFEFF6EC),
      imageUrl: 'https://img.icons8.com/color/48/000000/apple.png',
    ),
    _Category(
      name: 'المخبوزات والألبان',
      productCount: 28,
      color: const Color(0xFFFFF6E5),
      imageUrl: 'https://img.icons8.com/color/48/000000/bread.png',
    ),
    _Category(
      name: 'اللحوم والمأكولات البحرية',
      productCount: 32,
      color: const Color(0xFFE5F2FF),
      imageUrl: 'https://img.icons8.com/color/48/000000/fish-food.png',
    ),
    _Category(
      name: 'المشروبات',
      productCount: 19,
      color: const Color(0xFFF3EFFF),
      imageUrl: 'https://img.icons8.com/color/48/000000/cola.png',
    ),
    _Category(
      name: 'الوجبات الخفيفة والحلويات',
      productCount: 36,
      color: const Color(0xFFFFF9E5),
      imageUrl: 'https://img.icons8.com/color/48/000000/cookie.png',
    ),
  ];

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

  Future<void> _showCategoryForm({int? editIndex}) async {
    final isEdit = editIndex != null;
    final _Category? editing = isEdit ? categories[editIndex!] : null;
    final TextEditingController nameController = TextEditingController(text: editing?.name ?? '');
    Color selectedColor = editing?.color ?? _colorOptions[0];
    File? pickedImage = isEdit ? categories[editIndex!].imageFile : null;
    String? initialImageUrl = isEdit ? categories[editIndex!].imageUrl : null;
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
                      Text(isEdit ? 'تعديل الفئة' : 'إضافة فئة',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Button(
                          buttonContent: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
                          buttonColor: AppColors.primary,
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;
                            setState(() {
                              if (isEdit) {
                                categories[editIndex!] = categories[editIndex!].copyWith(
                                  name: name,
                                  color: selectedColor,
                                  imageFile: pickedImage,
                                  imageUrl: initialImageUrl,
                                );
                              } else {
                                categories.add(_Category(
                                  name: name,
                                  productCount: 0,
                                  color: selectedColor,
                                  imageFile: pickedImage,
                                  imageUrl: initialImageUrl,
                                ));
                              }
                            });
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
      nameController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
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
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 24,
                        child: ClipOval(
                          child: category.imageFile != null
                              ? Image.file(
                                  category.imageFile!,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                )
                              : (category.imageUrl != null
                                  ? Image.network(
                                      category.imageUrl!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text('${category.productCount} منتج'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFFFB300)),
                            onPressed: () => _showCategoryForm(editIndex: index),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {},
                            tooltip: 'حذف',
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
          ],
        ),
      ),
    );
  }
} 