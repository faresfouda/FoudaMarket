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
                imageUrl: 'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
                productName: 'Organic Bananas',
                quantityInfo: '7pcs, Priceg', // consider correcting to '7pcs, Price'
                price: '\$4.99',
                onAddPressed: () => print('Organic Bananas added to cart!'),
              );
            },
          ),
        ),
    );
  }
}
