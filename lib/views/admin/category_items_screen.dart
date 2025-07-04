import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';

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

class CategoryItemsScreen extends StatefulWidget {
  final String categoryName;
  final List<CategoryItem> items;
  const CategoryItemsScreen({Key? key, required this.categoryName, required this.items}) : super(key: key);

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  late List<CategoryItem> items;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  ItemAvailabilityFilter selectedFilter = ItemAvailabilityFilter.all;

  @override
  void initState() {
    super.initState();
    items = widget.items.map((e) => CategoryItem(
      name: e.name,
      imageUrl: e.imageUrl,
      imageFile: e.imageFile,
      price: e.price,
      available: e.available,
      hasOffer: e.hasOffer,
      offerPrice: e.offerPrice,
    )).toList();
  }

  List<CategoryItem> get filteredItems {
    List<CategoryItem> filtered = items;
    if (selectedFilter == ItemAvailabilityFilter.available) {
      filtered = filtered.where((item) => item.available).toList();
    } else if (selectedFilter == ItemAvailabilityFilter.unavailable) {
      filtered = filtered.where((item) => !item.available).toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) => item.name.contains(searchQuery)).toList();
    }
    return filtered;
  }

  Future<void> _pickImage(Function(File? file, String? url) onPicked, {String? initialUrl}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      onPicked(File(picked.path), null);
    } else {
      onPicked(null, initialUrl);
    }
  }

  void _showEditBottomSheet({int? editIndex}) async {
    final isEdit = editIndex != null;
    final CategoryItem? editing = isEdit ? items[editIndex!] : null;
    final nameController = TextEditingController(text: editing?.name ?? '');
    final priceController = TextEditingController(text: editing?.price.toString() ?? '');
    File? pickedImage = editing?.imageFile;
    String? imageUrl = editing?.imageUrl;
    bool available = editing?.available ?? true;
    bool hasOffer = editing?.hasOffer ?? false;
    final offerPriceController = TextEditingController(text: editing?.offerPrice?.toString() ?? '');
    String? offerError;
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
                    Text(isEdit ? 'تعديل المنتج' : 'إضافة منتج',
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
                        buttonContent: Text(isEdit ? 'حفظ التعديلات' : 'إضافة', style: const TextStyle(color: Colors.white)),
                        buttonColor: AppColors.orangeColor,
                        onPressed: () {
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                          double? offerPrice = hasOffer ? double.tryParse(offerPriceController.text.trim()) : null;
                          if (name.isEmpty || (pickedImage == null && (imageUrl == null || imageUrl!.isEmpty))) return;
                          if (hasOffer && (offerPrice == null || offerPrice >= price)) {
                            setModalState(() => offerError = 'سعر العرض يجب أن يكون أقل من السعر الأصلي');
                            return;
                          }
                          setState(() {
                            if (isEdit) {
                              items[editIndex!] = CategoryItem(
                                name: name,
                                imageFile: pickedImage,
                                imageUrl: imageUrl,
                                price: price,
                                available: available,
                                hasOffer: hasOffer,
                                offerPrice: hasOffer ? offerPrice : null,
                              );
                            } else {
                              items.add(CategoryItem(
                                name: name,
                                imageFile: pickedImage,
                                imageUrl: imageUrl,
                                price: price,
                                available: available,
                                hasOffer: hasOffer,
                                offerPrice: hasOffer ? offerPrice : null,
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
    nameController.dispose();
    priceController.dispose();
    offerPriceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
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
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final realIndex = items.indexOf(item);
                  return GestureDetector(
                    onTap: () => _showEditBottomSheet(editIndex: realIndex),
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
                              child: item.imageFile != null
                                  ? Image.file(
                                      item.imageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : (item.imageUrl != null && item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 48, color: Colors.grey),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                                        )),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                if (item.hasOffer && item.offerPrice != null) ...[
                                  Row(
                                    children: [
                                      Text('ج.م ${item.price}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          decoration: TextDecoration.lineThrough,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('ج.م ${item.offerPrice}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Text('ج.م ${item.price}', style: const TextStyle(color: Colors.black54)),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      item.available ? Icons.check_circle : Icons.cancel,
                                      color: item.available ? Colors.green : Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(item.available ? 'متوفر' : 'غير متوفر', style: TextStyle(color: item.available ? Colors.green : Colors.red)),
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
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditBottomSheet(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.orangeColor,
      ),
    );
  }
} 