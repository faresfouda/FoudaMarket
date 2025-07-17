import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/promo_code_model.dart';

class PromoCodeService {
  static final PromoCodeService _instance = PromoCodeService._internal();
  factory PromoCodeService() => _instance;
  PromoCodeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // التحقق من صلاحيات المدير
  Future<bool> _isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data()!;
      return userData['role'] == 'admin';
    } catch (e) {
      print('Error checking admin permissions: $e');
      return false;
    }
  }

  // إنشاء كود خصم جديد
  Future<void> createPromoCode(PromoCodeModel promoCode) async {
    try {
      // التحقق من صلاحيات المدير
      final isAdmin = await _isAdmin();
      if (!isAdmin) {
        throw Exception('غير مصرح لك بإنشاء أكواد الخصم. يجب أن تكون مديراً.');
      }

      // التحقق من عدم وجود كود بنفس الاسم
      final existingCode = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: promoCode.code.toUpperCase())
          .get();
      
      if (existingCode.docs.isNotEmpty) {
        throw Exception('كود الخصم موجود مسبقاً');
      }

      await _firestore.collection('promo_codes').doc(promoCode.id).set(promoCode.toJson());
    } catch (e) {
      print('Error creating promo code: $e');
      rethrow;
    }
  }

  // جلب جميع أكواد الخصم
  Future<List<PromoCodeModel>> getAllPromoCodes() async {
    print('[DEBUG] Fetching promo codes from Firestore...');
    try {
      final snapshot = await _firestore.collection('promo_codes').get();
      print('[DEBUG] Firestore returned ${snapshot.docs.length} promo codes');
      
      final codes = <PromoCodeModel>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          print('[DEBUG] Promo code data: $data');
          final promoCode = PromoCodeModel.fromJson(data);
          codes.add(promoCode);
        } catch (e) {
          print('[DEBUG] Error parsing promo code ${doc.id}: $e');
          // تجاهل الأكواد التي لا يمكن تحليلها
          continue;
        }
      }
      return codes;
    } catch (e) {
      print('[DEBUG] Error loading promo codes: $e');
      return [];
    }
  }

  // جلب أكواد الخصم الصالحة للمستخدمين (مفعلة وغير منتهية الصلاحية)
  Future<List<PromoCodeModel>> getValidPromoCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection('promo_codes')
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();
      
      final now = DateTime.now();
      final validCodes = <PromoCodeModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final promoCode = PromoCodeModel.fromJson(data);
          
          // فلترة الأكواد غير المنتهية الصلاحية والتي لم تصل للحد الأقصى للاستخدام
          if (promoCode.expiryDate.isAfter(now) && 
              promoCode.currentUsageCount < promoCode.maxUsageCount) {
            validCodes.add(promoCode);
          }
        } catch (e) {
          print('Error parsing valid promo code ${doc.id}: $e');
          continue;
        }
      }
      
      return validCodes;
    } catch (e) {
      print('Error getting valid promo codes: $e');
      return [];
    }
  }

  // جلب كود خصم بواسطة الكود
  Future<PromoCodeModel?> getPromoCodeByCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        try {
          final data = querySnapshot.docs.first.data();
          data['id'] = querySnapshot.docs.first.id;
          return PromoCodeModel.fromJson(data);
        } catch (e) {
          print('Error parsing promo code by code: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting promo code by code: $e');
      return null;
    }
  }

  // تحديث كود الخصم
  Future<void> updatePromoCode(String promoCodeId, Map<String, dynamic> data) async {
    try {
      // التحقق من صلاحيات المدير
      final isAdmin = await _isAdmin();
      if (!isAdmin) {
        throw Exception('غير مصرح لك بتحديث أكواد الخصم. يجب أن تكون مديراً.');
      }

      await _firestore.collection('promo_codes').doc(promoCodeId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating promo code: $e');
      rethrow;
    }
  }

  // حذف كود الخصم
  Future<void> deletePromoCode(String promoCodeId) async {
    try {
      // التحقق من صلاحيات المدير
      final isAdmin = await _isAdmin();
      if (!isAdmin) {
        throw Exception('غير مصرح لك بحذف أكواد الخصم. يجب أن تكون مديراً.');
      }

      await _firestore.collection('promo_codes').doc(promoCodeId).delete();
    } catch (e) {
      print('Error deleting promo code: $e');
      rethrow;
    }
  }

  // تفعيل/إلغاء تفعيل كود الخصم
  Future<void> togglePromoCodeStatus(String promoCodeId, bool isActive) async {
    try {
      // التحقق من صلاحيات المدير
      final isAdmin = await _isAdmin();
      if (!isAdmin) {
        throw Exception('غير مصرح لك بتفعيل/إلغاء تفعيل أكواد الخصم. يجب أن تكون مديراً.');
      }

      await _firestore.collection('promo_codes').doc(promoCodeId).update({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling promo code status: $e');
      rethrow;
    }
  }

  // زيادة عدد مرات الاستخدام
  Future<void> incrementUsageCount(String promoCodeId) async {
    try {
      await _firestore.collection('promo_codes').doc(promoCodeId).update({
        'current_usage_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing usage count: $e');
      rethrow;
    }
  }

  // التحقق من صحة كود الخصم
  Future<Map<String, dynamic>> validatePromoCode(String code, double orderAmount) async {
    try {
      final promoCode = await getPromoCodeByCode(code);
      
      if (promoCode == null) {
        return {
          'isValid': false,
          'message': 'كود الخصم غير موجود',
          'promoCode': null,
        };
      }

      if (!promoCode.isActive) {
        return {
          'isValid': false,
          'message': 'كود الخصم غير مفعل',
          'promoCode': promoCode,
        };
      }

      if (promoCode.isExpired) {
        return {
          'isValid': false,
          'message': 'كود الخصم منتهي الصلاحية',
          'promoCode': promoCode,
        };
      }

      if (promoCode.isUsageLimitReached) {
        return {
          'isValid': false,
          'message': 'تم استنفاذ عدد مرات استخدام كود الخصم',
          'promoCode': promoCode,
        };
      }

      if (promoCode.minOrderAmount != null && orderAmount < promoCode.minOrderAmount!) {
        return {
          'isValid': false,
          'message': 'الحد الأدنى للطلب ${promoCode.minOrderAmount!.toStringAsFixed(2)} جنيه',
          'promoCode': promoCode,
        };
      }

      // حساب قيمة الخصم
      double discountAmount = (orderAmount * promoCode.discountPercentage) / 100;
      
      if (promoCode.maxDiscountAmount != null && discountAmount > promoCode.maxDiscountAmount!) {
        discountAmount = promoCode.maxDiscountAmount!;
      }

      return {
        'isValid': true,
        'message': 'كود الخصم صالح',
        'promoCode': promoCode,
        'discountAmount': discountAmount,
      };
    } catch (e) {
      print('Error validating promo code: $e');
      return {
        'isValid': false,
        'message': 'خطأ في التحقق من كود الخصم',
        'promoCode': null,
      };
    }
  }

  // جلب إحصائيات أكواد الخصم
  Future<Map<String, dynamic>> getPromoCodeStats() async {
    try {
      final querySnapshot = await _firestore.collection('promo_codes').get();
      
      int totalCodes = querySnapshot.docs.length;
      int activeCodes = 0;
      int expiredCodes = 0;
      int usageLimitReached = 0;
      int totalUsage = 0;

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final promoCode = PromoCodeModel.fromJson(data);
          
          if (promoCode.isActive) activeCodes++;
          if (promoCode.isExpired) expiredCodes++;
          if (promoCode.isUsageLimitReached) usageLimitReached++;
          totalUsage += promoCode.currentUsageCount;
        } catch (e) {
          print('Error parsing promo code ${doc.id}: $e');
          // تجاهل الأكواد التي لا يمكن تحليلها
          continue;
        }
      }

      return {
        'totalCodes': totalCodes,
        'activeCodes': activeCodes,
        'expiredCodes': expiredCodes,
        'usageLimitReached': usageLimitReached,
        'totalUsage': totalUsage,
      };
    } catch (e) {
      print('Error getting promo code stats: $e');
      return {
        'totalCodes': 0,
        'activeCodes': 0,
        'expiredCodes': 0,
        'usageLimitReached': 0,
        'totalUsage': 0,
      };
    }
  }
} 