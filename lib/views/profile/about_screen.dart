import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appVersion = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // App Logo and Basic Info
                  Card(
                    elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
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
                                  const SizedBox(height: 8),
                                  Text(
                                    'الإصدار $appVersion ($buildNumber)',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                          const SizedBox(height: 18),
                          const Text(
                                    'منصتك الذكية لتسوق جميع احتياجاتك من المنتجات الغذائية والمنزلية بسهولة وسرعة. استمتع بتجربة تسوق فريدة مع أفضل العروض، خيارات دفع متعددة، وتوصيل سريع حتى باب منزلك.',
                                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.7),
                            textAlign: TextAlign.center,
                          ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Features Section
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'مميزات التطبيق',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFeatureItem(Icons.shopping_cart, 'تسوق سريع وسهل'),
                                  _buildFeatureItem(Icons.local_shipping, 'توصيل سريع'),
                                  _buildFeatureItem(Icons.payment, 'دفع آمن ومتعدد'),
                                  _buildFeatureItem(Icons.track_changes, 'تتبع الطلبات'),
                                  _buildFeatureItem(Icons.favorite, 'قائمة المفضلة'),
                                  _buildFeatureItem(Icons.star, 'تقييمات ومراجعات'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Company Info
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'معلومات الشركة',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoItem('اسم الشركة', 'فودة ماركت'),
                                  _buildInfoItem('العنوان', 'المملكة العربية السعودية'),
                                  _buildInfoItem('البريد الإلكتروني', 'info@foudamarket.com'),
                                  _buildInfoItem('الهاتف', '+966 50 123 4567'),
                                  _buildInfoItem('ساعات العمل', '24/7'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Social Media Links
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'تابعنا على',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildSocialButton(
                                        Icons.facebook,
                                        'فيسبوك',
                                        () => _launchUrl('https://facebook.com/foudamarket'),
                                        Colors.blue,
                                      ),
                                      _buildSocialButton(
                                        Icons.chat,
                                        'واتساب',
                                        () => _launchUrl('https://wa.me/966501234567'),
                                        Colors.green,
                                      ),
                                      _buildSocialButton(
                                        Icons.email,
                                        'إيميل',
                                        () => _launchUrl('mailto:info@foudamarket.com'),
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Legal Info
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          const Text(
                                    'معلومات قانونية',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLegalItem('سياسة الخصوصية', () {
                                    // Navigate to privacy policy
                                  }),
                                  _buildLegalItem('شروط الاستخدام', () {
                                    // Navigate to terms of service
                                  }),
                                  _buildLegalItem('سياسة الاسترجاع', () {
                                    // Navigate to return policy
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Copyright
                          const Card(
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'جميع الحقوق محفوظة © 2024 فودة ماركت\nتم التطوير بواسطة فريق فودة ماركت',
                                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLegalItem(String text, VoidCallback onTap) {
    return ListTile(
      title: Text(text, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 