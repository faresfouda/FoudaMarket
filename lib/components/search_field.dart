import 'package:flutter/material.dart';
import '../theme/appcolors.dart';

class SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry? contentPadding;

  const SearchField({
    Key? key,
    this.controller,
    this.hintText = '',
    this.onChanged,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGrayColor3),
      ),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
} 