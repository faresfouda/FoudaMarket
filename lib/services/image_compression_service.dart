import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionService {
  static final ImageCompressionService _instance = ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  /// ضغط صورة من ملف (ضغط الحجم فقط)
  Future<File?> compressImageFile(File imageFile, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة: ${imageFile.path}');

      Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: quality,
        keepExif: keepExif,
        format: CompressFormat.jpeg,
        numberOfRetries: 3,
        autoCorrectionAngle: true,
      );

      if (compressedBytes == null) {
        debugPrint('compressWithFile فشل، سيتم تجربة compressWithList');
        final bytes = await imageFile.readAsBytes();
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          quality: quality,
          keepExif: keepExif,
        );
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File(path.join(tempDir.path, fileName));
      await compressedFile.writeAsBytes(compressedBytes);

      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();
      final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

      debugPrint('تم ضغط الصورة بنجاح:');
      debugPrint('- الحجم الأصلي: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('- الحجم المضغوط: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('- نسبة الضغط: ${compressionRatio.toStringAsFixed(1)}%');

      return compressedFile;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة: $e');
      return null;
    }
  }

  /// ضغط صورة من مسار
  Future<File?> compressImageFromPath(String imagePath, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      debugPrint('الملف غير موجود: $imagePath');
      return null;
    }

    return await compressImageFile(
      imageFile,
      quality: quality,
      keepExif: keepExif,
    );
  }

  /// ضغط صورة من Bytes
  Future<Uint8List?> compressImageBytes(Uint8List imageBytes, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة من bytes');

      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        keepExif: keepExif,
      );

      final compressionRatio = ((imageBytes.length - compressedBytes.length) / imageBytes.length * 100);
      debugPrint('تم ضغط الصورة من bytes:');
      debugPrint('- الحجم الأصلي: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB');
      debugPrint('- الحجم المضغوط: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
      debugPrint('- نسبة الضغط: ${compressionRatio.toStringAsFixed(1)}%');

      return compressedBytes;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من bytes: $e');
      return null;
    }
  }

  /// ضغط صورة مع إعدادات ذكية حسب الحجم
  Future<File?> compressImageSmart(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      final sizeInMB = fileSize / (1024 * 1024);
      
      // إعدادات ضغط ذكية حسب حجم الملف
      int quality;
      int maxWidth;
      int maxHeight;
      
      if (sizeInMB > 5) {
        // ملف كبير جداً - ضغط قوي
        quality = 70;
        maxWidth = 800;
        maxHeight = 800;
      } else if (sizeInMB > 2) {
        // ملف كبير - ضغط متوسط
        quality = 80;
        maxWidth = 1024;
        maxHeight = 1024;
      } else if (sizeInMB > 1) {
        // ملف متوسط - ضغط خفيف
        quality = 85;
        maxWidth = 1200;
        maxHeight = 1200;
      } else {
        // ملف صغير - ضغط خفيف جداً
        quality = 90;
        maxWidth = 1500;
        maxHeight = 1500;
      }
      
      debugPrint('ضغط ذكي للصورة:');
      debugPrint('- الحجم: ${sizeInMB.toStringAsFixed(2)} MB');
      debugPrint('- الجودة: $quality%');
      debugPrint('- الأبعاد القصوى: ${maxWidth}x$maxHeight');
      
      return await compressImageFile(imageFile, 
        quality: quality,
      );
    } catch (e) {
      debugPrint('خطأ في الضغط الذكي: $e');
      return null;
    }
  }

  /// التحقق من حجم الملف
  Future<bool> isFileTooLarge(File file, {int maxSizeMB = 10}) async {
    try {
      final size = await file.length();
      final sizeInMB = size / (1024 * 1024);
      return sizeInMB > maxSizeMB;
    } catch (e) {
      debugPrint('خطأ في التحقق من حجم الملف: $e');
      return false;
    }
  }

  /// الحصول على معلومات الملف
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final size = await file.length();
      final sizeInMB = size / (1024 * 1024);
      final sizeInKB = size / 1024;
      
      return {
        'size': size,
        'sizeInMB': sizeInMB,
        'sizeInKB': sizeInKB,
        'path': file.path,
        'exists': await file.exists(),
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات الملف: $e');
      return {};
    }
  }

  /// تنظيف الملفات المؤقتة
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      int deletedCount = 0;
      for (final file in files) {
        if (file is File && file.path.contains('compressed_')) {
          final age = DateTime.now().difference(file.statSync().modified).inHours;
          if (age > 24) { // حذف الملفات الأقدم من 24 ساعة
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      if (deletedCount > 0) {
        debugPrint('تم حذف $deletedCount ملف مؤقت');
      }
    } catch (e) {
      debugPrint('خطأ في تنظيف الملفات المؤقتة: $e');
    }
  }
} 