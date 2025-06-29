import 'package:flutter/material.dart';
import 'package:fodamarket/components/phonetextfield.dart';
import 'package:fodamarket/components/navigatorbutton.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/selectlocation/selectLocation.dart';

class Number extends StatelessWidget {
  const Number({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: Navigatorbutton()),
      body: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Expanded(
          child: ListView(
            children: [
              Text(
                'أدخل رقم الهاتف',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'رقم الهاتف',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mediumGrayColor,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 0, left: 20),
                child: PhoneTextField(autofocus: true, onTap: () {}),
              ),
              SizedBox(height: 200),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.orangeColor,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Selectlocation(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.whiteColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
