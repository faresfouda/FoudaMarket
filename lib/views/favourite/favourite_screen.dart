import 'package:flutter/material.dart';
import 'package:fodamarket/views/cart/widgets/cart_product.dart';
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
            imageUrl: 'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
            productName: 'Apple',
            quantityInfo: '1kg',
            price: '\$4.99',
            onRemove: () {
              // remove from favorites logic
            },
          )
          ;
        },
      ),
    );
  }
}
