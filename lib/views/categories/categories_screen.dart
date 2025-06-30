import 'package:flutter/material.dart';
import 'package:fodamarket/views/categories/widgets/category_card.dart';
import 'package:fodamarket/views/home/widgets/my_searchbutton.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الاقسام'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            SizedBox(height: 20),
            SearchButton(),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 20.0,
                ),
                itemCount: 10, // Example item count
                itemBuilder: (context, index) {
                  return CategoryCardGrid(
                    context: context,
                    backgroundColor: Color(0xFFF0FFF0), // This is a light green color from the image
                    imagePath: 'https://i.ibb.co/hJN2FQPF/pngfuel-6.png', // Assuming your image is in assets
                    categoryName: 'Fresh Fruits\n& Vegetable', // Use \n for line break if needed
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
