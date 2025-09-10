import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouda_market/models/banner_image_model.dart';
import 'package:fouda_market/services/cloudinary_service.dart';
import 'dart:io';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// جلب جميع صور العروض
  Future<List<BannerImage>> getAllBanners() async {
    try {
      final querySnapshot = await _firestore
          .collection('banners')
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BannerImage.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب صور العروض: $e');
      return [];
    }
  }

  /// جلب صور العروض المفعلة فقط
  Future<List<BannerImage>> getActiveBanners() async {
    try {
      final querySnapshot = await _firestore
          .collection('banners')
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BannerImage.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب صور العروض المفعلة: $e');
      return [];
    }
  }

  /// إضافة صورة عرض جديدة
  Future<bool> addBanner({
    required File imageFile,
    required String title,
    required String adminId,
    String? adminName,
  }) async {
    try {
      // رفع الصورة إلى Cloudinary
      final imageUrl = await _cloudinaryService.uploadImageFile(imageFile);
      if (imageUrl == null) {
        print('فشل في رفع الصورة');
        return false;
      }

      // حفظ بيانات الصورة في Firestore
      final bannerData = {
        'image_url': imageUrl,
        'title': title,
        'is_active': true, // مفعلة افتراضياً
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'created_by': adminName ?? adminId,
        'admin_id': adminId,
      };

      await _firestore.collection('banners').add(bannerData);
      print('تم إضافة صورة العرض بنجاح');
      return true;
    } catch (e) {
      print('خطأ في إضافة صورة العرض: $e');
      return false;
    }
  }

  /// تحديث حالة صورة العرض (تفعيل/إلغاء تفعيل)
  Future<bool> updateBannerStatus({
    required String bannerId,
    required bool isActive,
    required String adminId,
    String? adminName,
  }) async {
    try {
      await _firestore.collection('banners').doc(bannerId).update({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': adminName ?? adminId,
        'admin_id': adminId,
      });
      print('تم تحديث حالة صورة العرض بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة صورة العرض: $e');
      return false;
    }
  }

  /// تحديث عنوان صورة العرض
  Future<bool> updateBannerTitle({
    required String bannerId,
    required String title,
    required String adminId,
    String? adminName,
  }) async {
    try {
      await _firestore.collection('banners').doc(bannerId).update({
        'title': title,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': adminName ?? adminId,
        'admin_id': adminId,
      });
      print('تم تحديث عنوان صورة العرض بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تحديث عنوان صورة العرض: $e');
      return false;
    }
  }

  /// حذف صورة عرض
  Future<bool> deleteBanner({
    required String bannerId,
    required String adminId,
    String? adminName,
  }) async {
    try {
      // جلب بيانات الصورة أولاً
      final doc = await _firestore.collection('banners').doc(bannerId).get();
      if (!doc.exists) {
        print('صورة العرض غير موجودة');
        return false;
      }

      final bannerData = doc.data();
      final imageUrl = bannerData?['image_url'];

      // حذف الصورة من Firestore
      await _firestore.collection('banners').doc(bannerId).delete();

      // يمكن إضافة حذف الصورة من Cloudinary هنا إذا لزم الأمر
      // await _cloudinaryService.deleteImage(imageUrl);

      print('تم حذف صورة العرض بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف صورة العرض: $e');
      return false;
    }
  }

  /// حذف جميع صور العروض
  Future<bool> deleteAllBanners({
    required String adminId,
    String? adminName,
  }) async {
    try {
      final querySnapshot = await _firestore.collection('banners').get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('تم حذف جميع صور العروض بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف جميع صور العروض: $e');
      return false;
    }
  }
}
