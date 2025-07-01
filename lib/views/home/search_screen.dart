import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fodamarket/components/item_container.dart';
import 'package:fodamarket/views/home/search_filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedBrand;

  final List<Map<String, String>> _products = [
    {
      'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
      'productName': 'Egg Chicken Red',
      'quantityInfo': '4pcs, Price',
      'price': '100L.E',
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
      'productName': 'Egg Chicken White',
      'quantityInfo': '180g, Price',
      'price': '100L.E',
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=400&q=80',
      'productName': 'Egg Pasta',
      'quantityInfo': '30gm, Price',
      'price': '100L.E',
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80',
      'productName': 'Egg Noodles',
      'quantityInfo': '2L, Price',
      'price': '100L.E',
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
      'productName': 'Mayonnais Eggless',
      'quantityInfo': '500g, Price',
      'price': '100L.E',
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80',
      'productName': 'Egg Noodles',
      'quantityInfo': '1L, Price',
      'price': '100L.E',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((product) {
      final matchesQuery = product['productName']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || product['productName']!.toLowerCase().contains(_selectedCategory!.toLowerCase());
      final matchesBrand = _selectedBrand == null || product['productName']!.toLowerCase().contains(_selectedBrand!.toLowerCase());
      return matchesQuery && matchesCategory && matchesBrand;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(onPressed: () {
                    Navigator.pop(context);
                  }, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black,)),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          SvgPicture.asset(
                            'assets/home/search.svg',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Egg',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.black),
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SearchFilterSheet(
                            selectedCategory: _selectedCategory,
                            selectedBrand: _selectedBrand,
                            onApply: (category, brand) {
                              setState(() {
                                _selectedCategory = category;
                                _selectedBrand = brand;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductCard(
                      imageUrl: product['imageUrl']!,
                      productName: product['productName']!,
                      quantityInfo: product['quantityInfo']!,
                      price: product['price']!,
                      onAddPressed: () {},
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 