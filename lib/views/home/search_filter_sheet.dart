import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/category/category_state.dart';

class SearchFilterSheet extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedBrand;
  final Function(List<String> categories, double minPrice, double maxPrice) onApply;

  const SearchFilterSheet({
    super.key,
    this.selectedCategory,
    this.selectedBrand,
    required this.onApply,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  String? selectedCategory;
  String? selectedBrand;
  List<String> selectedCategories = [];
  double minPrice = 0;
  double maxPrice = 1000;
  RangeValues priceRange = const RangeValues(0, 1000);

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null) {
      selectedCategories = [widget.selectedCategory!];
    }
    // يمكن لاحقاً تمرير قيم السعر من الخارج
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F6F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'فلترة المنتجات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 48), // For symmetry
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الفئة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, state) {
                        if (state is CategoriesLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is CategoriesLoaded && state.categories.isNotEmpty) {
                          return Column(
                            children: state.categories.map((cat) => CheckboxListTile(
                              value: selectedCategories.contains(cat.id),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    selectedCategories.add(cat.id);
                                  } else {
                                    selectedCategories.remove(cat.id);
                                  }
                                });
                              },
                              title: Text(
                                cat.name,
                                style: TextStyle(
                                  color: selectedCategories.contains(cat.id) ? AppColors.orangeColor : Colors.black,
                                  fontWeight: selectedCategories.contains(cat.id) ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              activeColor: AppColors.orangeColor,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            )).toList(),
                          );
                        } else if (state is CategoriesError) {
                          return Text('فشل تحميل الفئات', style: TextStyle(color: Colors.red));
                        } else {
                          return Text('لا توجد فئات متاحة');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'السعر',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: priceRange,
                      min: 0,
                      max: 1000,
                      divisions: 100,
                      labels: RangeLabels(
                        priceRange.start.round().toString(),
                        priceRange.end.round().toString(),
                      ),
                      onChanged: (values) {
                        setState(() {
                          priceRange = values;
                        });
                      },
                      activeColor: AppColors.orangeColor,
                      inactiveColor: Colors.grey[300],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'من ${priceRange.start.round()} ج.م',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'إلى ${priceRange.end.round()} ج.م',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    // يمكن إضافة فلتر الماركة لاحقاً عند توفر البيانات
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onApply(selectedCategories, priceRange.start, priceRange.end);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'تطبيق الفلتر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
} 