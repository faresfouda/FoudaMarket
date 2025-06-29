import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/components/CustomTextField.dart';
import 'package:fodamarket/components/Signing.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/signup/Signup.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Signing(
      title: 'تسجيل الدخول',
      subTitle: 'ادخل البريد الالكتروني وكلمة السر',
      screenContent: Expanded(
        child: ListView(
          children: [
            CustomTextField(
              hinttext: 'أدخل البريد الالكتروني',
              title: 'البريد الالكتروني',
              button: null,
            ),
            SizedBox(height: 10),
            CustomTextField(
              hinttext: 'أدخل كلمة السر',
              title: 'كلمة السر',
              button: IconButton(
                onPressed: () {},
                icon: Icon(Icons.remove_red_eye_outlined),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'هل نسيت كلمة السر؟',
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Button(
              onPressed: () {},
              buttonContent: Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.whiteColor,
                ),
              ),
              buttonColor: AppColors.orangeColor,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ليس لديك حساب؟ ',
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (context) => Signup()));
                  },
                  child: Text(
                    'أنشئ حساب',
                    style: TextStyle(
                      color: AppColors.orangeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
