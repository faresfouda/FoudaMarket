// NOTE: This screen includes الرئيسية (dashboard) in the navigation bar.
// For data entry, see DataEntryHomeScreen, which excludes الرئيسية from the navigation bar.
import 'package:flutter/material.dart';
import 'package:fouda_market/views/admin/orders_screen.dart';
import 'package:fouda_market/views/admin/products_categories_screen.dart';
import 'package:fouda_market/views/admin/profile_screen.dart';
import 'package:fouda_market/views/admin/reviews_screen.dart';
import 'package:fouda_market/views/admin/send_notification_screen.dart';
import 'package:fouda_market/views/admin/sales_reports_screen.dart';
import 'package:fouda_market/views/admin/admin_devtools_screen.dart';
import 'package:fouda_market/core/services/dashboard_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import 'package:fouda_market/views/profile/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _ordersInitialFilter;

  late final List<Widget> _screens = [
    AdminDashboardSection(onTabChange: _onTabChange),
    ProductsCategoriesScreen(),
    OrdersScreen(initialFilter: _ordersInitialFilter),
    ReviewsScreen(),
    ProfileScreen(),
  ];

  static const List<String> _titles = [
    'لوحة التحكم',
    'المنتجات',
    'الطلبات',
    'المراجعة',
    'الإعدادات',
  ];

  void _onTabChange(int index, {String? filter}) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        _ordersInitialFilter = filter;
        // Recreate the orders screen with the new filter
        _screens[2] = OrdersScreen(initialFilter: _ordersInitialFilter);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تعيين context لخدمة الإشعارات
      NotificationService().setContext(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the callback is always up to date
    _screens[0] = AdminDashboardSection(onTabChange: _onTabChange);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/home/logo.jpg'),
              radius: 18,
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'المنتجات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'المراجعة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

class AdminDashboardSection extends StatefulWidget {
  final void Function(int, {String? filter})? onTabChange;
  const AdminDashboardSection({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<AdminDashboardSection> createState() => _AdminDashboardSectionState();
}

class _AdminDashboardSectionState extends State<AdminDashboardSection> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _includeLastWeek = false; // للتبديل بين اليوم وآخر أسبوع

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // جلب الإحصائيات والنشاط الأخير في نفس الوقت
      final results = await Future.wait([
        _dashboardService.getDashboardStats(includeLastWeek: _includeLastWeek),
        _dashboardService.getRecentActivity(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _recentActivity = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} ج.م';
  }

  String _formatPercent(int percent) {
    if (percent > 0) {
      return '+$percent%';
    } else if (percent < 0) {
      return '$percent%';
    } else {
      return '0%';
    }
  }

  Color _getPercentColor(int percent) {
    if (percent > 0) {
      return Colors.green;
    } else if (percent < 0) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // زر التبديل بين اليوم وآخر أسبوع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإحصائيات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  Text(
                    _includeLastWeek ? 'آخر 7 أيام' : 'اليوم',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Switch(
                    value: _includeLastWeek,
                    onChanged: (value) {
                      setState(() {
                        _includeLastWeek = value;
                      });
                      _loadDashboardData();
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Metrics Grid (Wrap)
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _MetricCard(
                icon: Icons.shopping_bag,
                iconColor: Colors.blue,
                title: 'الطلبات الجديدة',
                value: '${_stats['newOrders'] ?? 0}',
                percent: _formatPercent(_stats['ordersChangePercent'] ?? 0),
                percentColor: _getPercentColor(_stats['ordersChangePercent'] ?? 0),
              ),
              _MetricCard(
                icon: Icons.bar_chart,
                iconColor: Colors.orange,
                title: 'إجمالي المبيعات',
                value: _formatCurrency(_stats['todaySales'] ?? 0.0),
                percent: _formatPercent(_stats['salesChangePercent'] ?? 0),
                percentColor: _getPercentColor(_stats['salesChangePercent'] ?? 0),
              ),
              _MetricCard(
                icon: Icons.people,
                iconColor: Colors.purple,
                title: 'إجمالي العملاء',
                value: '${_stats['totalCustomers'] ?? 0}',
                percent: _formatPercent(_stats['customersChangePercent'] ?? 0),
                percentColor: _getPercentColor(_stats['customersChangePercent'] ?? 0),
              ),
              _MetricCard(
                icon: Icons.rate_review,
                iconColor: Colors.blue,
                title: 'مراجعات بانتظار الموافقة',
                value: '${_stats['pendingReviews'] ?? 0}',
                percent: _stats['pendingReviews'] != null && _stats['pendingReviews'] > 0 ? 'جديد' : 'لا يوجد',
                percentColor: _stats['pendingReviews'] != null && _stats['pendingReviews'] > 0 ? Colors.blue : Colors.grey,
              ),
            ],
          ),
          SizedBox(height: 32),
          // Quick Actions (Wrap)
          Text(
            'إجراءات سريعة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _QuickActionCard(
                icon: Icons.add,
                label: 'إضافة منتج',
                color: Colors.orange,
                labelColor: Colors.white,
                iconColor: Colors.white,
                onTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(1);
                  }
                },
              ),
              _QuickActionCard(
                icon: Icons.notifications_active,
                label: 'إرسال إشعار للعملاء',
                color: Colors.orange[50]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SendNotificationScreen(),
                    ),
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.bar_chart,
                label: 'تقارير المبيعات',
                color: Colors.orange[50]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalesReportsScreen(),
                    ),
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.list_alt,
                label: 'طلبات جديدة',
                color: Colors.orange[50]!,
                onTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(2, filter: 'جديد');
                  }
                },
              ),
              // كارد أدوات المطور
              _QuickActionCard(
                icon: Icons.developer_mode,
                label: 'أدوات المطور',
                color: Colors.grey[200]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminDevToolsScreen(),
                    ),
                  );
                },
              ),
              // كارد إنشاء طلب تجريبي
              _QuickActionCard(
                icon: Icons.bug_report,
                label: 'إنشاء طلب تجريبي',
                color: Colors.red[100]!,
                onTap: () async {
                  await _dashboardService.createTestOrder();
                  _loadDashboardData(); // إعادة تحميل البيانات
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إنشاء طلب تجريبي بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 32),
          // Recent Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'النشاط الأخير',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.orange),
                    onPressed: _loadDashboardData,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllActivityScreen(),
                        ),
                      );
                    },
                    child: Text('عرض الكل', style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _recentActivity.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'لا يوجد نشاط حديث',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: _recentActivity.take(4).map((activity) {
                    return Column(
                      children: [
                        _ActivityItem(
                          icon: activity['icon'],
                          iconColor: activity['iconColor'],
                          text: activity['text'],
                          time: activity['time'],
                          details: activity['details'],
                        ),
                        SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
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
          Text(
            'المراجعة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(Icons.rate_review, color: Colors.orange),
              title: Text('مراجعة تقييم منتج'),
              subtitle: Text(
                'عميل: أحمد محمد\nالتقييم: "منتج ممتاز وسعر مناسب"',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(onPressed: () {}, child: Text('قبول')),
                  SizedBox(width: 8),
                  OutlinedButton(onPressed: () {}, child: Text('رفض')),
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
              trailing: ElevatedButton(onPressed: () {}, child: Text('عرض')),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('طلب تعديل تقييم'),
              subtitle: Text(
                'عميل: سارة أحمد\nالتقييم الحالي: "جيد لكن التوصيل تأخر"',
              ),
              trailing: ElevatedButton(onPressed: () {}, child: Text('تعديل')),
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
    return Center(
      child: Text(
        'شاشة المنتجات (قريباً)',
        style: TextStyle(fontSize: 22, color: Colors.grey[700]),
      ),
    );
  }
}

class AdminOrdersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'شاشة الطلبات (قريباً)',
        style: TextStyle(fontSize: 22, color: Colors.grey[700]),
      ),
    );
  }
}

class AdminSettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'شاشة الإعدادات (قريباً)',
        style: TextStyle(fontSize: 22, color: Colors.grey[700]),
      ),
    );
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
                  Text(
                    percent,
                    style: TextStyle(
                      color: percentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),
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
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor ?? Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
          title: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(details, style: TextStyle(fontSize: 14)),
          trailing: Text(
            time,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class AllActivityScreen extends StatefulWidget {
  const AllActivityScreen({super.key});

  @override
  State<AllActivityScreen> createState() => _AllActivityScreenState();
}

class _AllActivityScreenState extends State<AllActivityScreen> {
  DateTime? selectedDate;
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> allActivities = [];
  
  // متغيرات pagination
  dynamic _lastTimestamp;
  String? _lastDocumentId;
  String? _lastType;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _dashboardService.getRecentActivityPaginated(limit: 20);
      
      if (mounted) {
        setState(() {
          allActivities = result['activities'] as List<Map<String, dynamic>>;
          _hasMore = result['hasMore'] as bool;
          _lastTimestamp = result['lastTimestamp'];
          _lastDocumentId = result['lastDocumentId'] as String?;
          _lastType = result['lastType'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل النشاطات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreActivities() async {
    if (!_hasMore || _isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final result = await _dashboardService.getRecentActivityPaginated(
        limit: 20,
        lastTimestamp: _lastTimestamp,
        lastDocumentId: _lastDocumentId,
        lastType: _lastType,
      );

      if (mounted) {
        setState(() {
          final newActivities = result['activities'] as List<Map<String, dynamic>>;
          allActivities.addAll(newActivities);
          _hasMore = result['hasMore'] as bool;
          _lastTimestamp = result['lastTimestamp'];
          _lastDocumentId = result['lastDocumentId'] as String?;
          _lastType = result['lastType'] as String?;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المزيد من النشاطات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredActivities {
    if (selectedDate != null) {
      return allActivities
          .where(
            (a) {
              final timestamp = a['timestamp'];
              DateTime? activityDate;
              
              if (timestamp is Timestamp) {
                activityDate = timestamp.toDate();
              } else if (timestamp is String) {
                try {
                  activityDate = DateTime.parse(timestamp);
                } catch (e) {
                  return false;
                }
              } else {
                return false;
              }
              
              if (activityDate == null) return false;
              
              return activityDate.day == selectedDate!.day &&
                     activityDate.month == selectedDate!.month &&
                     activityDate.year == selectedDate!.year;
            },
          )
          .toList();
    }
    return allActivities;
  }

  String get dateLabel {
    if (selectedDate == null) return 'الكل';
    final d = selectedDate!;
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMore) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadMoreActivities,
                child: const Text('تحميل المزيد'),
              ),
      ),
    );
  }

  Widget _buildDetailedActivityItem(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  activity['icon'],
                  color: activity['iconColor'],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activity['text']} - ${activity['userName'] ?? 'غير محدد'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['details'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity['time'],
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // تفاصيل إضافية حسب نوع النشاط
            if (activity['type'] == 'order') ...[
              _buildOrderDetails(activity),
            ] else if (activity['type'] == 'review') ...[
              _buildReviewDetails(activity),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'تفاصيل الطلب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('رقم الطلب: ${activity['orderId']?.substring(0, 8) ?? 'غير محدد'}'),
              Text('${activity['orderTotal']} ج.م'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الحالة: ${_getOrderStatusText(activity['orderStatus'])}'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(activity['orderStatus']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getOrderStatusText(activity['orderStatus']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDetails(Map<String, dynamic> activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'تفاصيل المراجعة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (activity['reviewRating'] ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
              const SizedBox(width: 8),
              Text('${activity['reviewRating'] ?? 0}/5'),
            ],
          ),
          const SizedBox(height: 4),
          if (activity['reviewText']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'التعليق: ${activity['reviewText']}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الحالة: ${_getReviewStatusText(activity['reviewStatus'])}'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReviewStatusColor(activity['reviewStatus']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getReviewStatusText(activity['reviewStatus']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getOrderStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير محدد';
    }
  }

  Color _getOrderStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getReviewStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير محدد';
    }
  }

  Color _getReviewStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كل النشاطات'), 
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllActivities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(selectedDate == null ? 'اختر يوم' : dateLabel),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      if (selectedDate != null)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => setState(() => selectedDate = null),
                          child: const Text('الكل'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredActivities.isEmpty
                        ? const Center(child: Text('لا يوجد نشاطات في هذا اليوم'))
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                                if (_hasMore && !_isLoadingMore) {
                                  _loadMoreActivities();
                                }
                              }
                              return true;
                            },
                            child: ListView.separated(
                              itemCount: filteredActivities.length + (_hasMore ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index == filteredActivities.length) {
                                  // عرض مؤشر تحميل المزيد
                                  return _buildLoadMoreIndicator();
                                }
                                
                                final a = filteredActivities[index];
                                return _buildDetailedActivityItem(a);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}


