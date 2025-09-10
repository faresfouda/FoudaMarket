import 'package:cloud_firestore/cloud_firestore.dart';
import 'helpers.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getDashboardStats({
    bool includeLastWeek = false,
  }) async {
    try {
      // جلب الطلبات الجديدة (الشهر الحالي)
      final today = DateTime.now();
      final startOfMonth = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 30));
      final endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 1));

      DateTime startDate = startOfMonth;
      DateTime endDate = endOfDay;
      String periodLabel = 'آخر 30 يوم';

      print('📅 [DASHBOARD] الفترة: $periodLabel');
      print('📅 [DASHBOARD] من: ${startDate.toIso8601String()}');
      print('📅 [DASHBOARD] إلى: ${endDate.toIso8601String()}');

      // جلب الطلبات
      final allOrdersQuery = await _searchOrdersByDate(startDate, endDate);

      // تصفية الطلبات حسب التاريخ وتشمل فقط الطلبات الجديدة (pending)
      final filteredOrders = <QueryDocumentSnapshot>[];
      for (var doc in allOrdersQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['created_at'];
        final orderDate = parseTimestamp(timestamp);
        final status = data?['status'] ?? '';
        if (status == 'pending' &&
            orderDate.isAfter(startDate) &&
            orderDate.isBefore(endDate)) {
          filteredOrders.add(doc);
        }
      }

      final newOrders = filteredOrders.length;
      print('📊 [DASHBOARD] إجمالي الطلبات الجديدة (pending فقط): $newOrders');

      // جلب إجمالي المبيعات (الشهر) - تشمل فقط الطلبات المكتملة
      double todaySales = 0;
      for (var doc in allOrdersQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['created_at'];
        final orderDate = parseTimestamp(timestamp);
        final status = data?['status'] ?? '';
        if ((status == 'delivered' || status == 'completed') &&
            orderDate.isAfter(startDate) &&
            orderDate.isBefore(endDate)) {
          final orderData = _analyzeOrderData(doc);
          print(
            '📝 [DASHBOARD] طلب مكتمل:  [1m${orderData['id']} [0m - الحالة: ${orderData['status']} - الإجمالي: ${orderData['total']}',
          );
          todaySales += orderData['total'];
          print('💰 [DASHBOARD] إضافة للبيع: ${orderData['total']}');
        }
      }
      print('💰 [DASHBOARD] إجمالي المبيعات الشهر (المكتملة فقط): $todaySales');

      // جلب إجمالي العملاء خلال الشهر (فلترة في الكود)
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
      final totalCustomers = usersQuery.docs.where((doc) {
        final data = doc.data();
        final createdAtRaw = data['createdAt'];
        DateTime? createdAt;
        if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw);
        } else if (createdAtRaw is Timestamp) {
          createdAt = createdAtRaw.toDate();
        }
        return createdAt != null &&
            createdAt.isAfter(startDate) &&
            createdAt.isBefore(endDate);
      }).length;
      print('👥 [DASHBOARD] إجمالي العملاء (آخر شهر): $totalCustomers');

      // جلب المراجعات بانتظار الموافقة خلال الشهر (فلترة في الكود)
      final pendingReviewsQuery = await _firestore
          .collection('reviews')
          .where('status', isEqualTo: 'pending')
          .get();
      final pendingReviews = pendingReviewsQuery.docs.where((doc) {
        final data = doc.data();
        final createdAtRaw = data['created_at'];
        DateTime? createdAt;
        if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw);
        } else if (createdAtRaw is Timestamp) {
          createdAt = createdAtRaw.toDate();
        }
        return createdAt != null &&
            createdAt.isAfter(startDate) &&
            createdAt.isBefore(endDate);
      }).length;
      print('⭐ [DASHBOARD] المراجعات المعلقة (آخر شهر): $pendingReviews');

      // حساب النسب المئوية مقارنة بالفترة السابقة (30 يوم قبل startDate)
      final previousMonthStart = startDate.subtract(const Duration(days: 30));
      final previousMonthEnd = startDate;

      print(
        '📅 [DASHBOARD] فترة الشهر الماضي: من ${previousMonthStart.toIso8601String()} إلى ${previousMonthEnd.toIso8601String()}',
      );

      // جلب بيانات الشهر الماضي للطلبات
      final previousOrdersQuery = await _searchOrdersByDate(
        previousMonthStart,
        previousMonthEnd,
      );

      print(
        '📋 [DASHBOARD] إجمالي الطلبات في الشهر الماضي (قبل الفلترة): ${previousOrdersQuery.docs.length}',
      );

      final previousOrders = previousOrdersQuery.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['created_at'];
        final orderDate = parseTimestamp(timestamp);
        final status = data?['status'] ?? '';
        final isValid =
            status == 'pending' &&
            orderDate.isAfter(previousMonthStart) &&
            orderDate.isBefore(previousMonthEnd);

        if (isValid) {
          print(
            '✅ [DASHBOARD] طلب جديد في الشهر الماضي: ${doc.id} - ${orderDate.toIso8601String()} - $status',
          );
        }

        return isValid;
      }).length;

      // جلب بيانات الشهر الماضي للمبيعات
      double previousSales = 0;
      for (var doc in previousOrdersQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['created_at'];
        final orderDate = parseTimestamp(timestamp);
        final status = data?['status'] ?? '';
        if ((status == 'delivered' || status == 'completed') &&
            orderDate.isAfter(previousMonthStart) &&
            orderDate.isBefore(previousMonthEnd)) {
          final orderData = _analyzeOrderData(doc);
          previousSales += orderData['total'];
          print(
            '💰 [DASHBOARD] إضافة مبيعات الشهر الماضي: ${orderData['total']} من طلب ${doc.id}',
          );
        }
      }

      // جلب بيانات الشهر الماضي للعملاء
      final previousCustomers = usersQuery.docs.where((doc) {
        final data = doc.data();
        final createdAtRaw = data['createdAt'];
        DateTime? createdAt;
        if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw);
        } else if (createdAtRaw is Timestamp) {
          createdAt = createdAtRaw.toDate();
        }
        final isValid =
            createdAt != null &&
            createdAt.isAfter(previousMonthStart) &&
            createdAt.isBefore(previousMonthEnd);

        if (isValid) {
          print(
            '👤 [DASHBOARD] عميل صالح في الشهر الماضي: ${doc.id} - ${createdAt.toIso8601String()}',
          );
        }

        return isValid;
      }).length;

      print(
        '📊 [DASHBOARD] البيانات الحالية - الطلبات: $newOrders, المبيعات: $todaySales, العملاء: $totalCustomers',
      );
      print(
        '📊 [DASHBOARD] البيانات السابقة - الطلبات: $previousOrders, المبيعات: $previousSales, العملاء: $previousCustomers',
      );

      // حساب النسب المئوية مع منطق محسن
      int ordersChangePercent;
      if (previousOrders == 0) {
        // إذا كان عدد الطلبات السابقة 0، نعرض عدد الطلبات الجديدة كنسبة مئوية
        // مع حد أقصى 100%
        ordersChangePercent = newOrders > 10 ? 100 : newOrders * 10;
      } else {
        ordersChangePercent =
            ((newOrders - previousOrders) / previousOrders * 100).round();
      }

      int salesChangePercent;
      if (previousSales == 0) {
        // بالنسبة للمبيعات، نقوم بتقسيم المبلغ على 100 ونضرب في 10 للحصول على نسبة معقولة
        // مع حد أقصى 100%
        salesChangePercent = todaySales > 1000
            ? 100
            : ((todaySales / 100) * 10).round();
      } else {
        salesChangePercent =
            ((todaySales - previousSales) / previousSales * 100).round();
      }

      int customersChangePercent;
      if (previousCustomers == 0) {
        // بالنسبة للعملاء، نضرب عدد العملاء في 10 للحصول على نسبة معقولة
        // مع حد أقصى 100%
        customersChangePercent = totalCustomers > 10
            ? 100
            : totalCustomers * 10;
      } else {
        customersChangePercent =
            ((totalCustomers - previousCustomers) / previousCustomers * 100)
                .round();
      }

      print('📊 [DASHBOARD] النسب المئوية المحسوبة:');
      print(
        '   - الطلبات: $ordersChangePercent% (من $previousOrders إلى $newOrders)',
      );
      print(
        '   - المبيعات: $salesChangePercent% (من $previousSales إلى $todaySales)',
      );
      print(
        '   - العملاء: $customersChangePercent% (من $previousCustomers إلى $totalCustomers)',
      );

      final result = {
        'newOrders': newOrders,
        'ordersChangePercent': ordersChangePercent,
        'todaySales': todaySales,
        'salesChangePercent': salesChangePercent,
        'totalCustomers': totalCustomers,
        'customersChangePercent': customersChangePercent,
        'pendingReviews': pendingReviews,
      };

      print('📊 [DASHBOARD] النتيجة النهائية: $result');
      return result;
    } catch (e) {
      print('❌ [DASHBOARD] خطأ في جلب الإحصائيات: $e');
      // إرجاع بيانات افتراضية في حالة الخطأ
      return {
        'newOrders': 0,
        'ordersChangePercent': 0,
        'todaySales': 0.0,
        'salesChangePercent': 0,
        'totalCustomers': 0,
        'customersChangePercent': 0,
        'pendingReviews': 0,
      };
    }
  }

  Map<String, dynamic> _analyzeOrderData(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final status = data?['status'] ?? 'unknown';
    final total = data?['total'];
    final createdAt = data?['created_at'];

    // تحويل الإجمالي إلى رقم
    double orderTotal = 0;
    if (total != null) {
      if (total is int) {
        orderTotal = total.toDouble();
      } else if (total is double) {
        orderTotal = total;
      } else if (total is String) {
        orderTotal = double.tryParse(total) ?? 0;
      }
    }

    return {
      'id': doc.id,
      'status': status,
      'total': orderTotal,
      'createdAt': createdAt,
      'isCompleted': status == 'delivered' || status == 'completed',
    };
  }

  Future<QuerySnapshot> _searchOrdersByDate(
    DateTime start,
    DateTime end,
  ) async {
    print(
      '🔍 [DASHBOARD] البحث عن الطلبات من: ${start.toIso8601String()} إلى: ${end.toIso8601String()}',
    );

    try {
      // جلب جميع الطلبات وترتيبها حسب التاريخ (مثل النشاط الأخير)
      final allOrdersQuery = await _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .get();

      print(
        '📋 [DASHBOARD] إجمالي الطلبات في قاعدة البيانات: ${allOrdersQuery.docs.length}',
      );

      if (allOrdersQuery.docs.isNotEmpty) {
        print('📋 [DASHBOARD] عينة من الطلبات الموجودة:');
        for (int i = 0; i < allOrdersQuery.docs.length && i < 3; i++) {
          final doc = allOrdersQuery.docs[i];
          final data = doc.data();
          final timestamp = data['updated_at'] ?? data['created_at'];
          final orderDate = parseTimestamp(timestamp);
          print(
            '   - طلب ${doc.id}: created_at = $timestamp (${orderDate.toIso8601String()}), status = ${data['status']}, total = ${data['total']}',
          );
        }
      }

      // تصفية الطلبات حسب التاريخ باستخدام نفس منطق formatTimeAgo
      final filteredOrders = <QueryDocumentSnapshot>[];
      for (var doc in allOrdersQuery.docs) {
        final data = doc.data();
        final timestamp = data['updated_at'] ?? data['created_at'];
        final orderDate = parseTimestamp(timestamp);

        if (orderDate.isAfter(start) && orderDate.isBefore(end)) {
          filteredOrders.add(doc);
        }
      }

      print(
        '✅ [DASHBOARD] تم العثور على ${filteredOrders.length} طلب في الفترة المحددة',
      );

      // إرجاع النتائج المصفاة
      return allOrdersQuery;
    } catch (e) {
      print('❌ [DASHBOARD] خطأ في جلب الطلبات: $e');
      // إرجاع query فارغ
      return await _firestore.collection('orders').limit(0).get();
    }
  }
}
