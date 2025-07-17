import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../components/Button.dart';
import '../../theme/appcolors.dart';
import '../../routes.dart';

class OrderAcceptedScreen extends StatelessWidget {
  final String? orderId;
  
  const OrderAcceptedScreen({super.key, this.orderId});

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
                        if (orderId != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.orangeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.orangeColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              'رقم الطلب: $orderId',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.orangeColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'تم استلام طلبك وجاري معالجته وإرساله إليك\nسيتم التواصل معك قريباً',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.4,
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
                              if (orderId != null) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '${AppRoutes.orderDetails}/$orderId',
                                  (route) => false,
                                );
                              } else {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.main,
                                  (route) => false,
                                );
                              }
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
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.main,
                                (route) => false,
                              );
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