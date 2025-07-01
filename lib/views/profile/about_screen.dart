import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Image.asset(
              'assets/home/backgroundblur.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'حول التطبيق',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/home/logo.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'فودة ماركت',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'تطبيق فودة ماركت هو منصتك الذكية لتسوق جميع احتياجاتك من المنتجات الغذائية والمنزلية بسهولة وسرعة. استمتع بتجربة تسوق فريدة مع أفضل العروض، خيارات دفع متعددة، وتوصيل سريع حتى باب منزلك. هدفنا هو راحتك ورضاك، ونسعى دائماً لتقديم الأفضل.',
                            style: TextStyle(fontSize: 18, color: Colors.black87, height: 1.7),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          const Divider(),
                          const Text(
                            'جميع الحقوق محفوظة © 2024 فودة ماركت',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
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