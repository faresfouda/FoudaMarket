import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';

class Navigatorbutton extends StatelessWidget {
  const Navigatorbutton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: Icon(Icons.arrow_back_ios_new, color: AppColors.orangeColor),
    );
  }
}
