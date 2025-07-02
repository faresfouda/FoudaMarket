import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';

class AdminProductsCategoriesScreen extends StatelessWidget {
  final List<_Category> categories = const [
    _Category(
      name: 'الفواكه والخضروات',
      productCount: 45,
      color: Color(0xFFEFF6EC),
      icon: Icons.apple,
      iconColor: Color(0xFF4CAF50),
    ),
    _Category(
      name: 'المخبوزات والألبان',
      productCount: 28,
      color: Color(0xFFFFF6E5),
      icon: Icons.bakery_dining,
      iconColor: Color(0xFFFFB300),
    ),
    _Category(
      name: 'اللحوم والمأكولات البحرية',
      productCount: 32,
      color: Color(0xFFE5F2FF),
      icon: Icons.set_meal,
      iconColor: Color(0xFF2196F3),
    ),
    _Category(
      name: 'المشروبات',
      productCount: 19,
      color: Color(0xFFF3EFFF),
      icon: Icons.local_drink,
      iconColor: Color(0xFF9C27B0),
    ),
    _Category(
      name: 'الوجبات الخفيفة والحلويات',
      productCount: 36,
      color: Color(0xFFFFF9E5),
      icon: Icons.cookie,
      iconColor: Color(0xFFFFC107),
    ),
  ];

  AdminProductsCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header row with Add button
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الفئات',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('إضافة فئة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightGrayColor3),
            ),
            child: const TextField(
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن الفئات...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
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
                      child: Icon(category.icon, color: category.iconColor),
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
                          onPressed: () {},
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
        ],
      ),
    );
  }
}

class _Category {
  final String name;
  final int productCount;
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _Category({
    required this.name,
    required this.productCount,
    required this.color,
    required this.icon,
    required this.iconColor,
  });
} 