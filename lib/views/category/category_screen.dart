import 'package:flutter/material.dart';

import '../../components/item_container.dart';


class CategoryScreen extends StatelessWidget {
  final String categoryName;
  const CategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.75,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            return ProductCard(
              imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
              productName: 'خيار طازج',
              quantityInfo: '١ كجم',
              originalPrice: '٢٠ ج.م',
              isFavorite: false,
              onFavoritePressed: () {},
              onAddPressed: () {},
            );
          },
        ),
      ),
    );
  }
}
