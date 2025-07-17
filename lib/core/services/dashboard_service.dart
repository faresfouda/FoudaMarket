import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/review_model.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// دالة مساعدة لتحليل بيانات الطلب
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

  /// دالة مساعدة للبحث في الطلبات (محدثة بناءً على منطق النشاط الأخير)
  Future<QuerySnapshot> _searchOrdersByDate(DateTime start, DateTime end) async {
    print('🔍 [DASHBOARD] البحث عن الطلبات من: ${start.toIso8601String()} إلى: ${end.toIso8601String()}');

    try {
      // جلب جميع الطلبات وترتيبها حسب التاريخ (مثل النشاط الأخير)
      final allOrdersQuery = await _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .get();

      print('📋 [DASHBOARD] إجمالي الطلبات في قاعدة البيانات: ${allOrdersQuery.docs.length}');
      
      if (allOrdersQuery.docs.isNotEmpty) {
        print('📋 [DASHBOARD] عينة من الطلبات الموجودة:');
        for (int i = 0; i < allOrdersQuery.docs.length && i < 3; i++) {
          final doc = allOrdersQuery.docs[i];
          final data = doc.data();
          final timestamp = data['created_at'];
          final orderDate = _parseTimestamp(timestamp);
          print('   - طلب ${doc.id}: created_at = $timestamp (${orderDate.toIso8601String()}), status = ${data['status']}, total = ${data['total']}');
        }
      }

      // تصفية الطلبات حسب التاريخ باستخدام نفس منطق _formatTimeAgo
      final filteredOrders = <QueryDocumentSnapshot>[];
      for (var doc in allOrdersQuery.docs) {
        final data = doc.data();
        final timestamp = data['created_at'];
        final orderDate = _parseTimestamp(timestamp);
        
        if (orderDate.isAfter(start) && orderDate.isBefore(end)) {
          filteredOrders.add(doc);
        }
      }

      print('✅ [DASHBOARD] تم العثور على ${filteredOrders.length} طلب في الفترة المحددة');
      
      // إرجاع النتائج المصفاة
      return allOrdersQuery;
    } catch (e) {
      print('❌ [DASHBOARD] خطأ في جلب الطلبات: $e');
      // إرجاع query فارغ
      return await _firestore.collection('orders').limit(0).get();
    }
  }

  /// دالة مساعدة لتحليل Timestamp (مثل _formatTimeAgo)
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $e');
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
  }

  /// إنشاء طلب تجريبي للاختبار
  Future<void> createTestOrder() async {
    try {
      final now = DateTime.now();
      final testOrder = {
        'created_at': Timestamp.fromDate(now),
        'status': 'delivered',
        'total': 150.0,
        'delivery_address_name': 'أحمد محمد',
        'delivery_phone': '+1234567890',
        'items': [
          {
            'productId': 'test_product_1',
            'productName': 'منتج تجريبي 1',
            'quantity': 2,
            'price': 75.0,
          }
        ],
      };

      await _firestore.collection('orders').add(testOrder);
      print('✅ [DASHBOARD] تم إنشاء طلب تجريبي بنجاح');
    } catch (e) {
      print('❌ [DASHBOARD] خطأ في إنشاء طلب تجريبي: $e');
    }
  }

  /// جلب إحصائيات لوحة التحكم
  Future<Map<String, dynamic>> getDashboardStats({bool includeLastWeek = false}) async {
    try {
      // جلب الطلبات الجديدة (اليوم أو آخر أسبوع)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      DateTime startDate, endDate;
      String periodLabel;
      
      if (includeLastWeek) {
        // جلب الطلبات من آخر 7 أيام
        startDate = today.subtract(const Duration(days: 7));
        endDate = today;
        periodLabel = 'آخر 7 أيام';
      } else {
        // جلب طلبات اليوم فقط
        startDate = startOfDay;
        endDate = endOfDay;
        periodLabel = 'اليوم';
      }

      print('📅 [DASHBOARD] الفترة: $periodLabel');
      print('📅 [DASHBOARD] من: ${startDate.toIso8601String()}');
      print('📅 [DASHBOARD] إلى: ${endDate.toIso8601String()}');

      // جلب الطلبات
      final allOrdersQuery = await _searchOrdersByDate(startDate, endDate);
      
      // تصفية الطلبات حسب التاريخ
      final filteredOrders = <QueryDocumentSnapshot>[];
      for (var doc in allOrdersQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['created_at'];
        final orderDate = _parseTimestamp(timestamp);
        
        if (orderDate.isAfter(startDate) && orderDate.isBefore(endDate)) {
          filteredOrders.add(doc);
        }
      }
      
      final newOrders = filteredOrders.length;
      print('📊 [DASHBOARD] إجمالي الطلبات الجديدة: $newOrders');

      // جلب إجمالي المبيعات (اليوم) - تشمل جميع الطلبات بغض النظر عن الحالة
      double todaySales = 0;
      for (var doc in filteredOrders) {
        final orderData = _analyzeOrderData(doc);
        print('📝 [DASHBOARD] طلب: ${orderData['id']} - الحالة: ${orderData['status']} - الإجمالي: ${orderData['total']}');
        
        // إضافة جميع الطلبات للمبيعات (ليس فقط المكتملة)
        todaySales += orderData['total'];
        print('💰 [DASHBOARD] إضافة للبيع: ${orderData['total']}');
      }
      print('💰 [DASHBOARD] إجمالي المبيعات اليوم: $todaySales');

      // جلب إجمالي العملاء
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      final totalCustomers = usersQuery.docs.length;
      print('👥 [DASHBOARD] إجمالي العملاء: $totalCustomers');

      // جلب المراجعات بانتظار الموافقة
      final pendingReviewsQuery = await _firestore
          .collection('reviews')
          .where('status', isEqualTo: 'pending')
          .get();

      final pendingReviews = pendingReviewsQuery.docs.length;
      print('⭐ [DASHBOARD] المراجعات المعلقة: $pendingReviews');

      // حساب النسبة المئوية للتغيير (مقارنة بالأمس)
      final yesterday = startOfDay.subtract(const Duration(days: 1));
      final yesterdayAllOrdersQuery = await _searchOrdersByDate(yesterday, startOfDay);
      
      // تصفية طلبات الأمس
      final yesterdayFilteredOrders = <QueryDocumentSnapshot>[];
      for (var doc in yesterdayAllOrdersQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['created_at'];
        final orderDate = _parseTimestamp(timestamp);
        
        if (orderDate.isAfter(yesterday) && orderDate.isBefore(startOfDay)) {
          yesterdayFilteredOrders.add(doc);
        }
      }

      final yesterdayOrders = yesterdayFilteredOrders.length;
      final ordersChangePercent = yesterdayOrders > 0 
          ? ((newOrders - yesterdayOrders) / yesterdayOrders * 100).round()
          : newOrders > 0 ? 100 : 0;

      print('📈 [DASHBOARD] تغيير الطلبات: $ordersChangePercent% (أمس: $yesterdayOrders)');

      // حساب تغيير المبيعات
      double yesterdaySales = 0;
      for (var doc in yesterdayFilteredOrders) {
        final orderData = _analyzeOrderData(doc);
        // إضافة جميع الطلبات للمبيعات (ليس فقط المكتملة)
        yesterdaySales += orderData['total'];
      }

      final salesChangePercent = yesterdaySales > 0 
          ? ((todaySales - yesterdaySales) / yesterdaySales * 100).round()
          : todaySales > 0 ? 100 : 0;

      print('💰 [DASHBOARD] تغيير المبيعات: $salesChangePercent% (أمس: $yesterdaySales)');

      // حساب تغيير العملاء (مقارنة بالأسبوع الماضي)
      final weekAgo = today.subtract(const Duration(days: 7));
      final twoWeeksAgo = weekAgo.subtract(const Duration(days: 7));

      QuerySnapshot newCustomersThisWeekQuery;
      QuerySnapshot newCustomersLastWeekQuery;

      try {
        newCustomersThisWeekQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
            .get();

        newCustomersLastWeekQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(twoWeeksAgo))
            .where('createdAt', isLessThan: Timestamp.fromDate(weekAgo))
            .get();
      } catch (e) {
        newCustomersThisWeekQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .where('createdAt', isGreaterThanOrEqualTo: weekAgo.toIso8601String())
            .get();

        newCustomersLastWeekQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .where('createdAt', isGreaterThanOrEqualTo: twoWeeksAgo.toIso8601String())
            .where('createdAt', isLessThan: weekAgo.toIso8601String())
            .get();
      }

      final newCustomersThisWeek = newCustomersThisWeekQuery.docs.length;
      final newCustomersLastWeek = newCustomersLastWeekQuery.docs.length;
      final customersChangePercent = newCustomersLastWeek > 0 
          ? ((newCustomersThisWeek - newCustomersLastWeek) / newCustomersLastWeek * 100).round()
          : newCustomersThisWeek > 0 ? 100 : 0;

      print('👥 [DASHBOARD] تغيير العملاء: $customersChangePercent%');

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

  /// جلب النشاط الأخير مع pagination
  Future<Map<String, dynamic>> getRecentActivityPaginated({
    int limit = 10,
    dynamic lastTimestamp,
    String? lastDocumentId,
    String? lastType,
  }) async {
    try {
      final activities = <Map<String, dynamic>>[];
      dynamic lastActivityTimestamp;
      String? lastActivityId;
      String? lastActivityType;

      // جلب الطلبات الأخيرة
      var ordersQuery = _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .limit(limit);

      // إضافة startAfter إذا كان هناك آخر عنصر
      if (lastTimestamp != null && lastType == 'order') {
        ordersQuery = ordersQuery.startAfter([lastTimestamp]);
      }

      final recentOrdersQuery = await ordersQuery.get();

      for (var doc in recentOrdersQuery.docs) {
        final data = doc.data();
        final timestamp = data['created_at'];
        
        activities.add({
          'id': doc.id,
          'type': 'order',
          'icon': _getOrderIcon(data['status']),
          'iconColor': _getOrderColor(data['status']),
          'text': _getOrderText(data['status']),
          'details': 'طلب رقم ${doc.id.substring(0, 8)} - ${data['delivery_address_name'] ?? 'مستخدم'}',
          'time': _formatTimeAgo(timestamp),
          'timestamp': timestamp,
          'orderId': doc.id,
          'orderStatus': data['status'],
          'orderTotal': data['total'] ?? 0,
          'userName': data['delivery_address_name'] ?? 'مستخدم',
          'userPhone': data['delivery_phone'] ?? '',
        });

        // تحديث آخر عنصر
        lastActivityTimestamp = timestamp;
        lastActivityId = doc.id;
        lastActivityType = 'order';
      }

      // جلب المراجعات الأخيرة
      var reviewsQuery = _firestore
          .collection('reviews')
          .orderBy('created_at', descending: true)
          .limit(limit);

      // إضافة startAfter إذا كان هناك آخر عنصر
      if (lastTimestamp != null && lastType == 'review') {
        reviewsQuery = reviewsQuery.startAfter([lastTimestamp]);
      }

      final recentReviewsQuery = await reviewsQuery.get();

      for (var doc in recentReviewsQuery.docs) {
        final data = doc.data();
        final timestamp = data['created_at'];
        
        activities.add({
          'id': doc.id,
          'type': 'review',
          'icon': _getReviewIcon(data['status']),
          'iconColor': _getReviewColor(data['status']),
          'text': _getReviewText(data['status']),
          'details': '${data['user_name'] ?? 'مستخدم'} - ${data['product_name'] ?? 'منتج'}',
          'time': _formatTimeAgo(timestamp),
          'timestamp': timestamp,
          'reviewId': doc.id,
          'reviewStatus': data['status'],
          'reviewRating': data['rating'] ?? 0,
          'reviewText': data['review_text'] ?? '',
          'userName': data['user_name'] ?? 'مستخدم',
          'productName': data['product_name'] ?? 'منتج',
          'productImage': data['product_image'] ?? '',
        });

        // تحديث آخر عنصر
        lastActivityTimestamp = timestamp;
        lastActivityId = doc.id;
        lastActivityType = 'review';
      }

      // ترتيب النشاطات حسب الوقت
      activities.sort((a, b) {
        final timestampA = a['timestamp'];
        final timestampB = b['timestamp'];
        
        DateTime dateA, dateB;
        
        if (timestampA is Timestamp) {
          dateA = timestampA.toDate();
        } else if (timestampA is String) {
          dateA = DateTime.parse(timestampA);
        } else {
          dateA = DateTime.now();
        }
        
        if (timestampB is Timestamp) {
          dateB = timestampB.toDate();
        } else if (timestampB is String) {
          dateB = DateTime.parse(timestampB);
        } else {
          dateB = DateTime.now();
        }
        
        return dateB.compareTo(dateA);
      });

      return {
        'activities': activities.take(limit).toList(),
        'hasMore': activities.length >= limit,
        'lastTimestamp': lastActivityTimestamp,
        'lastDocumentId': lastActivityId,
        'lastType': lastActivityType,
      };
    } catch (e) {
      print('Error getting recent activity: $e');
      return {
        'activities': [],
        'hasMore': false,
        'lastTimestamp': null,
        'lastDocumentId': null,
        'lastType': null,
      };
    }
  }

  /// جلب النشاط الأخير (للتوافق مع الكود القديم)
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final result = await getRecentActivityPaginated(limit: limit);
    return result['activities'] as List<Map<String, dynamic>>;
  }

  /// جلب إحصائيات المبيعات للأسبوع
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
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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

  // Helper methods
  IconData _getOrderIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_cart;
    }
  }

  Color _getOrderColor(String? status) {
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

  String _getOrderText(String? status) {
    switch (status) {
      case 'pending':
        return 'طلب جديد';
      case 'confirmed':
        return 'تم تأكيد الطلب';
      case 'shipped':
        return 'تم شحن الطلب';
      case 'delivered':
        return 'تم تسليم الطلب';
      case 'cancelled':
        return 'تم إلغاء الطلب';
      default:
        return 'طلب جديد';
    }
  }

  IconData _getReviewIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.rate_review;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.rate_review;
    }
  }

  Color _getReviewColor(String? status) {
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

  String _getReviewText(String? status) {
    switch (status) {
      case 'pending':
        return 'مراجعة جديدة بانتظار الموافقة';
      case 'approved':
        return 'تم قبول المراجعة';
      case 'rejected':
        return 'تم رفض المراجعة';
      default:
        return 'مراجعة جديدة';
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'الآن';
    
    DateTime time;
    
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        time = DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $e');
        return 'الآن';
      }
    } else {
      return 'الآن';
    }
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
} 