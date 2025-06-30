import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/cart/widgets/cart_product.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
          return ProductQuantityControl(
            imageUrl: 'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
            productName: 'Organic Bananas',
            quantityInfo: '7pcs, Price',
            price: '\$4.99',
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Button(
          onPressed: (){},
          buttonContent: Row(
            children: [
              const Text(
                'الإجمالي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              const Text(
                'LE 100.00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          buttonColor: AppColors.orangeColor,
        ),
      ),
    );
  }
}
