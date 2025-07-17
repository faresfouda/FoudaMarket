import 'package:flutter/material.dart';

import '../../category/category_screen.dart';
import '../../../components/cached_image.dart';

Widget CategoryCardGrid({
  required BuildContext context,
  required Color backgroundColor,
  required String imagePath,
  required String categoryName,
  required String categoryId,
}) {
  final Color borderColor = darken(backgroundColor, 0.2); // darken by 20%

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryScreen(
          categoryName: categoryName,
          categoryId: categoryId,
        ),
        ),
      );
    },
    child: Container(
      width: 200,
      // height: 250,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor, // Darker border
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CachedImage(
            imageUrl: imagePath,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              categoryName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
Color darken(Color color, [double amount = .1]) {
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}