import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/cart/order_accepted_screen.dart';
import 'package:fodamarket/views/cart/widgets/cart_product.dart';
import 'package:fodamarket/views/product/product_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عربة التسوق'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: 3, // Example item count
        itemBuilder: (context, index) {
          // Arabic mock data
          final products = [
            {
              'imageUrl': 'https://i.pinimg.com/736x/14/fb/f5/14fbf589a2f366f1c3c38a217bf04876.jpg',
              'productName': 'موز عضوي',
              'quantityInfo': '٧ قطع، السعر',
              'price': '٤٩ ج.م',
            },
            {
              'imageUrl': 'https://i.pinimg.com/736x/7a/aa/a5/7aaaa545e00e8a434850e80b8910dd94.jpg',
              'productName': 'تفاح أحمر',
              'quantityInfo': '٢ كجم',
              'price': '٦٠ ج.م',
            },
            {
              'imageUrl': 'https://i.pinimg.com/736x/7a/aa/a5/7aaaa545e00e8a434850e80b8910dd94.jpg',
              'productName': 'برتقال عصير',
              'quantityInfo': '١.٥ كجم',
              'price': '٣٥ ج.م',
            },
          ];
          final product = products[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    imageUrl: product['imageUrl']!,
                    productName: product['productName']!,
                    quantityInfo: product['quantityInfo']!,
                    price: product['price']!,
                  ),
                ),
              );
            },
            child: ProductQuantityControl(
              imageUrl: product['imageUrl']!,
              productName: product['productName']!,
              quantityInfo: product['quantityInfo']!,
              price: product['price']!,
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(12.0),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.orangeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'الإجمالي',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '١٠٠ ج.م',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
