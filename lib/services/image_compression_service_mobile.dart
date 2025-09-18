import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'image_compression_service.dart';

/// تنفيذ خدمة ضغط الصور للأجهزة المحمولة (Android/iOS)
class MobileImageCompressionImplementation implements ImageCompressionImplementation {
  final List<String> _tempFilePaths = [];

  @override
  Future<File?> compressImageFromXFile(
    XFile xFile, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة من XFile للأجهزة المحمولة: ${xFile.path}');

      // تحويل XFile إلى File
      final file = File(xFile.path);
      return await compressImageFile(file, quality: quality, keepExif: keepExif);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من XFile للأجهزة المحمولة: $e');
      return File(xFile.path);
    }
  }

  @override
  Future<File?> compressImageFile(
    File imageFile, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة للأجهزة المحمولة: ${imageFile.path}');

      if (!await imageFile.exists()) {
        debugPrint('الملف غير موجود: ${imageFile.path}');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}'
      );

      _tempFilePaths.add(targetPath);

      // محاولة الضغط باستخدام compressAndGetFile أولاً
      XFile? result;
      try {
        result = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          targetPath,
          quality: quality,
          keepExif: keepExif,
          format: CompressFormat.jpeg,
          numberOfRetries: 3,
          autoCorrectionAngle: true,
        );
        debugPrint('تم ضغط الصورة بالمسار بنجاح للأجهزة المحمولة');
      } catch (e) {
        debugPrint('فشل الضغط بالمسار للأجهزة المحمولة: $e');
        result = null;
      }

      // إذا فشل الضغط بالمسار، جرب الضغط بالبيانات
      if (result == null) {
        debugPrint('محاولة الضغط بالبيانات للأجهزة المحمولة...');
        try {
          final bytes = await imageFile.readAsBytes();
          final compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            quality: quality,
            keepExif: keepExif,
            format: CompressFormat.jpeg,
          );

          final compressedFile = File(targetPath);
          await compressedFile.writeAsBytes(compressedBytes);
          result = XFile(compressedFile.path);
          debugPrint('تم ضغط الصورة بالبيانات بنجاح للأجهزة المحمولة');
        } catch (e) {
          debugPrint('فشل الضغط بالبيانات أيضاً للأجهزة المحمولة: $e');
          return imageFile;
        }
      }

      if (result != null) {
        final compressedFile = File(result.path);

        // عرض إحصائيات الضغط
        final originalSize = await imageFile.length();
        final compressedSize = await compressedFile.length();
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

        debugPrint('تم ضغط الصورة بنجاح للأجهزة المحمولة:');
        debugPrint('- الحجم الأصلي: ${(originalSize / 1024).toStringAsFixed(2)} KB');
        debugPrint('- الحجم المضغوط: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        debugPrint('- نسبة الضغط: ${compressionRatio.toStringAsFixed(1)}%');

        return compressedFile;
      }

      return imageFile;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة للأجهزة المحمولة: $e');
      return imageFile;
    }
  }

  @override
  Future<Uint8List?> compressImageBytes(
    Uint8List imageBytes, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة من bytes للأجهزة المحمولة');

      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        keepExif: keepExif,
        format: CompressFormat.jpeg,
      );

      final compressionRatio = ((imageBytes.length - compressedBytes.length) / imageBytes.length * 100);
      debugPrint('تم ضغط الصورة من bytes للأجهزة المحمولة:');
      debugPrint('- الحجم الأصلي: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB');
      debugPrint('- الحجم المضغوط: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
      debugPrint('- نسبة الضغط: ${compressionRatio.toStringAsFixed(1)}%');

      return compressedBytes;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من bytes للأجهزة المحمولة: $e');
      return imageBytes;
    }
  }

  @override
  Future<File?> compressImageWithDimensions(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1200,
    int maxHeight = 1200,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة مع الأبعاد للأجهزة المحمولة');

      if (!await imageFile.exists()) {
        debugPrint('الملف غير موجود: ${imageFile.path}');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_dim_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}'
      );

      _tempFilePaths.add(targetPath);

      // ضغط مع تحديد الأبعاد
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        keepExif: keepExif,
        format: CompressFormat.jpeg,
        numberOfRetries: 3,
        autoCorrectionAngle: true,
      );

      if (result != null) {
        final compressedFile = File(result.path);

        // عرض إحصائيات الضغط
        final originalSize = await imageFile.length();
        final compressedSize = await compressedFile.length();
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

        debugPrint('تم ضغط الصورة مع الأبعاد بنجاح للأجهزة المحمولة:');
        debugPrint('- الحجم الأصلي: ${(originalSize / 1024).toStringAsFixed(2)} KB');
        debugPrint('- الحجم المضغوط: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        debugPrint('- نسبة الضغط: ${compressionRatio.toStringAsFixed(1)}%');
        debugPrint('- الأبعاد القصوى: ${maxWidth}x$maxHeight');

        return compressedFile;
      }

      return imageFile;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة مع الأبعاد للأجهزة المحمولة: $e');
      return imageFile;
    }
  }

  @override
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final size = await file.length();
      final sizeInMB = size / (1024 * 1024);
      final sizeInKB = size / 1024;
      final exists = await file.exists();

      return {
        'size': size,
        'sizeInMB': sizeInMB,
        'sizeInKB': sizeInKB,
        'path': file.path,
        'exists': exists,
        'platform': 'mobile',
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات الملف للأجهزة المحمولة: $e');
      return {
        'size': 0,
        'sizeInMB': 0.0,
        'sizeInKB': 0.0,
        'path': file.path,
        'exists': false,
        'platform': 'mobile',
      };
    }
  }

  @override
  Future<void> cleanupTempFiles() async {
    try {
      // حذف الملفات المؤقتة المحفوظة في القائمة
      for (var filePath in _tempFilePaths) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('تم حذف الملف المؤقت للأجهزة المحمولة: $filePath');
          }
        } catch (e) {
          debugPrint('خطأ في حذف الملف المؤقت للأجهزة المحمولة: $e');
        }
      }
      _tempFilePaths.clear();

      // تنظيف إضافي لجميع الملفات المضغوطة في المجلد المؤقت
      try {
        final tempDir = await getTemporaryDirectory();
        final files = tempDir.listSync();

        for (final file in files) {
          if (file is File &&
              (file.path.contains('compressed_') ||
               file.path.contains('compressed_dim_'))) {
            try {
              await file.delete();
              debugPrint('تم حذف ملف مؤقت إضافي للأجهزة المحمولة: ${file.path}');
            } catch (e) {
              debugPrint('خطأ في حذف ملف مؤقت إضافي للأجهزة المحمولة: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('خطأ في تنظيف المجلد المؤقت للأجهزة المحمولة: $e');
      }
    } catch (e) {
      debugPrint('خطأ في تنظيف الملفات المؤقتة للأجهزة المحمولة: $e');
    }
  }

  @override
  Uint8List? getWebFileData(String fileName) {
    // هذه الدالة خاصة بالويب، ترجع null في الأجهزة المحمولة
    debugPrint('getWebFileData غير مدعوم في الأجهزة المحمولة');
    return null;
  }
}

/// إنشاء تنفيذ الأجهزة المحمولة (دالة مساعدة للاستيراد الشرطي)
ImageCompressionImplementation createMobileImageCompressionImplementation() {
  return MobileImageCompressionImplementation();
}

/// إنشاء تنفيذ الويب (دالة وهمية - لن تستدعى في الأجهزة المحمولة)
ImageCompressionImplementation createWebImageCompressionImplementation() {
  throw UnsupportedError('Web implementation is not supported on mobile platforms');
}
