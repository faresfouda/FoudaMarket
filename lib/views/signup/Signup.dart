import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/components/CustomTextField.dart';
import 'package:fodamarket/components/Signing.dart';
import 'package:fodamarket/theme/appcolors.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    return Signing(
      title: 'انشاء حساب',
      subTitle: 'أدخل بياناتك للاستمرار',
      screenContent: Expanded(
        child: ListView(
          children: [
            CustomTextField(
              hinttext: 'اسم المستخدم',
              title: "ادخل اسمك الثنائي",
              button: null,
            ),
            CustomTextField(
              hinttext: 'البريد الالكتروني',
              title: "أدخل بريدك الالكتروني",
              button: null,
            ),
            CustomTextField(
              hinttext: "كلمة المرور",
              title: "ادخل كلمة المرور",
              button: null,
            ),
            CustomTextField(
              hinttext: 'تأكيد كلمة المرور',
              title: "تأكيد كلمة المرور",
              button: null,
            ),
            SizedBox(height: 10),
            Button(
              onPressed: () {},
              buttonContent: Text(
                'أنشئ حساب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              buttonColor: AppColors.orangeColor,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'لديك حساب بالفعل؟ ',
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "تسجيل الدخول",
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
