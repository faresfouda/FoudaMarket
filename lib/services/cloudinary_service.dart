import 'package:cloudinary_public/cloudinary_public.dart';
import 'image_compression_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

// تذكر تغيير CLOUD_NAME و UPLOAD_PRESET إلى بيانات حسابك في Cloudinary
class CloudinaryService {
  final cloudinary = CloudinaryPublic('dmmlntyd8', 'Fouda Market', cache: false);
  final _compressionService = ImageCompressionService();

  // إعدادات Cloudinary للحذف (يجب الحصول عليها من لوحة التحكم)
  static const String _cloudName = 'dmmlntyd8';
  static const String _apiKey = '125933152659552'; // يجب تعديلها
  static const String _apiSecret = '3mieHLkkiV5LfhSS_p5h8e02Nuo'; // يجب تعديلها

  /// رفع صورة مع ضغط تلقائي
  Future<String?> uploadImage(String filePath) async {
    try {
      debugPrint('بدء رف�� الصورة: $filePath');

      final imageFile = File(filePath);
      if (!await imageFile.exists()) {
        debugPrint('الملف غير موجود: $filePath');
        return null;
      }

      // التحقق من حجم الملف
      final fileInfo = await _compressionService.getFileInfo(imageFile);
      debugPrint('معلومات الملف: ${fileInfo['sizeInMB'].toStringAsFixed(2)} MB');

      // ضغط الصورة إذا كانت كبيرة
      File? fileToUpload = imageFile;
      if (fileInfo['sizeInMB'] > 1.0) { // إذا كان الحجم أكبر من 1 MB
        debugPrint('ضغط الصورة قبل الرفع...');
        final compressedFile = await _compressionService.compressImageSmart(imageFile);
        if (compressedFile != null) {
          fileToUpload = compressedFile;
          final compressedInfo = await _compressionService.getFileInfo(compressedFile);
          debugPrint('بعد الضغط: ${compressedInfo['sizeInMB'].toStringAsFixed(2)} MB');
        }
      }

      // رفع الصورة
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(fileToUpload.path, resourceType: CloudinaryResourceType.Image),
      );

      // تنظيف الملف المضغوط المؤقت إذا كان مختلفاً عن الملف الأصلي
      if (fileToUpload != imageFile && await fileToUpload.exists()) {
        await fileToUpload.delete();
        debugPrint('تم حذف الملف المضغوط المؤقت');
      }

      debugPrint('تم رفع الصورة بنجاح: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      debugPrint('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  /// رفع صورة مع إعدادات ضغط مخصصة
  Future<String?> uploadImageWithCompression(String filePath, {
    int quality = 85,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      debugPrint('بدء رفع الصورة مع ضغط مخصص: $filePath');
      
      final imageFile = File(filePath);
      if (!await imageFile.exists()) {
        debugPrint('الملف غير موجود: $filePath');
        return null;
      }

      // ضغط الصورة بالإعدادات المخصصة
      final compressedFile = await _compressionService.compressImageFile(
        imageFile,
        quality: quality,

      );

      if (compressedFile == null) {
        debugPrint('فشل في ضغط الصورة');
        return null;
      }

      // رفع الصورة المضغوطة
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(compressedFile.path, resourceType: CloudinaryResourceType.Image),
      );

      // تنظيف الملف المضغوط المؤقت
      if (await compressedFile.exists()) {
        await compressedFile.delete();
        debugPrint('ت�� حذف الملف المضغوط المؤقت');
      }

      debugPrint('تم رفع الصورة المضغوطة بنجاح: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      debugPrint('خطأ في رفع الصورة المضغوطة: $e');
      return null;
    }
  }

  /// رفع صورة من ملف File مباشرة
  Future<String?> uploadImageFile(File imageFile) async {
    return await uploadImage(imageFile.path);
  }

  /// رفع صورة من ملف File مع ضغط مخصص
  Future<String?> uploadImageFileWithCompression(File imageFile, {
    int quality = 85,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    return await uploadImageWithCompression(imageFile.path, 
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  /// تنظيف الملفات المؤقتة
  Future<void> cleanupTempFiles() async {
    await _compressionService.cleanupTempFiles();
  }

  /// حذف صورة من Cloudinary باستخدام الرابط
  Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      // استخراج public_id من الرابط
      final publicId = _extractPublicIdFromUrl(imageUrl);
      if (publicId == null) {
        debugPrint('فشل في استخراج public_id من الرابط: $imageUrl');
        return false;
      }

      debugPrint('محاولة حذف الصورة بـ public_id: $publicId');

      // حذف الصورة من Cloudinary باستخدام API
      final success = await _deleteImageFromCloudinary(publicId);

      if (success) {
        debugPrint('تم حذف الصورة بنجاح: $publicId');
      } else {
        debugPrint('فشل في حذف الصورة: $publicId');
      }

      return success;
    } catch (e) {
      debugPrint('خطأ في حذف الصورة: $e');
      return false;
    }
  }

  /// حذف عدة صور من Cloudinary
  Future<bool> deleteMultipleImages(List<String> imageUrls) async {
    bool allDeleted = true;
    for (String imageUrl in imageUrls) {
      if (imageUrl.isNotEmpty) {
        final deleted = await deleteImageByUrl(imageUrl);
        if (!deleted) {
          allDeleted = false;
        }
      }
    }
    return allDeleted;
  }

  /// حذف صورة من Cloudinary باستخدام REST API
  Future<bool> _deleteImageFromCloudinary(String publicId) async {
    try {
      // إنشاء timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // إنشاء signature
      final stringToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();

      // إعداد البيانات للإرسال
      final data = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
        'api_key': _apiKey,
        'signature': signature,
      };

      // إرسال طلب الحذف
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: data,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['result'] == 'ok';
      } else {
        debugPrint('خطأ في طلب حذف الصورة: ${response.statusCode}');
        debugPrint('استجابة الخادم: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('خطأ في إرسال طلب حذف الصورة: $e');
      return false;
    }
  }

  /// استخراج public_id من رابط Cloudinary
  String? _extractPublicIdFromUrl(String imageUrl) {
    try {
      // مثال على رابط Cloudinary:
      // https://res.cloudinary.com/dmmlntyd8/image/upload/v1234567890/folder/image_name.jpg

      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // البحث عن مؤشر "upload" في المسار
      int uploadIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'upload') {
          uploadIndex = i;
          break;
        }
      }

      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        return null;
      }

      // الحصول على الجزء بعد version (v1234567890)
      List<String> publicIdParts = [];
      for (int i = uploadIndex + 2; i < pathSegments.length; i++) {
        publicIdParts.add(pathSegments[i]);
      }

      if (publicIdParts.isEmpty) {
        return null;
      }

      // إزالة امتداد الملف من آخر جزء
      String lastPart = publicIdParts.last;
      int dotIndex = lastPart.lastIndexOf('.');
      if (dotIndex != -1) {
        lastPart = lastPart.substring(0, dotIndex);
        publicIdParts[publicIdParts.length - 1] = lastPart;
      }

      return publicIdParts.join('/');
    } catch (e) {
      debugPrint('خطأ في استخراج public_id: $e');
      return null;
    }
  }
}
