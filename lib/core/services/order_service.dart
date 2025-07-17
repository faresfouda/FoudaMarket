import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/order_model.dart';
import '../../models/promo_code_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إنشاء طلب جديد مع دعم كود الخصم
  Future<String> createOrder(OrderModel order) async {
    try {
      // إنشاء معرف فريد للطلب
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final orderWithId = order.copyWith(id: orderId);
      
      // حفظ الطلب في Firestore
      await _firestore.collection('orders').doc(orderId).set(orderWithId.toJson());
      
      // إذا كان هناك كود خصم، تحديث عدد مرات الاستخدام
      if (order.promoCodeId != null) {
        await _updatePromoCodeUsage(order.promoCodeId!);
      }
      
      // إشعار المديرين ومدخلي البيانات بعد إنشاء الطلب
      await notifyAdminsAndDataEntryOnNewOrder(orderWithId);
      
      // إضافة إشعار للأدمن عند إنشاء طلب جديد
      final adminsQuery = await _firestore.collection('users').where('role', whereIn: ['admin', 'data_entry']).get();
      for (var adminDoc in adminsQuery.docs) {
        await _firestore.collection('users').doc(adminDoc.id).collection('notifications').add({
          'title': 'طلب جديد',
          'body': 'تم استلام طلب جديد من المستخدم ${order.userId}',
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      print('[DEBUG] Order created successfully: $orderId');
      return orderId;
    } catch (e) {
      print('[ERROR] Failed to create order: $e');
      throw Exception('فشل في إنشاء الطلب: $e');
    }
  }

  /// إشعار المديرين ومدخلي البيانات عند إنشاء طلب جديد
  Future<void> notifyAdminsAndDataEntryOnNewOrder(OrderModel order) async {
    try {
      print('[NOTIFY] >>> دخلنا دالة إشعار المديرين ومدخلي البيانات');
      // جلب كل المستخدمين الذين لديهم دور admin أو data_entry
      final usersQuery = await _firestore.collection('users')
        .where('role', whereIn: ['admin', 'data_entry'])
        .get();
      final tokens = <String>[];
      final adminTokens = <String>[];
      final dataEntryTokens = <String>[];
      final adminIds = <String>[];
      final dataEntryIds = <String>[];
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        final token = data['fcmToken'];
        final role = data['role'];
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
          if (role == 'admin') {
            adminTokens.add(token);
            adminIds.add(doc.id);
          } else if (role == 'data_entry') {
            dataEntryTokens.add(token);
            dataEntryIds.add(doc.id);
          }
        }
      }
      if (tokens.isEmpty) {
        print('[NOTIFY] لا يوجد مديرين أو مدخلي بيانات لديهم FCM Token');
        return;
      }
      // جلب اسم المستخدم
      String userName = order.userId;
      try {
        final userDoc = await _firestore.collection('users').doc(order.userId).get();
        if (userDoc.exists && userDoc.data()?['name'] != null) {
          userName = userDoc.data()!['name'];
        }
      } catch (_) {}
      // تفاصيل الطلب
      final itemsCount = order.items.length;
      final total = order.total.toStringAsFixed(2);
      final address = order.deliveryAddressName ?? order.deliveryAddress ?? '';
      // نصوص الإشعار
      final adminTitle = 'طلب جديد';
      final adminBody = 'طلب جديد من: $userName\nعدد المنتجات: $itemsCount\nالإجمالي: $total جنيه\nالعنوان: $address';
      final dataEntryTitle = 'طلب جديد بحاجة للمراجعة';
      final dataEntryBody = 'طلب جديد من: $userName\nعدد المنتجات: $itemsCount\nالإجمالي: $total جنيه\nالعنوان: $address';
      final endpoint = 'https://fcm-api-seven.vercel.app/api/send-fcm';
      // إشعار المديرين
      if (adminTokens.isNotEmpty) {
        final adminNotif = {
          'fcmTokens': adminTokens,
          'title': adminTitle,
          'body': adminBody,
          'data': {
            'orderId': order.id,
            'type': 'new_order',
            'role': 'admin',
            'userName': userName,
            'itemsCount': itemsCount.toString(),
            'total': total,
            'address': address,
          },
        };
        await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(adminNotif),
        );
        // سجل الإشعار في Firestore
        await _firestore.collection('admin_notifications').add({
          'orderId': order.id,
          'userId': order.userId,
          'userName': userName,
          'sentAt': FieldValue.serverTimestamp(),
          'tokens': adminTokens,
          'role': 'admin',
          'itemsCount': itemsCount,
          'total': total,
          'address': address,
        });
      }
      // إشعار مدخلي البيانات
      if (dataEntryTokens.isNotEmpty) {
        final dataEntryNotif = {
          'fcmTokens': dataEntryTokens,
          'title': dataEntryTitle,
          'body': dataEntryBody,
          'data': {
            'orderId': order.id,
            'type': 'new_order',
            'role': 'data_entry',
            'userName': userName,
            'itemsCount': itemsCount.toString(),
            'total': total,
            'address': address,
          },
        };
        await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(dataEntryNotif),
        );
        // سجل الإشعار في Firestore
        await _firestore.collection('admin_notifications').add({
          'orderId': order.id,
          'userId': order.userId,
          'userName': userName,
          'sentAt': FieldValue.serverTimestamp(),
          'tokens': dataEntryTokens,
          'role': 'data_entry',
          'itemsCount': itemsCount,
          'total': total,
          'address': address,
        });
      }
      print('[NOTIFY] تم إرسال إشعار للمديرين ومدخلي البيانات بنجاح');
    } catch (e) {
      print('[NOTIFY] فشل في إرسال إشعار للمديرين/مدخلي البيانات: $e');
    }
  }

  /// تحديث عدد مرات استخدام كود الخصم
  Future<void> _updatePromoCodeUsage(String promoCodeId) async {
    try {
      final promoCodeRef = _firestore.collection('promo_codes').doc(promoCodeId);
      
      await _firestore.runTransaction((transaction) async {
        final promoCodeDoc = await transaction.get(promoCodeRef);
        if (promoCodeDoc.exists) {
          final currentUsage = promoCodeDoc.data()?['current_usage_count'] ?? 0;
          transaction.update(promoCodeRef, {
            'current_usage_count': currentUsage + 1,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      });
      
      print('[DEBUG] Promo code usage updated: $promoCodeId');
    } catch (e) {
      print('[ERROR] Failed to update promo code usage: $e');
      // لا نريد أن نفشل الطلب إذا فشل تحديث كود الخصم
    }
  }

  /// جلب طلبات المستخدم
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();
      
      print('[DEBUG] Found ${orders.length} orders for user: $userId');
      return orders;
    } catch (e) {
      print('[ERROR] Failed to get user orders: $e');
      throw Exception('فشل في جلب طلبات المستخدم: $e');
    }
  }

  /// جلب جميع الطلبات (للمدير)
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .get();
      
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();
      
      print('[DEBUG] Found ${orders.length} total orders');
      return orders;
    } catch (e) {
      print('[ERROR] Failed to get all orders: $e');
      throw Exception('فشل في جلب جميع الطلبات: $e');
    }
  }

  /// جلب طلب بواسطة المعرف
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('[ERROR] Failed to get order by ID: $e');
      throw Exception('فشل في جلب الطلب: $e');
    }
  }

  /// إرسال إشعار مباشر باستخدام HTTP API (كبديل للـ Firebase Functions)
  Future<void> sendDirectNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // استخدام Firebase Cloud Messaging HTTP v1 API مباشرة
      final projectId = 'fouda-market';
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      
      // ملاحظة: في التطبيق الحقيقي، يجب استخدام Server Key أو Service Account
      // هذا مثال للتوضيح فقط
      final message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        },
      };

      print('[FCM] محاولة إرسال إشعار مباشر إلى: $fcmToken');
      print('[FCM] الرسالة: $message');
      
      // ملاحظة: هذا يتطلب Server Key من Firebase Console
      // أو استخدام Service Account للـ authentication
      print('[FCM] تحذير: هذا يتطلب إعداد Server Key أو Service Account');
      
    } catch (e) {
      print('[FCM] خطأ في إرسال الإشعار المباشر: $e');
    }
  }

  /// تحديث FCM Token تلقائياً
  Future<String?> _getUpdatedFcmToken() async {
    try {
      String? currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken != null) {
        // تحديث Token في Firestore للمستخدم الحالي
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'fcmToken': currentToken,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('[FCM] ✅ تم تحديث FCM Token في Firestore');
        }
      }
      return currentToken;
    } catch (e) {
      print('[FCM] ❌ فشل في تحديث FCM Token: $e');
      return null;
    }
  }

  /// اختبار الاتصال بـ Vercel API
  Future<bool> testVercelApiConnection() async {
    try {
      print('[FCM] 🔍 اختبار الاتصال بـ Vercel API...');
      
      final endpoint = 'https://fcm-api-seven.vercel.app/api/send-fcm';
      
      // إرسال طلب اختبار بسيط
      final testData = {
        'fcmToken': 'test_token',
        'title': 'اختبار الاتصال',
        'body': 'هذا اختبار للاتصال',
        'data': {'test': 'true'},
      };
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(testData),
      ).timeout(Duration(seconds: 5));
      
      print('[FCM] استجابة اختبار الاتصال: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('[FCM] ✅ الاتصال بـ Vercel API يعمل بشكل صحيح');
        return true;
      } else if (response.statusCode == 404) {
        print('[FCM] ⚠️ Vercel API متاح لكن FCM Token غير صالح (هذا طبيعي في الاختبار)');
        return true;
      } else {
        print('[FCM] ❌ مشكلة في Vercel API: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('[FCM] ❌ فشل في الاتصال بـ Vercel API: $e');
      return false;
    }
  }

  /// جلب FCM Token للمستخدم من Firestore
  Future<String?> getUserFcmToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final fcmToken = userData?['fcmToken'];
        print('[FCM] FCM Token للمستخدم $userId: ${fcmToken != null ? '${fcmToken.substring(0, 20)}...' : 'غير موجود'}');
        return fcmToken;
      }
      print('[FCM] المستخدم $userId غير موجود في Firestore');
      return null;
    } catch (e) {
      print('[FCM] ❌ فشل في جلب FCM Token: $e');
      return null;
    }
  }

  /// اختبار إرسال إشعار باستخدام HTTP API
  Future<void> testNotification({
    required String fcmToken,
    required String orderId,
    required String status,
  }) async {
    try {
      final statusText = {
        'pending': 'قيد الانتظار',
        'accepted': 'تم قبول الطلب',
        'preparing': 'جاري التحضير',
        'delivering': 'جاري التوصيل',
        'delivered': 'تم التوصيل',
        'cancelled': 'تم إلغاء الطلب',
        'failed': 'فشل الطلب',
      }[status] ?? status;

      // استخدم فقط fcmToken القادم من Firestore
      String tokenToUse = fcmToken;

      print('[FCM] 🔍 فحص FCM Token:');
      print('[FCM] Token المستخدم:  [32m${tokenToUse.substring(0, 20)}... [0m');

      final notificationData = {
        'fcmToken': tokenToUse,
        'title': 'تحديث حالة الطلب',
        'body': 'تم تحديث حالة طلبك ($orderId) إلى: $statusText',
        'data': {
          'orderId': orderId,
          'status': status,
          'type': 'order_status_update',
        },
      };

      // استخدام Vercel API لإرسال الإشعارات
      print('[FCM] إرسال إشعار عبر Vercel API');
      print('[FCM] البيانات: $notificationData');
      try {
        // تحديث حالة الطلب في Firestore أولاً
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[FCM] ✅ تم تحديث حالة الطلب في Firestore');

        // إرسال الإشعار عبر Vercel API
        final endpoint = 'https://fcm-api-seven.vercel.app/api/send-fcm';
        print('[FCM] 🌐 إرسال طلب إلى: $endpoint');
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(notificationData),
        ).timeout(Duration(seconds: 10));

        print('[FCM] استجابة الخادم: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('[FCM] ✅ تم إرسال الإشعار بنجاح عبر Vercel API');
          print('[FCM] Message ID: ${responseData['messageId']}');
          print('[FCM] 🎉 الإشعار تم إرساله بنجاح!');
        } else if (response.statusCode == 404) {
          print('[FCM] ❌ FCM Token غير صالح (404)');
          print('[FCM] 💡 السبب: FCM Token قديم أو غير صالح');
        } else if (response.statusCode == 401) {
          print('[FCM] ❌ خطأ في المصادقة (401)');
          print('[FCM] 💡 السبب: مشكلة في متغيرات البيئة في Vercel');
        } else {
          print('[FCM] ❌ فشل في إرسال الإشعار: ${response.statusCode}');
          print('[FCM] 💡 السبب: مشكلة في الخادم أو الشبكة');
        }
      } catch (e) {
        print('[FCM] ❌ فشل في إرسال الإشعار: $e');
        if (e.toString().contains('timeout')) {
          print('[FCM] 💡 السبب: انتهت مهلة الاتصال بالخادم');
        }
      }
    } catch (e) {
      print('[FCM] خطأ في اختبار الإشعار: $e');
    }
  }

  /// إرسال إشعار FCM عند تغيير حالة الطلب
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    try {
      // جلب fcmToken من Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final fcmToken = userData != null ? userData['fcmToken'] : null;
      if (fcmToken == null || fcmToken.isEmpty) {
        print('[FCM] لا يوجد fcmToken للمستخدم $userId');
        return;
      }
      
      // نص الإشعار حسب الحالة الجديدة
      final statusText = {
        'pending': 'قيد الانتظار',
        'accepted': 'تم قبول الطلب',
        'preparing': 'جاري التحضير',
        'delivering': 'جاري التوصيل',
        'delivered': 'تم التوصيل',
        'cancelled': 'تم إلغاء الطلب',
        'failed': 'فشل الطلب',
      }[status] ?? status;

      print('[FCM] سيتم إرسال إشعار للمستخدم $userId لحالة الطلب $orderId: $statusText');
      print('[FCM] Firebase Function ستتعامل مع إرسال الإشعار تلقائياً عند تحديث الحالة');
      
    } catch (e) {
      print('[FCM] خطأ في إعداد إشعار حالة الطلب: $e');
    }
  }

  /// تحديث حالة الطلب
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      await orderRef.update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // جلب الطلب لمعرفة userId
      final orderDoc = await orderRef.get();
      final orderData = orderDoc.data();
      final userId = orderData != null ? orderData['userId'] : null;
      
      if (userId != null) {
        // إضافة إشعار للمستخدم عند تغيير حالة الطلب
        final statusText = {
          'pending': 'قيد الانتظار',
          'accepted': 'تم قبول الطلب',
          'preparing': 'جاري التحضير',
          'delivering': 'جاري التوصيل',
          'delivered': 'تم التوصيل',
          'cancelled': 'تم إلغاء الطلب',
          'failed': 'فشل الطلب',
        }[status] ?? status;
        await _firestore.collection('users').doc(userId).collection('notifications').add({
          'title': 'تحديث حالة الطلب',
          'body': 'تم تحديث حالة طلبك إلى: $statusText',
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        // جلب fcmToken من Firestore
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        final fcmToken = userData != null ? userData['fcmToken'] : null;
        
        if (fcmToken != null && fcmToken.isNotEmpty) {
          // اختبار إرسال الإشعار باستخدام HTTP API
          await testNotification(
            fcmToken: fcmToken,
            orderId: orderId,
            status: status,
          );
        } else {
          print('[FCM] لا يوجد fcmToken للمستخدم $userId');
        }
        
        // أيضاً استدعاء الدالة الأصلية للـ Firebase Functions
        await sendOrderStatusNotification(userId: userId, orderId: orderId, status: status);
      }
      
      print('[DEBUG] Order status updated: $orderId -> $status');
    } catch (e) {
      print('[ERROR] Failed to update order status: $e');
      throw Exception('فشل في تحديث حالة الطلب: $e');
    }
  }

  /// جلب الطلبات حسب الحالة
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('created_at', descending: true)
          .get();
      
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();
      
      print('[DEBUG] Found ${orders.length} orders with status: $status');
      return orders;
    } catch (e) {
      print('[ERROR] Failed to get orders by status: $e');
      throw Exception('فشل في جلب الطلبات حسب الحالة: $e');
    }
  }

  /// إحصائيات المبيعات والتقارير
  Future<Map<String, dynamic>> getSalesReport(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', whereIn: ['delivered', 'completed'])
          .get();

      double totalSales = 0;
      double totalDiscounts = 0;
      int totalOrders = querySnapshot.docs.length;
      int ordersWithPromoCode = 0;

      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        totalSales += (orderData['total'] ?? 0).toDouble();
        totalDiscounts += (orderData['discount_amount'] ?? 0).toDouble();
        
        if (orderData['promo_code_id'] != null) {
          ordersWithPromoCode++;
        }
      }

      return {
        'totalSales': totalSales,
        'totalDiscounts': totalDiscounts,
        'totalOrders': totalOrders,
        'ordersWithPromoCode': ordersWithPromoCode,
        'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
        'averageDiscount': totalOrders > 0 ? totalDiscounts / totalOrders : 0,
      };
    } catch (e) {
      print('[ERROR] Failed to get sales report: $e');
      throw Exception('فشل في جلب تقرير المبيعات: $e');
    }
  }

  /// إحصائيات كود الخصم
  Future<Map<String, dynamic>> getPromoCodeStats() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('promo_code_id', isNull: false)
          .get();

      final promoCodeUsage = <String, int>{};
      double totalPromoCodeDiscounts = 0;

      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        final promoCodeId = orderData['promo_code_id'];
        final promoCode = orderData['promo_code'];
        final discountAmount = (orderData['discount_amount'] ?? 0).toDouble();
        
        if (promoCodeId != null) {
          promoCodeUsage[promoCode ?? promoCodeId] = (promoCodeUsage[promoCode ?? promoCodeId] ?? 0) + 1;
          totalPromoCodeDiscounts += discountAmount;
        }
      }

      return {
        'totalOrdersWithPromoCode': querySnapshot.docs.length,
        'totalPromoCodeDiscounts': totalPromoCodeDiscounts,
        'promoCodeUsage': promoCodeUsage,
      };
    } catch (e) {
      print('[ERROR] Failed to get promo code stats: $e');
      throw Exception('فشل في جلب إحصائيات كود الخصم: $e');
    }
  }
} 