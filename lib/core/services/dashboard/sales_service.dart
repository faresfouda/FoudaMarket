import 'package:cloud_firestore/cloud_firestore.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getWeeklySalesData() async {
    try {
      final today = DateTime.now();
      final weekData = <Map<String, dynamic>>[];

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final dayOrdersQuery = await _firestore
            .collection('orders')
            .where(
              'created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('created_at', isLessThan: Timestamp.fromDate(endOfDay))
            .where('status', whereIn: ['delivered', 'completed'])
            .get();

        double daySales = 0;
        for (var doc in dayOrdersQuery.docs) {
          final data = doc.data();
          daySales += (data['total'] ?? 0).toDouble();
        }

        weekData.add({
          'date': startOfDay,
          'sales': daySales,
          'orders': dayOrdersQuery.docs.length,
        });
      }

      return weekData;
    } catch (e) {
      print('Error getting weekly sales data: $e');
      return [];
    }
  }
}
