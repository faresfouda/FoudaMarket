import 'package:flutter/material.dart';

class ProductTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final String? suffixText;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextDirection textDirection;
  final int? maxLines;
  final bool alignLabelWithHint;
  final VoidCallback? onChanged;

  const ProductTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.suffixText,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.textDirection = TextDirection.rtl,
    this.maxLines = 1,
    this.alignLabelWithHint = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixText: suffixText,
        hintText: hintText,
        errorText: errorText,
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: onChanged != null ? (_) => onChanged!() : null,
    );
  }
}
