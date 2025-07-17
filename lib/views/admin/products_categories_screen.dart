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
import '../../services/firebase_service.dart';
import '../../services/image_compression_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';
import 'category_items_screen.dart';
// import 'widgets/category_form_bottom_sheet.dart';

class ProductsCategoriesScreen extends StatefulWidget {
  const ProductsCategoriesScreen({super.key});

  @override
  State<ProductsCategoriesScreen> createState() =>
      _ProductsCategoriesScreenState();
}

class _ProductsCategoriesScreenState
    extends State<ProductsCategoriesScreen> {
  late TextEditingController _categoryNameController;
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  Timer? _debounceTimer;
  bool _isLoadingMore = false;
  File? _pickedImage;
  Color? _pickedColor;
  bool isUploading = false; // مؤشر التحميل

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Fetch categories using BLoC
    Future.microtask(
      () => context.read<CategoryBloc>().add(
        const FetchCategories(limit: CategoryBloc.defaultLimit),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _categoryNameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200 && !_isLoadingMore) {
      final bloc = context.read<CategoryBloc>();
      final state = bloc.state;
      if (state is CategoriesLoaded && state.hasMore) {
        _isLoadingMore = true;
        bloc.add(
          LoadMoreCategories(
            limit: CategoryBloc.defaultLimit,
            lastCategory: state.categories.isNotEmpty
                ? state.categories.last
                : null,
          ),
        );
      }
    }
  }

  void _onLoadMoreFinished() {
    _isLoadingMore = false;
  }

  void _onSearchChanged(String value) {
    // إلغاء البحث السابق
    _debounceTimer?.cancel();

    // تأخير البحث لمدة 500 مللي ثانية لتجنب البحث المتكرر
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        context.read<CategoryBloc>().add(SearchCategories(value.trim()));
      } else {
        context.read<CategoryBloc>().add(const ClearSearch());
      }
    });
  }

  Future<void> _showCategoryForm({CategoryModel? editing}) async {
    _categoryNameController.text = editing?.name ?? '';
    _pickedImage = null;
    _pickedColor = null;
    String? imageUrl = editing?.imageUrl;
    Color? initialColor;
    if (editing != null && editing.color != null && editing.color!.isNotEmpty) {
      try {
        initialColor = Color(int.parse(editing.color!.replaceFirst('#', '0xff')));
      } catch (_) {}
    }
    _pickedColor = initialColor ?? Colors.orange; // لون افتراضي

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 24),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Text(
                  editing != null ? 'تعديل الفئة' : 'إضافة فئة جديدة',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _categoryNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة *',
                    border: OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
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
                            child: Image.file(_pickedImage!, width: 120, height: 120, fit: BoxFit.cover),
                          )
                        : (imageUrl != null && imageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(imageUrl!, width: 120, height: 120, fit: BoxFit.cover),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                                child: const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('لون الفئة *:'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        Color pickerColor = _pickedColor ?? Colors.orange;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('اختر لون الفئة'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: pickerColor,
                                onColorChanged: (color) {
                                  pickerColor = color;
                                },
                                enableAlpha: false,
                                showLabel: false,
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.close, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text('إلغاء', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text('اختيار', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: pickerColor, // لون الزر نفس اللون المختار
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _pickedColor = pickerColor;
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _pickedColor ?? Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: Icon(editing != null ? Icons.save : Icons.add),
                    label: isUploading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(editing != null ? 'تحديث الفئة' : 'إضافة الفئة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isUploading ? null : () async {
                      final name = _categoryNameController.text.trim();
                      final color = _pickedColor;
                      final image = _pickedImage;
                      final isEdit = editing != null;
                      if (name.isEmpty || (image == null && (imageUrl == null || imageUrl?.isEmpty == true)) || color == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جميع الحقول مطلوبة: الاسم، الصورة، اللون')),
                        );
                        return;
                      }
                      setState(() => isUploading = true);
                      String? uploadedImageUrl = imageUrl;
                      File? compressedImage = image;
                      if (image != null) {
                        compressedImage = await ImageCompressionService().compressImageSmart(image);
                        if (compressedImage == null) {
                          setState(() => isUploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('فشل في ضغط الصورة!')),
                          );
                          return;
                        }
                        uploadedImageUrl = await CloudinaryService().uploadImage(compressedImage.path);
                        if (uploadedImageUrl == null) {
                          setState(() => isUploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('فشل رفع الصورة!')),
                          );
                          return;
                        }
                      }
                      final hexColor = '#${color.value.toRadixString(16).substring(2)}';
                      final category = CategoryModel(
                        id: isEdit ? editing!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        color: hexColor,
                        imageUrl: uploadedImageUrl,
                        createdAt: isEdit ? editing!.createdAt : DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      if (isEdit) {
                        context.read<CategoryBloc>().add(UpdateCategory(category));
                      } else {
                        context.read<CategoryBloc>().add(AddCategory(category));
                      }
                      setState(() => isUploading = false);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'تم تحديث الفئة بنجاح' : 'تمت إضافة الفئة بنجاح'), backgroundColor: Colors.green),
                      );
                      _categoryNameController.clear();
                      _pickedImage = null;
                      _pickedColor = null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الفئات'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar - خارج BlocBuilder لتجنب إعادة البناء
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن الفئات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Content area - فقط هذا الجزء يتم إعادة بنائه
            Expanded(
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoriesLoading ||
                      state is CategoriesSearching) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('جاري التحميل...'),
                        ],
                      ),
                    );
                  } else if (state is CategoriesLoaded ||
                      state is CategoriesSearchLoaded) {
                    final categories = state is CategoriesLoaded
                        ? state.categories
                        : (state as CategoriesSearchLoaded).categories;

                    if (categories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              state is CategoriesSearchLoaded
                                  ? Icons.search_off
                                  : Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state is CategoriesSearchLoaded
                                  ? 'لا توجد نتائج للبحث'
                                  : 'لا توجد فئات متاحة',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (state is CategoriesSearchLoaded) ...[
                              const SizedBox(height: 8),
                              Text(
                                'جرب البحث بكلمات مختلفة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    if (_isLoadingMore &&
                        (state is CategoriesLoaded ||
                            state is CategoriesSearchLoaded)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _isLoadingMore = false;
                        });
                      });
                    }

                    return Stack(
                      children: [
                        ListView.separated(
                          controller: _scrollController,
                          itemCount: categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            Color bgColor = Colors.white;
                            if (category.color != null &&
                                category.color!.startsWith('#')) {
                              try {
                                bgColor = Color(
                                  int.parse(
                                    category.color!.replaceFirst('#', '0xff'),
                                  ),
                                );
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
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                                final products = await FirebaseService()
                                    .getProductsForCategory(category.id);
                                Navigator.pop(context);
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
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
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
                                      backgroundImage:
                                          (category.imageUrl != null &&
                                              category.imageUrl!.isNotEmpty)
                                          ? NetworkImage(category.imageUrl!)
                                          : null,
                                      child:
                                          (category.imageUrl == null ||
                                              category.imageUrl!.isEmpty)
                                          ? const Icon(Icons.category, size: 32)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip: 'تعديل',
                                                    onPressed: () =>
                                                        _showCategoryForm(
                                                          editing: category,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'حذف',
                                                    onPressed: () async {
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
                                                                Text('⚠️ حذف الفئة سيؤدي إلى حذف جميع المنتجات المرتبطة بها!'),
                                                                const SizedBox(height: 12),
                                                                Text('للتأكيد، اكتب اسم الفئة بالضبط:'),
                                                                const SizedBox(height: 8),
                                                                TextField(
                                                                  controller: controller,
                                                                  decoration: InputDecoration(
                                                                    border: OutlineInputBorder(),
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
                                                        context.read<CategoryBloc>().add(
                                                          DeleteCategory(category.id),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          FutureBuilder<int>(
                                            future: FirebaseService()
                                                .getAllProductCountForCategory(
                                                  category.id,
                                                ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                );
                                              }
                                              if (snapshot.hasError) {
                                                return const Text(
                                                  '-',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 13,
                                                  ),
                                                );
                                              }
                                              return Text(
                                                '${snapshot.data ?? 0} منتج',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.blackColor,
                                                ),
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
                        if (_isLoadingMore)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  } else if (state is CategoriesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ في تحميل الفئات',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CategoryBloc>().add(
                                const FetchCategories(
                                  limit: CategoryBloc.defaultLimit,
                                ),
                              );
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            // Add Category button (full width) - خارج BlocBuilder
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 70,
              child: Button(
                buttonContent: const Text(
                  'إضافة فئة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
