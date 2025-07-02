import 'package:flutter/material.dart';
import 'package:fodamarket/views/admin/admin_products_categories_screen.dart';

class AdminDashboardMain extends StatefulWidget {
  @override
  State<AdminDashboardMain> createState() => _AdminDashboardMainState();
}

class _AdminDashboardMainState extends State<AdminDashboardMain> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    AdminDashboardSection(),
    AdminProductsCategoriesScreen(),
    AdminOrdersSection(),
    AdminReviewSection(),
    AdminSettingsSection(),
  ];

  static const List<String> _titles = [
    'لوحة التحكم',
    'المنتجات',
    'الطلبات',
    'المراجعة',
    'الإعدادات',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 1
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(_titles[_selectedIndex], style: TextStyle(color: Colors.black)),
              actions: _selectedIndex == 0
                  ? [
                      IconButton(
                        icon: Icon(Icons.notifications, color: Colors.orange),
                        onPressed: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CircleAvatar(
                          backgroundImage: AssetImage('assets/home/logo.jpg'),
                          radius: 18,
                        ),
                      ),
                    ]
                  : null,
              iconTheme: IconThemeData(color: Colors.black),
            ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المنتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'المراجعة'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class AdminDashboardSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metrics Grid (Wrap)
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _MetricCard(
                icon: Icons.shopping_bag,
                iconColor: Colors.blue,
                title: 'الطلبات الجديدة',
                value: '187',
                percent: '+8%',
                percentColor: Colors.green,
              ),
              _MetricCard(
                icon: Icons.bar_chart,
                iconColor: Colors.orange,
                title: 'إجمالي المبيعات',
                value: '٢٤,٥٠٠ ج.م',
                percent: '+12%',
                percentColor: Colors.green,
              ),
              _MetricCard(
                icon: Icons.people,
                iconColor: Colors.purple,
                title: 'إجمالي العملاء',
                value: '٩٤',
                percent: '+5%',
                percentColor: Colors.green,
              ),
              _MetricCard(
                icon: Icons.rate_review,
                iconColor: Colors.blue,
                title: 'مراجعات بانتظار الموافقة',
                value: '٣',
                percent: 'جديد',
                percentColor: Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 32),
          // Quick Actions (Wrap)
          Text('إجراءات سريعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _QuickActionCard(
                icon: Icons.list_alt,
                label: 'عرض الطلبات',
                color: Colors.orange[50]!,
                onTap: () {},
              ),
              _QuickActionCard(
                icon: Icons.add,
                label: 'إضافة منتج',
                color: Colors.orange,
                labelColor: Colors.white,
                iconColor: Colors.white,
                onTap: () {},
              ),
              _QuickActionCard(
                icon: Icons.settings,
                label: 'الإعدادات',
                color: Colors.orange[50]!,
                onTap: () {},
              ),
              _QuickActionCard(
                icon: Icons.insert_chart,
                label: 'التقارير',
                color: Colors.orange[50]!,
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 32),
          // Recent Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('النشاط الأخير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('عرض الكل', style: TextStyle(color: Colors.orange)),
            ],
          ),
          SizedBox(height: 16),
          Column(
            children: [
              _ActivityItem(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                text: 'تم تأكيد طلب جديد',
                time: 'منذ 3 دقائق',
                details: 'طلب رقم 1234 - أحمد محمد',
              ),
              SizedBox(height: 16),
              _ActivityItem(
                icon: Icons.add_box,
                iconColor: Colors.orange,
                text: 'تم إضافة منتج جديد',
                time: 'منذ 10 دقائق',
                details: 'تفاح أحمر - 2 كجم',
              ),
              SizedBox(height: 16),
              _ActivityItem(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red,
                text: 'تنبيه مخزون منخفض',
                time: 'منذ ساعة',
                details: 'موز عضوي - بقى 5 قطع فقط',
              ),
              SizedBox(height: 16),
              _ActivityItem(
                icon: Icons.person,
                iconColor: Colors.blue,
                text: 'عميل جديد',
                time: 'منذ ساعتين',
                details: 'سارة أحمد انضمت للتطبيق',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// New Review Section
class AdminReviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('المراجعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(Icons.rate_review, color: Colors.orange),
              title: Text('مراجعة تقييم منتج'),
              subtitle: Text('عميل: أحمد محمد\nالتقييم: "منتج ممتاز وسعر مناسب"'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('قبول'),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: Text('رفض'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.report_gmailerrorred, color: Colors.red),
              title: Text('بلاغ عن تقييم غير لائق'),
              subtitle: Text('منتج: موز عضوي\nالسبب: كلمات غير لائقة'),
              trailing: ElevatedButton(
                onPressed: () {},
                child: Text('عرض'),
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('طلب تعديل تقييم'),
              subtitle: Text('عميل: سارة أحمد\nالتقييم الحالي: "جيد لكن التوصيل تأخر"'),
              trailing: ElevatedButton(
                onPressed: () {},
                child: Text('تعديل'),
              ),
            ),
          ),
          // Add more review items as needed
        ],
      ),
    );
  }
}

// Placeholder Sections (no Scaffold/AppBar)
class AdminProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('شاشة المنتجات (قريباً)', style: TextStyle(fontSize: 22, color: Colors.grey[700])));
  }
}

class AdminOrdersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('شاشة الطلبات (قريباً)', style: TextStyle(fontSize: 22, color: Colors.grey[700])));
  }
}

class AdminSettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('شاشة الإعدادات (قريباً)', style: TextStyle(fontSize: 22, color: Colors.grey[700])));
  }
}

// Metric Card Widget
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String percent;
  final Color percentColor;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.percent,
    required this.percentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 32,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 32),
                  Spacer(),
                  Text(percent, style: TextStyle(color: percentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              SizedBox(height: 16),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
              Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.labelColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 32,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor ?? Colors.orange, size: 32),
                SizedBox(height: 10),
                Text(label, style: TextStyle(color: labelColor ?? Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Activity Item Widget
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String time;
  final String details;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.time,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: iconColor, size: 32),
          title: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(details, style: TextStyle(fontSize: 14)),
          trailing: Text(time, style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      ),
    );
  }
} 