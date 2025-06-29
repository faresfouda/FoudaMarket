import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/components/phonetextfield.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/Number/Number.dart';
import 'package:get/get.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image(image: AssetImage('assets/login/logo.png')),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مع فودة.. البقالة أسهل وأسرع! ',
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: PhoneTextField(
                        autofocus: false,
                        onTap: () {
                          Get.to(Number());
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'أو سجل الدخول باستخدام وسائل التواصل الاجتماعي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mediumGrayColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          Button(
                            onPressed: () {},
                            buttonContent: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/socialmedia/Google.png'),
                                SizedBox(width: 20),
                                Text(
                                  'التواصل عبر جوجل',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            buttonColor: AppColors.lightBlueColor,
                          ),
                          SizedBox(height: 20),
                          Button(
                            onPressed: () {},
                            buttonContent: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/socialmedia/Facebook.png'),
                                SizedBox(width: 20),
                                Text(
                                  'التواصل عبر فيس بوك',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            buttonColor: AppColors.darkBlueColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
