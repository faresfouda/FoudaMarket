import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/components/CustomTextField.dart';
import 'package:fodamarket/components/navigatorbutton.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/login/Login.dart';

class Selectlocation extends StatelessWidget {
  const Selectlocation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: Navigatorbutton()),
      body: Center(
        child: Column(
          children: [
            Image(
              image: AssetImage('assets/selectLocation/selectlocation.png'),
            ),
            SizedBox(height: 20),
            Text(
              'حدد موقعك ',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "شغّل موقعك عشان تتابع كل الجديد حوليك",
              style: TextStyle(
                color: AppColors.mediumGrayColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 50),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                children: [
                  SizedBox(height: 10),
                  CustomTextField(
                    hinttext: 'محافظتك :',
                    title: 'المحافظة',
                    button: null,
                  ),
                  SizedBox(height: 20),
                  CustomTextField(
                    hinttext: 'مدينتك : ',
                    title: 'المدينة',
                    button: null,
                  ),
                  SizedBox(height: 20),
                  Button(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    },
                    buttonContent: Text(
                      'تأكيد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    buttonColor: AppColors.orangeColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
