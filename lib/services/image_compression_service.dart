import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

// استيراد شرطي للتنفيذات المختلفة
import 'image_compression_service_mobile.dart' if (dart.library.html) 'image_compression_service_web.dart';

/// خدمة ضغط الصور مع دعم متعدد المنصات
class ImageCompressionService {
  static final ImageCompressionService _instance = ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  ImageCompressionImplementation? _implementation;

  /// تهيئة الخدمة
  void _initializeImplementation() {
    if (kIsWeb) {
      // تنفيذ الويب
      try {
        _implementation = createWebImageCompressionImplementation();
      } catch (e) {
        debugPrint('فشل في تهيئة تنفيذ الويب: $e');
        _implementation = _FallbackImplementation();
      }
    } else {
      // تنفيذ الأجهزة المحمولة
      try {
        _implementation = createMobileImageCompressionImplementation();
      } catch (e) {
        debugPrint('فشل في تهيئة تنفيذ الأجهزة المحمولة: $e');
        _implementation = _FallbackImplementation();
      }
    }
  }

  /// الحصول على التنفيذ المناسب
  ImageCompressionImplementation get _impl {
    if (_implementation == null) {
      _initializeImplementation();
    }
    return _implementation!;
  }

  /// ضغط صورة من XFile (يدعم الويب والمنصات الأخرى)
  Future<File?> compressImageFromXFile(
    XFile xFile, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة من XFile: ${xFile.path}');
      return await _impl.compressImageFromXFile(xFile, quality: quality, keepExif: keepExif);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من XFile: $e');
      // في حالة الخطأ، إرجاع ملف من المسار الأصلي
      return File(xFile.path);
    }
  }

  /// ضغط صورة من ملف
  Future<File?> compressImageFile(
    File imageFile, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة: ${imageFile.path}');
      return await _impl.compressImageFile(imageFile, quality: quality, keepExif: keepExif);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة: $e');
      return imageFile;
    }
  }

  /// ضغط صورة من مسار
  Future<File?> compressImageFromPath(
    String imagePath, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      final imageFile = File(imagePath);
      return await compressImageFile(imageFile, quality: quality, keepExif: keepExif);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من المسار: $e');
      return null;
    }
  }

  /// ضغط صورة من Bytes
  Future<Uint8List?> compressImageBytes(
    Uint8List imageBytes, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة من bytes');
      return await _impl.compressImageBytes(imageBytes, quality: quality, keepExif: keepExif);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من bytes: $e');
      return imageBytes;
    }
  }

  /// ضغط صورة مع إعدادات ذكية حسب الحجم
  Future<File?> compressImageSmart(File imageFile) async {
    try {
      final fileInfo = await getFileInfo(imageFile);
      final sizeInMB = fileInfo['sizeInMB'] as double;

      // إعدادات ضغط ذكية حسب حجم الملف
      int quality;
      if (sizeInMB > 5) {
        quality = 70; // ضغط قوي للملفات الكبيرة جداً
      } else if (sizeInMB > 2) {
        quality = 80; // ضغط متوسط للملفات الكبيرة
      } else if (sizeInMB > 1) {
        quality = 85; // ضغط خفيف للملفات المتوسطة
      } else {
        quality = 90; // ضغط خفيف جداً للملفات الصغيرة
      }

      debugPrint('ضغط ذكي للصورة:');
      debugPrint('- الحجم: ${sizeInMB.toStringAsFixed(2)} MB');
      debugPrint('- الجودة المختارة: $quality%');

      return await compressImageFile(imageFile, quality: quality);
    } catch (e) {
      debugPrint('خطأ في الضغط الذكي: $e');
      return imageFile;
    }
  }

  /// ضغط مع تحديد الأبعاد
  Future<File?> compressImageWithDimensions(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1200,
    int maxHeight = 1200,
    bool keepExif = false,
  }) async {
    try {
      return await _impl.compressImageWithDimensions(
        imageFile,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        keepExif: keepExif,
      );
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة مع الأبعاد: $e');
      return imageFile;
    }
  }

  /// التحقق من حجم الملف
  Future<bool> isFileTooLarge(File file, {int maxSizeMB = 10}) async {
    try {
      final info = await getFileInfo(file);
      final sizeInMB = info['sizeInMB'] as double;
      return sizeInMB > maxSizeMB;
    } catch (e) {
      debugPrint('خطأ في التحقق من حجم الملف: $e');
      return false;
    }
  }

  /// الحصول على معلومات الملف
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      return await _impl.getFileInfo(file);
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات الملف: $e');
      return {
        'size': 0,
        'sizeInMB': 0.0,
        'sizeInKB': 0.0,
        'path': file.path,
        'exists': false,
      };
    }
  }

  /// الحصول على بيانات الملف للويب
  Uint8List? getWebFileData(String fileName) {
    try {
      return _impl.getWebFileData(fileName);
    } catch (e) {
      debugPrint('خطأ في الحصول على بيانات الملف للويب: $e');
      return null;
    }
  }

  /// تنظيف الملفات المؤقتة
  Future<void> cleanupTempFiles() async {
    try {
      await _impl.cleanupTempFiles();
      debugPrint('تم تنظيف الملفات المؤقتة');
    } catch (e) {
      debugPrint('خطأ في تنظيف الملفات المؤقتة: $e');
    }
  }

  /// حساب نسبة الضغط
  double calculateCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0;
    return ((originalSize - compressedSize) / originalSize * 100);
  }

  /// تحديد لون التحذير حسب حجم الملف
  String getWarningColor(double sizeInMB) {
    if (sizeInMB > 5) return 'red'; // ملف كبير جداً
    if (sizeInMB > 2) return 'orange'; // ملف كبير
    if (sizeInMB > 1) return 'yellow'; // ملف متوسط
    return 'green'; // حجم مناسب
  }

  /// الحصول على رسالة التحذير
  String getWarningMessage(double sizeInMB) {
    if (sizeInMB > 5) return 'ملف كبير جداً - يوصى بالضغط بقوة';
    if (sizeInMB > 2) return 'ملف كبير - يوصى بالضغط';
    if (sizeInMB > 1) return 'ملف متوسط - ضغط اختياري';
    return 'حجم مناسب';
  }
}

/// واجهة التنفيذ المشتركة
abstract class ImageCompressionImplementation {
  Future<File?> compressImageFromXFile(XFile xFile, {int quality = 75, bool keepExif = false});
  Future<File?> compressImageFile(File imageFile, {int quality = 75, bool keepExif = false});
  Future<Uint8List?> compressImageBytes(Uint8List imageBytes, {int quality = 75, bool keepExif = false});
  Future<File?> compressImageWithDimensions(File imageFile, {int quality = 85, int maxWidth = 1200, int maxHeight = 1200, bool keepExif = false});
  Future<Map<String, dynamic>> getFileInfo(File file);
  Future<void> cleanupTempFiles();
  Uint8List? getWebFileData(String fileName);
}

/// تنفيذ احتياطي في حالة الفشل في تحميل التنفيذ المناسب
class _FallbackImplementation implements ImageCompressionImplementation {
  @override
  Future<File?> compressImageFromXFile(XFile xFile, {int quality = 75, bool keepExif = false}) async {
    return File(xFile.path);
  }

  @override
  Future<File?> compressImageFile(File imageFile, {int quality = 75, bool keepExif = false}) async {
    return imageFile;
  }

  @override
  Future<Uint8List?> compressImageBytes(Uint8List imageBytes, {int quality = 75, bool keepExif = false}) async {
    return imageBytes;
  }

  @override
  Future<File?> compressImageWithDimensions(File imageFile, {int quality = 85, int maxWidth = 1200, int maxHeight = 1200, bool keepExif = false}) async {
    return imageFile;
  }

  @override
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    return {
      'size': 0,
      'sizeInMB': 0.0,
      'sizeInKB': 0.0,
      'path': file.path,
      'exists': false,
    };
  }

  @override
  Future<void> cleanupTempFiles() async {
    // لا شيء للقيام به في التنفيذ الاحتياطي
  }

  @override
  Uint8List? getWebFileData(String fileName) {
    return null;
  }
}
