import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.blackColor)),
        GestureDetector(
          onTap: onTap,
          child: Text('عرض الكل', style: TextStyle(fontSize: 16, color: AppColors.orangeColor)),
        ),
      ],
    );
  }
} 