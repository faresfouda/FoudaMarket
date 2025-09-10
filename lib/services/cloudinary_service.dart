import 'package:cloudinary_public/cloudinary_public.dart';
import 'image_compression_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// تذكر تغيير CLOUD_NAME و UPLOAD_PRESET إلى بيانات حسابك في Cloudinary
class CloudinaryService {
  final cloudinary = CloudinaryPublic('dmmlntyd8', 'Fouda Market', cache: false);
  final _compressionService = ImageCompressionService();

  /// رفع صورة مع ضغط تلقائي
  Future<String?> uploadImage(String filePath) async {
    try {
      debugPrint('بدء رفع الصورة: $filePath');

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
        debugPrint('تم حذف الملف المضغوط المؤقت');
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
}
