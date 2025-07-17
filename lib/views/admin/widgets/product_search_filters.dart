import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/appcolors.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_event.dart';

/// واجهة البحث والفلترة للمنتجات في شاشة الأدمن
/// البحث شامل للمنتجات المتوفرة وغير المتوفرة
/// الفلترة تسمح باختيار: الكل، متوفر، غير متوفر

enum ItemAvailabilityFilter { all, available, unavailable }

class ProductSearchFilters extends StatelessWidget {
  final String searchQuery;
  final ItemAvailabilityFilter selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ItemAvailabilityFilter> onFilterChanged;
  final String categoryId;

  const ProductSearchFilters({
    Key? key,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        TextField(
          onChanged: (value) {
            onSearchChanged(value);
            // إرسال حدث البحث الشامل إلى BLoC (يشمل المتوفر وغير المتوفر)
            if (value.trim().isNotEmpty) {
              // استخدام BlocProvider.of بدلاً من context.read لتجنب مشاكل السياق
              final bloc = BlocProvider.of<ProductBloc>(context, listen: false);
              bloc.add(SearchAllProductsInCategory(categoryId, value.trim()));
            } else {
              // إذا كان البحث فارغ، ارجع للقائمة العادية
              final bloc = BlocProvider.of<ProductBloc>(context, listen: false);
              bloc.add(
                FetchProducts(categoryId, limit: ProductBloc.defaultLimit),
              );
            }
          },
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'الكل',
                isSelected: selectedFilter == ItemAvailabilityFilter.all,
                onSelected: (_) => onFilterChanged(ItemAvailabilityFilter.all),
                selectedColor: AppColors.orangeColor,
              ),
              _buildFilterChip(
                label: 'متوفر',
                isSelected: selectedFilter == ItemAvailabilityFilter.available,
                onSelected: (_) =>
                    onFilterChanged(ItemAvailabilityFilter.available),
                selectedColor: Colors.green,
              ),
              _buildFilterChip(
                label: 'غير متوفر',
                isSelected:
                    selectedFilter == ItemAvailabilityFilter.unavailable,
                onSelected: (_) =>
                    onFilterChanged(ItemAvailabilityFilter.unavailable),
                selectedColor: Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    required Color selectedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: selectedColor,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : selectedColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
