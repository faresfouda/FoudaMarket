import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'helpers.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // جلب المنتجات المضافة/المعدلة حديثاً
      var productsQuery = _firestore
          .collection('products')
          .orderBy('updated_at', descending: true)
          .limit(limit);

      if (lastTimestamp != null && lastType == 'product') {
        productsQuery = productsQuery.startAfter([lastTimestamp]);
      }

      final recentProductsQuery = await productsQuery.get();

      for (var doc in recentProductsQuery.docs) {
        final data = doc.data();
        final displayTimestamp = data['updated_at'] ?? data['created_at'];
        final sortTimestamp = data['updated_at'] ?? data['created_at'];
        final isNew = data['created_at'] == data['updated_at'];

        activities.add({
          'id': doc.id,
          'type': 'product',
          'icon': isNew ? Icons.add_circle : Icons.edit,
          'iconColor': isNew ? Colors.green : Colors.orange,
          'text': isNew ? 'تمت إضافة منتج جديد' : 'تم تحديث منتج',
          'details': '${data['name']} - ${data['price']} ج.م',
          'time': formatTimeAgo(displayTimestamp),
          'timestamp': sortTimestamp,
          'productId': doc.id,
          'productName': data['name'],
          'productPrice': data['price'],
          'productImage': data['image'],
          'isNewProduct': isNew,
          'updatedBy': data['updated_by'] ?? data['admin_name'],
        });

        lastActivityTimestamp = sortTimestamp;
        lastActivityId = doc.id;
        lastActivityType = 'product';
      }

      // جلب العملاء الجدد
      var usersQuery = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastTimestamp != null && lastType == 'user') {
        usersQuery = usersQuery.startAfter([lastTimestamp]);
      }

      final recentUsersQuery = await usersQuery.get();

      for (var doc in recentUsersQuery.docs) {
        final data = doc.data();
        final displayTimestamp = data['createdAt'];
        final sortTimestamp = data['createdAt'];

        activities.add({
          'id': doc.id,
          'type': 'user',
          'icon': Icons.person_add,
          'iconColor': Colors.blue,
          'text': 'عميل جديد',
          'details': data['name'] ?? 'مستخدم جديد',
          'time': formatTimeAgo(displayTimestamp),
          'timestamp': sortTimestamp,
          'userId': doc.id,
          'userName': data['name'],
        });

        lastActivityTimestamp = sortTimestamp;
        lastActivityId = doc.id;
        lastActivityType = 'user';
      }

      // جلب الطلبات الأخيرة
      var ordersQuery = _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastTimestamp != null && lastType == 'order') {
        ordersQuery = ordersQuery.startAfter([lastTimestamp]);
      }

      final recentOrdersQuery = await ordersQuery.get();

      print('[DEBUG] Found ${recentOrdersQuery.docs.length} orders');

      for (var doc in recentOrdersQuery.docs) {
        final data = doc.data();
        final displayTimestamp = data['updated_at'] ?? data['created_at'];
        final sortTimestamp = data['updated_at'] ?? data['created_at'];

        print(
          '[DEBUG] Order ${doc.id}: status=${data['status']}, created_at=${data['created_at']}, updated_at=${data['updated_at']}',
        );

        activities.add({
          'id': doc.id,
          'type': 'order',
          'icon': _getOrderIcon(data['status']),
          'iconColor': _getOrderColor(data['status']),
          'text': _getOrderText(data['status']),
          'details':
              'طلب رقم ${doc.id.substring(0, 8)} - ${data['customer_name'] ?? data['delivery_address_name'] ?? 'مستخدم'}',
          'time': formatTimeAgo(displayTimestamp),
          'timestamp': sortTimestamp,
          'orderId': doc.id,
          'orderStatus': data['status'],
          'orderTotal': data['total'] ?? 0,
          'userName':
              data['customer_name'] ??
              data['delivery_address_name'] ??
              'مستخدم',
          'userPhone': data['customer_phone'] ?? data['delivery_phone'] ?? '',
          'updatedBy': data['updated_by'] ?? data['admin_name'],
          'updatedAt': data['updated_at'],
        });

        lastActivityTimestamp = sortTimestamp;
        lastActivityId = doc.id;
        lastActivityType = 'order';
      }

      // جلب المراجعات الأخيرة
      var reviewsQuery = _firestore
          .collection('reviews')
          .orderBy('updated_at', descending: true)
          .limit(limit);

      if (lastTimestamp != null && lastType == 'review') {
        reviewsQuery = reviewsQuery.startAfter([lastTimestamp]);
      }

      final recentReviewsQuery = await reviewsQuery.get();

      for (var doc in recentReviewsQuery.docs) {
        final data = doc.data();
        final displayTimestamp = data['updated_at'] ?? data['created_at'];
        final sortTimestamp = data['updated_at'] ?? data['created_at'];

        activities.add({
          'id': doc.id,
          'type': 'review',
          'icon': _getReviewIcon(data['status']),
          'iconColor': _getReviewColor(data['status']),
          'text': _getReviewText(data['status']),
          'details':
              '${data['user_name'] ?? 'مستخدم'} - ${data['product_name'] ?? 'منتج'}',
          'time': formatTimeAgo(displayTimestamp),
          'timestamp': sortTimestamp,
          'reviewId': doc.id,
          'reviewStatus': data['status'],
          'reviewRating': data['rating'] ?? 0,
          'reviewText': data['review_text'] ?? '',
          'userName': data['user_name'] ?? 'مستخدم',
          'productName': data['product_name'] ?? 'منتج',
          'productImage': data['product_image'] ?? '',
          'updatedBy': data['updated_by'] ?? data['admin_name'],
        });

        lastActivityTimestamp = sortTimestamp;
        lastActivityId = doc.id;
        lastActivityType = 'review';
      }

      print('[DEBUG] Total activities before sorting: ${activities.length}');
      print(
        '[DEBUG] Activities by type: ${activities.map((a) => a['type']).toList()}',
      );

      // ترتيب النشاطات حسب وقت التحديث أو الإنشاء
      activities.sort((a, b) {
        final timestampA = a['timestamp'];
        final timestampB = b['timestamp'];

        DateTime dateA = parseTimestamp(timestampA);
        DateTime dateB = parseTimestamp(timestampB);

        // أولاً نقارن حسب وقت التحديث
        final comparison = dateB.compareTo(dateA);
        if (comparison != 0) return comparison;

        // إذا كان وقت التحديث متساوياً، نقارن حسب نوع النشاط
        // الترتيب: الطلبات، المراجعات، المنتجات، المستخدمين
        final typeOrder = {'order': 0, 'review': 1, 'product': 2, 'user': 3};
        final typeA = typeOrder[a['type']] ?? 4;
        final typeB = typeOrder[b['type']] ?? 4;
        return typeA.compareTo(typeB);
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

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final result = await getRecentActivityPaginated(limit: limit);
    final activities = result['activities'] as List<Map<String, dynamic>>;
    print(
      '[DEBUG] ActivityService.getRecentActivity: returning ${activities.length} activities',
    );
    print(
      '[DEBUG] Activity types: ${activities.map((a) => a['type']).toList()}',
    );
    return activities;
  }

  // Helper methods
  IconData _getOrderIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.timelapse;
      case 'delivering':
        return Icons.local_shipping;
      case 'delivered':
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.shopping_cart;
    }
  }

  Color _getOrderColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.amber;
      case 'delivering':
        return Colors.teal;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getOrderText(String? status) {
    switch (status) {
      case 'pending':
        return 'طلب جديد';
      case 'accepted':
        return 'تم قبول الطلب';
      case 'preparing':
        return 'جاري تحضير الطلب';
      case 'delivering':
        return 'جاري توصيل الطلب';
      case 'delivered':
      case 'completed':
        return 'تم تسليم الطلب';
      case 'cancelled':
        return 'تم إلغاء الطلب';
      case 'failed':
        return 'فشل الطلب';
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
}
