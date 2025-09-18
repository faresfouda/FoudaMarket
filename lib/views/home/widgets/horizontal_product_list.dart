import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/product/product_event.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/views/product/product_screen.dart';
import 'package:fouda_market/components/item_container.dart';

class HorizontalProductList extends StatelessWidget {
  final List<ProductModel> products;

  const HorizontalProductList({super.key, this.products = const []});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text('لا توجد منتجات', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListenableBuilder(
            listenable: context.read<ProductBloc>().favoritesNotifier,
            builder: (context, child) {
              final bloc = context.read<ProductBloc>();
              final isFavorite = bloc.favoritesNotifier.isProductFavorite(
                product.id,
              );
              return ProductCard(
                product: product,
                isFavorite: isFavorite,
                onFavoritePressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    if (isFavorite) {
                      context.read<ProductBloc>().add(
                        RemoveFromFavorites(user.uid, product.id),
                      );
                    } else {
                      context.read<ProductBloc>().add(
                        AddToFavorites(user.uid, product.id),
                      );
                    }
                  }
                },
                onAddPressed: () async {
                  // Add to cart logic can be implemented here
                },
              );
            },
          );
        },
      ),
    );
  }
}
