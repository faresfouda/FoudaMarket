import 'package:fodamarket/components/Button.dart';
import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/SignIn/SignIn.dart';

class OnBording extends StatelessWidget {
  final VoidCallback? onFinish;
  const OnBording({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          SizedBox.expand(
            child: Padding(
              padding: EdgeInsets.only(right: 0),
              child: Image.asset(
                'assets/getstarted/getStarted.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Image(image: AssetImage('assets/getstarted/Group.png')),
              ),
              Text(
                'أهلاً بيك',
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'عندنا',
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'اطلب دلوقتي، والتوصيل في خلال ساعة! ',
                style: TextStyle(
                  color: AppColors.offWhiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20),
              Button(
                onPressed: () {
                  if (onFinish != null) {
                    onFinish!();
                  } else {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
                  }
                },
                buttonContent: Text(
                  'اطلب دلوقتي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                  ),
                ),
                buttonColor: AppColors.orangeColor,
              ),
              SizedBox(height: 55),
            ],
          ),
        ],
      ),
    );
  }
}
