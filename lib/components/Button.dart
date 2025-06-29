import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.onPressed,
    required this.buttonContent,
    required this.buttonColor,
  });
  final VoidCallback onPressed;
  final Widget buttonContent;
  final Color buttonColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(buttonColor),
        minimumSize: WidgetStatePropertyAll(Size(353, 67)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      child: buttonContent,
    );
  }
}
