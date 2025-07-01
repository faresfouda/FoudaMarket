import 'package:flutter/material.dart';
import 'package:fodamarket/views/favourite/widgets/product_favourite.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: 10, // Example item count
        itemBuilder: (context, index) {
          return FavoriteItemCard(
            imageUrl: 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?auto=format&fit=crop&w=400&q=80',
            productName: 'تفاح أحمر',
            quantityInfo: '٢ كجم',
            price: '٦٠ ج.م',
            onRemove: () {
              // remove from favorites logic
            },
          );
        },
      ),
    );
  }
}
