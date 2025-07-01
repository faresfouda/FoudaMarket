import 'package:flutter/material.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/home/main_screen.dart';

class OrderAcceptedScreen extends StatelessWidget {
  const OrderAcceptedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background blur image
            Positioned.fill(
              child: Image.asset(
                'assets/home/backgroundblur.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Centered content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Order completed image
                        SizedBox(
                          height: 220,
                          child: Image.asset(
                            'assets/home/order completed.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 48),
                        const Text(
                          'تم قبول طلبك',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'تم استلام طلبك وجاري معالجته وإرساله إليك',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 65,
                          child: Button(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MainScreen()));
                            },
                            buttonContent: const Text('تتبع الطلب'),
                            buttonColor: AppColors.orangeColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 65,
                          child: Button(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MainScreen()));
                            },
                            buttonContent: const Text('العودة إلى الرئيسية'),
                            buttonColor: AppColors.orangeColor,
                          ),
                        ),
                      ],
                    ),
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