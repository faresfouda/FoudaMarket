import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hinttext,
    required this.title,
    required this.button,
  });
  final String hinttext;
  final String title;
  final Widget? button;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.mediumGrayColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          TextField(
            decoration: InputDecoration(
              suffixIcon: button,
              hintText: hinttext,
              hintStyle: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.blackColor,
              ),

              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.blackColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.blackColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
