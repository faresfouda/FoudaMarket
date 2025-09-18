import 'package:flutter/material.dart';
import 'package:fouda_market/views/admin/orders_screen.dart';
import 'package:fouda_market/views/admin/products_categories_screen.dart';
import 'package:fouda_market/views/admin/profile_screen.dart';
import 'package:fouda_market/views/admin/reviews_screen.dart';
import 'package:fouda_market/core/services/dashboard_service.dart';
import 'package:fouda_market/views/profile/notifications_screen.dart';
import 'screens/all_activity_screen.dart';
import 'widgets/dashboard_metrics.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_activity.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _ordersInitialFilter;
  final DashboardService _dashboardService = DashboardService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardSection(
        onTabChange: _onTabChange,
        dashboardService: _dashboardService,
      ),
      ProductsCategoriesScreen(),
      OrdersScreen(initialFilter: _ordersInitialFilter),
      ReviewsScreen(),
      ProfileScreen(),
    ];
  }

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
        _screens[2] = OrdersScreen(initialFilter: _ordersInitialFilter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 4
          ? null
          : AppBar(
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
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
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
        onTap: (index) => _onTabChange(index),
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
  final DashboardService dashboardService;

  const AdminDashboardSection({
    super.key,
    this.onTabChange,
    required this.dashboardService,
  });

  @override
  State<AdminDashboardSection> createState() => _AdminDashboardSectionState();
}

class _AdminDashboardSectionState extends State<AdminDashboardSection> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];

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

      final results = await Future.wait([
        widget.dashboardService.getDashboardStats(),
        widget.dashboardService.getRecentActivity(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _recentActivity = results[1] as List<Map<String, dynamic>>;
          print(
            '[DEBUG] Dashboard loaded ${_recentActivity.length} activities',
          );
          print(
            '[DEBUG] Activity types: ${_recentActivity.map((a) => a['type']).toList()}',
          );
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

  Future<void> _createTestOrder() async {
    try {
      await widget.dashboardService.createTestOrder();
      _loadDashboardData(); // إعادة تحميل البيانات
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء طلب تجريبي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء طلب تجريبي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardMetrics(stats: _stats),
          SizedBox(height: 32),
          DashboardQuickActions(
            onTabChange: widget.onTabChange,
            onCreateTestOrder: _createTestOrder,
          ),
          SizedBox(height: 32),
          DashboardActivity(
            activities: _recentActivity,
            onRefresh: _loadDashboardData,
            onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllActivityScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
