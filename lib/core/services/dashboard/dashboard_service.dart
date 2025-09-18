import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_service.dart';
import 'stats_service.dart';
import 'sales_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ActivityService _activityService = ActivityService();
  final StatsService _statsService = StatsService();
  final SalesService _salesService = SalesService();

  // واجهة مبسطة للخدمات
  Future<Map<String, dynamic>> getDashboardStats({
    bool includeLastWeek = false,
  }) {
    return _statsService.getDashboardStats(includeLastWeek: includeLastWeek);
  }

  Future<Map<String, dynamic>> getRecentActivityPaginated({
    int limit = 10,
    dynamic lastTimestamp,
    String? lastDocumentId,
    String? lastType,
  }) {
    return _activityService.getRecentActivityPaginated(
      limit: limit,
      lastTimestamp: lastTimestamp,
      lastDocumentId: lastDocumentId,
      lastType: lastType,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final result = await _activityService.getRecentActivity(limit: limit);
    print('[DEBUG] DashboardService: got ${result.length} activities');
    return result;
  }

  Future<List<Map<String, dynamic>>> getWeeklySalesData() {
    return _salesService.getWeeklySalesData();
  }

  Future<void> createTestOrder() async {
    // إنشاء طلب تجريبي بسيط
    final firestore = FirebaseFirestore.instance;
    final testOrderData = {
      'customer_name': 'عميل تجريبي',
      'customer_phone': '0123456789',
      'delivery_address': 'عنوان تجريبي',
      'delivery_address_name': 'المنزل',
      'delivery_phone': '0123456789',
      'items': [
        {'name': 'منتج تجريبي', 'qty': '2', 'price': '50.0', 'image': ''},
      ],
      'total': 100.0,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': 'admin',
      'admin_id': 'admin',
    };

    await firestore.collection('orders').add(testOrderData);
  }
}
