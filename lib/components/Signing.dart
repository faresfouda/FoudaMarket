import 'package:flutter/material.dart';
import 'package:fodamarket/components/navigatorbutton.dart';
import 'package:fodamarket/theme/appcolors.dart';

class Signing extends StatelessWidget {
  const Signing({
    super.key,
    required this.title,
    required this.subTitle,
    required this.screenContent,

  });
  final String title;
  final String subTitle;
  final Widget screenContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Image(image: AssetImage('assets/home/logo.jpg',),width: 100,height: 100,),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    subTitle,
                    style: TextStyle(
                      color: AppColors.mediumGrayColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              screenContent,
            ],
          ),
        ),
      ),
    );
  }
}
