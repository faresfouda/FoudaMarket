import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';

class SearchFilterSheet extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedBrand;
  final Function(String? category, String? brand) onApply;

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
  final List<String> categories = [
    'Eggs',
    'Noodles & Pasta',
    'Chips & Crisps',
    'Fast Food',
  ];
  final List<String> brands = [
    'Individual Collection',
    'Cocola',
    'Ifad',
    'Kazi Farmas',
  ];

  String? selectedCategory;
  String? selectedBrand;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.selectedCategory;
    selectedBrand = widget.selectedBrand;
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
                  'Filters',
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
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...categories.map((cat) => CheckboxListTile(
                        value: selectedCategory == cat,
                        onChanged: (_) {
                          setState(() {
                            selectedCategory = cat;
                          });
                        },
                        title: Text(
                          cat,
                          style: TextStyle(
                            color: selectedCategory == cat ? AppColors.orangeColor : Colors.black,
                            fontWeight: selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        activeColor: AppColors.orangeColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),
                  const SizedBox(height: 16),
                  const Text(
                    'Brand',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...brands.map((brand) => CheckboxListTile(
                        value: selectedBrand == brand,
                        onChanged: (_) {
                          setState(() {
                            selectedBrand = brand;
                          });
                        },
                        title: Text(
                          brand,
                          style: TextStyle(
                            color: selectedBrand == brand ? AppColors.orangeColor : Colors.black,
                            fontWeight: selectedBrand == brand ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        activeColor: AppColors.orangeColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),
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
                  widget.onApply(selectedCategory, selectedBrand);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Apply Filter',
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
    );
  }
} 