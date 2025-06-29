import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';

class PhoneTextField extends StatelessWidget {
  const PhoneTextField({
    super.key,
    required this.autofocus,
    required this.onTap,
  });
  final bool autofocus;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        onTap: onTap,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: '+20',
          hintStyle: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.blackColor,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: CountryFlag.fromCountryCode(
              'eg',
              width: 3,
              height: 3,
              shape: RoundedRectangle(3),
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.blackColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.blackColor),
          ),
        ),
      ),
    );
  }
}
