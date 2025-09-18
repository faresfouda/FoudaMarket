import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouda_market/core/services/dashboard_service.dart';

void main() async {
  // اختبار جلب النشاطات
  print('=== اختبار جلب النشاطات ===');

  try {
    final dashboardService = DashboardService();
    final activities = await dashboardService.getRecentActivity(limit: 20);

    print('تم جلب ${activities.length} نشاط');

    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      print(
        '${i + 1}. نوع: ${activity['type']} - نص: ${activity['text']} - تفاصيل: ${activity['details']}',
      );

      if (activity['type'] == 'order') {
        print('   - رقم الطلب: ${activity['orderId']}');
        print('   - حالة الطلب: ${activity['orderStatus']}');
        print('   - إجمالي الطلب: ${activity['orderTotal']}');
        print('   - تم التحديث بواسطة: ${activity['updatedBy']}');
        print('   - وقت التحديث: ${activity['updatedAt']}');
      }
    }
  } catch (e) {
    print('خطأ في جلب النشاطات: $e');
  }

  // اختبار جلب الطلبات مباشرة من Firestore
  print('\n=== اختبار جلب الطلبات من Firestore ===');

  try {
    final firestore = FirebaseFirestore.instance;
    final ordersQuery = await firestore
        .collection('orders')
        .orderBy('created_at', descending: true)
        .limit(10)
        .get();

    print('تم العثور على ${ordersQuery.docs.length} طلب في Firestore');

    for (int i = 0; i < ordersQuery.docs.length; i++) {
      final doc = ordersQuery.docs[i];
      final data = doc.data();
      print('${i + 1}. طلب ${doc.id}:');
      print('   - الحالة: ${data['status']}');
      print('   - تاريخ الإنشاء: ${data['created_at']}');
      print('   - تاريخ التحديث: ${data['updated_at']}');
      print('   - تم التحديث بواسطة: ${data['updated_by']}');
      print('   - إجمالي: ${data['total']}');
    }
  } catch (e) {
    print('خطأ في جلب الطلبات من Firestore: $e');
  }
}
