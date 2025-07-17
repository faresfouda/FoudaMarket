import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> faqItems = [
    {
      'question': 'كيف يمكنني إنشاء حساب جديد؟',
      'answer': 'اضغط على "تسجيل الدخول" ثم "إنشاء حساب جديد" واملأ البيانات المطلوبة (الاسم، البريد الإلكتروني، كلمة المرور، رقم الهاتف).'
    },
    {
      'question': 'كيف يمكنني إضافة منتجات إلى سلة التسوق؟',
      'answer': 'تصفح المنتجات في الصفحة الرئيسية أو من خلال التصنيفات، ثم اضغط على أيقونة السلة بجانب المنتج المطلوب.'
    },
    {
      'question': 'ما هي طرق الدفع المتاحة؟',
      'answer': 'نوفر عدة طرق دفع: الدفع عند الاستلام، البطاقات الائتمانية، المحافظ الإلكترونية، والتحويل البنكي.'
    },
    {
      'question': 'كم تستغرق مدة التوصيل؟',
      'answer': 'مدة التوصيل تتراوح من ساعة إلى 3 ساعات حسب موقعك. يمكنك متابعة طلبك في الوقت الفعلي.'
    },
    {
      'question': 'كيف يمكنني تتبع طلبي؟',
      'answer': 'اذهب إلى "الطلبات" في الملف الشخصي وستجد جميع طلباتك مع حالة كل طلب وتفاصيل التوصيل.'
    },
    {
      'question': 'ما هي سياسة الاسترجاع؟',
      'answer': 'يمكنك إرجاع المنتج خلال 24 ساعة من الاستلام إذا كان هناك عيب في المنتج أو خطأ في الطلب.'
    },
    {
      'question': 'كيف يمكنني تغيير عنوان التوصيل؟',
      'answer': 'اذهب إلى "عنوان التوصيل" في الملف الشخصي ويمكنك إضافة أو تعديل العناوين المحفوظة.'
    },
    {
      'question': 'كيف يمكنني استخدام كود الخصم؟',
      'answer': 'اذهب إلى "كود الخصم" في الملف الشخصي وأدخل الكود في صفحة الدفع للحصول على الخصم.'
    },
  ];

  final List<Map<String, String>> contactInfo = [
    {'title': 'الهاتف', 'value': '+966 50 123 4567', 'icon': 'phone'},
    {'title': 'البريد الإلكتروني', 'value': 'support@foudamarket.com', 'icon': 'email'},
    {'title': 'الواتساب', 'value': '+966 50 123 4567', 'icon': 'whatsapp'},
    {'title': 'ساعات العمل', 'value': '24/7', 'icon': 'schedule'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _contactViaPhone() {
    _launchUrl('tel:+966501234567');
  }

  void _contactViaEmail() {
    _launchUrl('mailto:support@foudamarket.com');
  }

  void _contactViaWhatsApp() {
    _launchUrl('https://wa.me/966501234567');
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
                          'المساعدة والدعم',
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
                  const SizedBox(height: 8),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.orange,
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.black54,
                    tabs: const [
                      Tab(text: 'الأسئلة الشائعة'),
                      Tab(text: 'الدليل السريع'),
                      Tab(text: 'تواصل معنا'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // FAQ Tab
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: faqItems.length,
                          itemBuilder: (context, index) {
                            return _buildFAQItem(faqItems[index]);
                          },
                        ),
                        // Quick Guide Tab
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildGuideSection(
                              'كيفية الطلب',
                              [
                                'تصفح المنتجات في الصفحة الرئيسية',
                                'اختر المنتجات المطلوبة واضغط على أيقونة السلة',
                                'اذهب إلى سلة التسوق وراجع طلبك',
                                'أدخل عنوان التوصيل وطريقة الدفع',
                                'اضغط على "إتمام الطلب"',
                              ],
                              Icons.shopping_cart,
                            ),
                            const SizedBox(height: 20),
                            _buildGuideSection(
                              'طرق الدفع',
                              [
                                'الدفع عند الاستلام',
                                'البطاقات الائتمانية',
                                'المحافظ الإلكترونية',
                                'التحويل البنكي',
                              ],
                              Icons.payment,
                            ),
                            const SizedBox(height: 20),
                            _buildGuideSection(
                              'سياسة الاسترجاع',
                              [
                                'يمكن إرجاع المنتج خلال 24 ساعة',
                                'يجب أن يكون المنتج في حالة جيدة',
                                'سيتم إرجاع المبلغ خلال 3-5 أيام عمل',
                                'للاستفسار اتصل بنا على الرقم المذكور',
                              ],
                              Icons.assignment_return,
                            ),
                          ],
                        ),
                        // Contact Tab
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const Icon(Icons.support_agent, size: 60, color: Colors.orange),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'فريق الدعم متاح 24/7',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'نحن هنا لمساعدتك في أي وقت',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...contactInfo.map((contact) => _buildContactItem(contact)),
                            const SizedBox(height: 20),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'معلومات إضافية',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      '• خدمة العملاء متاحة على مدار الساعة\n'
                                      '• وقت الاستجابة: خلال 5 دقائق\n'
                                      '• يمكنك التواصل معنا عبر الهاتف أو البريد الإلكتروني\n'
                                      '• نقدم دعم فني مجاني لجميع العملاء',
                                      style: TextStyle(fontSize: 14, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildFAQItem(Map<String, dynamic> item) {
    return ExpansionTile(
      title: Text(
        item['question'],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            item['answer'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideSection(String title, List<String> steps, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              int index = entry.key;
              String step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Map<String, String> contact) {
    IconData icon;
    VoidCallback? onTap;
    
    switch (contact['icon']) {
      case 'phone':
        icon = Icons.phone;
        onTap = _contactViaPhone;
        break;
      case 'email':
        icon = Icons.email;
        onTap = _contactViaEmail;
        break;
      case 'whatsapp':
        icon = Icons.chat;
        onTap = _contactViaWhatsApp;
        break;
      default:
        icon = Icons.schedule;
        onTap = null;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange, size: 24),
        title: Text(contact['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(contact['value']!),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }
} 