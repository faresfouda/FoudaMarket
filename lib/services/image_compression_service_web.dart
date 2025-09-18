import 'dart:async';
import 'dart:html' as html;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'image_compression_service.dart';

/// إنشاء تنفيذ الويب (دالة مساعدة للاستيراد الشرطي)
ImageCompressionImplementation createWebImageCompressionImplementation() {
  return WebImageCompressionImplementation();
}

/// إنشاء تنفيذ الأجهزة المحمولة (دالة وهمية - لن تستدعى في الويب)
ImageCompressionImplementation createMobileImageCompressionImplementation() {
  throw UnsupportedError('Mobile implementation is not supported on web platform');
}

/// تنفيذ خدمة ضغط الصور لمنصة الويب
class WebImageCompressionImplementation implements ImageCompressionImplementation {
  // كاش لحفظ بيانات الملفات في الويب
  static final Map<String, Uint8List> _webFileCache = {};

  @override
  Future<File?> compressImageFromXFile(
    XFile xFile, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة من XFile للويب: ${xFile.path}');

      // قراءة البيانات من XFile
      final bytes = await xFile.readAsBytes();
      debugPrint('تم قراءة ${bytes.length} بايت من XFile');

      // ضغط البيانات باستخدام Canvas API
      final compressedBytes = await _compressImageBytesWeb(bytes, quality: quality);

      if (compressedBytes != null && compressedBytes.length < bytes.length) {
        debugPrint('تم ضغط الصورة للويب بنجاح');
        debugPrint('- الحجم الأصلي: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
        debugPrint('- الحجم المضغوط: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');

        // حفظ البيانات المضغوطة في الكاش
        final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}_${path.basename(xFile.path)}';
        _webFileCache[fileName] = compressedBytes;

        return _WebFile(fileName, compressedBytes);
      } else {
        debugPrint('لم يتم تحقيق تحسن في الضغط، سيتم استخدام الصورة الأصلية');
        final fileName = 'original_${DateTime.now().millisecondsSinceEpoch}_${path.basename(xFile.path)}';
        _webFileCache[fileName] = bytes;
        return _WebFile(fileName, bytes);
      }
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من XFile للويب: $e');
      // في حالة الخطأ، احفظ البيانات الأصلية
      try {
        final bytes = await xFile.readAsBytes();
        final fileName = 'fallback_${DateTime.now().millisecondsSinceEpoch}_${path.basename(xFile.path)}';
        _webFileCache[fileName] = bytes;
        return _WebFile(fileName, bytes);
      } catch (fallbackError) {
        debugPrint('خطأ في إنشاء ملف احتياطي: $fallbackError');
        return null;
      }
    }
  }

  @override
  Future<File?> compressImageFile(
    File imageFile, {
    int quality = 75,
    bool keepExif = false,
  }) async {
    try {
      debugPrint('بدء ضغط الصورة من File للويب: ${imageFile.path}');

      Uint8List bytes;

      // التحقق من وجود البيانات في الكاش أولاً
      if (imageFile is _WebFile) {
        bytes = imageFile.bytes;
        debugPrint('تم العثور على البيانات في WebFile');
      } else if (_webFileCache.containsKey(imageFile.path)) {
        bytes = _webFileCache[imageFile.path]!;
        debugPrint('تم العثور على البيانات في الكاش');
      } else {
        // محاولة قراءة البيانات من الملف
        try {
          bytes = await imageFile.readAsBytes();
          debugPrint('تم قراءة البيانات من الملف');
        } catch (e) {
          debugPrint('فشل في قراءة الملف للويب: $e');
          return imageFile;
        }
      }

      // ضغط البيانات باستخدام Canvas API
      final compressedBytes = await _compressImageBytesWeb(bytes, quality: quality);

      if (compressedBytes != null && compressedBytes.length < bytes.length) {
        debugPrint('تم ضغط الصورة للويب بنجاح');
        debugPrint('- الحجم الأصلي: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
        debugPrint('- الحجم المضغوط: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');

        // حفظ البيانات المضغوطة في الكاش
        final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        _webFileCache[fileName] = compressedBytes;

        return _WebFile(fileName, compressedBytes);
      } else {
        debugPrint('لم يتم تحقيق تحسن في الضغط');
        // احتفظ بالبيانات الأصلية في الكاش
        if (!_webFileCache.containsKey(imageFile.path)) {
          _webFileCache[imageFile.path] = bytes;
        }
        return imageFile;
      }
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من File للويب: $e');
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
      debugPrint('بدء ضغط الصورة من bytes للويب');

      final compressedBytes = await _compressImageBytesWeb(imageBytes, quality: quality);

      if (compressedBytes != null) {
        final compressionRatio = ((imageBytes.length - compressedBytes.length) / imageBytes.length * 100);
        debugPrint('تم ضغط الصورة من bytes للويب:');
        debugPrint('- الحجم الأصلي: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB');
        debugPrint('- الحجم المضغوط: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
        debugPrint('- نسبة الضغط: ${compressionRatio.toStringAsFixed(1)}%');

        return compressedBytes;
      } else {
        debugPrint('فشل في ضغط البيانات للويب، سيتم إرجاع البيانات الأصلية');
        return imageBytes;
      }
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة من bytes للويب: $e');
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
      debugPrint('بدء ضغط الصورة مع الأبعاد للويب');

      Uint8List bytes;

      // الحصول على البيانات
      if (imageFile is _WebFile) {
        bytes = imageFile.bytes;
      } else if (_webFileCache.containsKey(imageFile.path)) {
        bytes = _webFileCache[imageFile.path]!;
      } else {
        try {
          bytes = await imageFile.readAsBytes();
        } catch (e) {
          debugPrint('فشل في قراءة الملف للويب: $e');
          return imageFile;
        }
      }

      // ضغط مع الأبعاد المحددة
      final compressedBytes = await _compressImageBytesWebWithDimensions(
        bytes,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight
      );

      if (compressedBytes != null && compressedBytes.length < bytes.length) {
        debugPrint('تم ضغط الصورة مع الأبعاد للويب بنجاح');
        debugPrint('- الحجم الأصلي: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
        debugPrint('- الحجم المضغوط: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
        debugPrint('- الأبعاد القصوى: ${maxWidth}x$maxHeight');

        // حفظ البيانات المضغوطة في الكاش
        final fileName = 'compressed_dim_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        _webFileCache[fileName] = compressedBytes;

        return _WebFile(fileName, compressedBytes);
      }

      return imageFile;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة مع الأبعاد للويب: $e');
      return imageFile;
    }
  }

  /// ضغط البيانات باستخدام Canvas API للويب
  Future<Uint8List?> _compressImageBytesWeb(Uint8List imageBytes, {int quality = 75}) async {
    try {
      debugPrint('بدء الضغط باستخدام Canvas API');

      // إنشاء Blob من البيانات
      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // إنشاء Image element
      final image = html.ImageElement();
      final completer = Completer<html.ImageElement>();

      image.onLoad.listen((_) {
        completer.complete(image);
      });

      image.onError.listen((_) {
        completer.completeError('خطأ في تحميل الصورة');
      });

      image.src = url;

      // انتظار تحميل الصورة مع timeout
      final loadedImage = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'انتهت مهلة تحميل الصورة',
      );

      // حساب الأبعاد الجديدة
      final originalWidth = loadedImage.naturalWidth!;
      final originalHeight = loadedImage.naturalHeight!;

      // تحديد الحد الأقصى للأبعاد حسب الحجم
      int maxDimension;
      if (imageBytes.length > 5 * 1024 * 1024) { // أكبر من 5MB
        maxDimension = 800;
      } else if (imageBytes.length > 2 * 1024 * 1024) { // أكبر من 2MB
        maxDimension = 1024;
      } else if (imageBytes.length > 1 * 1024 * 1024) { // أكبر من 1MB
        maxDimension = 1200;
      } else {
        maxDimension = 1500;
      }

      // حساب الأبعاد الجديدة مع الحفاظ على النسبة
      double ratio = 1.0;
      if (originalWidth > maxDimension || originalHeight > maxDimension) {
        ratio = maxDimension / (originalWidth > originalHeight ? originalWidth : originalHeight);
      }

      final newWidth = (originalWidth * ratio).round();
      final newHeight = (originalHeight * ratio).round();

      // إنشاء Canvas
      final canvas = html.CanvasElement(width: newWidth, height: newHeight);
      final context = canvas.getContext('2d') as html.CanvasRenderingContext2D;

      // تحسين جودة الرسم
      context.imageSmoothingEnabled = true;
      context.imageSmoothingQuality = 'high';

      // رسم الصورة على Canvas بالأبعاد الجديدة
      context.drawImageScaled(loadedImage, 0, 0, newWidth, newHeight);

      // تحويل Canvas إلى Blob مع جودة الضغط
      final qualityValue = quality / 100.0;
      final compressedBlob = await canvas.toBlob('image/jpeg', qualityValue);

      // قراءة البيانات من Blob
      final reader = html.FileReader();
      final completer2 = Completer<Uint8List>();

      reader.onLoadEnd.listen((_) {
        final result = reader.result as List<int>;
        completer2.complete(Uint8List.fromList(result));
      });

      reader.onError.listen((_) {
        completer2.completeError('خطأ في قراءة البيانات المضغوطة');
      });

      reader.readAsArrayBuffer(compressedBlob);

      final compressedBytes = await completer2.future;

      // تنظيف الذاكرة
      html.Url.revokeObjectUrl(url);

      debugPrint('تم ضغط الصورة باستخدام Canvas:');
      debugPrint('- الأبعاد الأصلية: ${originalWidth}x$originalHeight');
      debugPrint('- الأبعاد الجديدة: ${newWidth}x$newHeight');
      debugPrint('- الجودة: $quality%');

      return compressedBytes;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة باستخدام Canvas: $e');
      return null;
    }
  }

  /// ضغط البيانات مع تحديد الأبعاد
  Future<Uint8List?> _compressImageBytesWebWithDimensions(
    Uint8List imageBytes, {
    int quality = 85,
    int maxWidth = 1200,
    int maxHeight = 1200,
  }) async {
    try {
      debugPrint('بدء الضغط مع الأبعاد المحددة باستخدام Canvas API');

      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final image = html.ImageElement();
      final completer = Completer<html.ImageElement>();

      image.onLoad.listen((_) => completer.complete(image));
      image.onError.listen((_) => completer.completeError('خطأ في تحميل الصورة'));
      image.src = url;

      final loadedImage = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'انتهت مهلة تحميل الصورة',
      );

      final originalWidth = loadedImage.naturalWidth!;
      final originalHeight = loadedImage.naturalHeight!;

      // حساب الأبعاد الجديدة
      double ratio = 1.0;
      if (originalWidth > maxWidth || originalHeight > maxHeight) {
        ratio = (maxWidth / originalWidth < maxHeight / originalHeight)
            ? maxWidth / originalWidth
            : maxHeight / originalHeight;
      }

      final newWidth = (originalWidth * ratio).round();
      final newHeight = (originalHeight * ratio).round();

      // إنشاء Canvas بالأبعاد الجديدة
      final canvas = html.CanvasElement(width: newWidth, height: newHeight);
      final context = canvas.getContext('2d') as html.CanvasRenderingContext2D;

      context.imageSmoothingEnabled = true;
      context.imageSmoothingQuality = 'high';

      context.drawImageScaled(loadedImage, 0, 0, newWidth, newHeight);

      final qualityValue = quality / 100.0;
      final compressedBlob = await canvas.toBlob('image/jpeg', qualityValue);

      final reader = html.FileReader();
      final completer2 = Completer<Uint8List>();

      reader.onLoadEnd.listen((_) {
        final result = reader.result as List<int>;
        completer2.complete(Uint8List.fromList(result));
      });

      reader.onError.listen((_) {
        completer2.completeError('خطأ في قراءة البيانات المضغوطة');
      });

      reader.readAsArrayBuffer(compressedBlob);

      final compressedBytes = await completer2.future;
      html.Url.revokeObjectUrl(url);

      debugPrint('تم ضغط الصورة مع الأبعاد المحددة:');
      debugPrint('- الأبعاد الأصلية: ${originalWidth}x$originalHeight');
      debugPrint('- الأبعاد الجديدة: ${newWidth}x$newHeight');
      debugPrint('- الحد الأقصى: ${maxWidth}x$maxHeight');

      return compressedBytes;
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة مع الأبعاد المحددة: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      int size = 0;

      if (file is _WebFile) {
        size = file.bytes.length;
      } else if (_webFileCache.containsKey(file.path)) {
        size = _webFileCache[file.path]!.length;
      } else {
        try {
          final bytes = await file.readAsBytes();
          _webFileCache[file.path] = bytes;
          size = bytes.length;
        } catch (e) {
          debugPrint('خطأ في قراءة حجم الملف للويب: $e');
          size = 0;
        }
      }

      final sizeInMB = size / (1024 * 1024);
      final sizeInKB = size / 1024;

      return {
        'size': size,
        'sizeInMB': sizeInMB,
        'sizeInKB': sizeInKB,
        'path': file.path,
        'exists': true, // في الويب، الملفات موجودة في الكاش
        'platform': 'web',
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات الملف للويب: $e');
      return {
        'size': 0,
        'sizeInMB': 0.0,
        'sizeInKB': 0.0,
        'path': file.path,
        'exists': false,
        'platform': 'web',
      };
    }
  }

  @override
  Future<void> cleanupTempFiles() async {
    try {
      _webFileCache.clear();
      debugPrint('تم تنظيف كاش الملفات في الويب');
    } catch (e) {
      debugPrint('خطأ في تنظيف الملفات المؤقتة للويب: $e');
    }
  }

  @override
  Uint8List? getWebFileData(String fileName) {
    return _webFileCache[fileName];
  }
}

/// كلاس محاكاة لـ File لاستخدامه في الويب
class _WebFile implements File {
  @override
  final String path;
  final Uint8List bytes;

  _WebFile(this.path, this.bytes);

  @override
  Future<Uint8List> readAsBytes() async {
    return bytes;
  }

  @override
  Uint8List readAsBytesSync() {
    return bytes;
  }

  @override
  int lengthSync() {
    return bytes.length;
  }

  @override
  Future<int> length() async {
    return bytes.length;
  }

  @override
  Future<bool> exists() async {
    return true;
  }

  @override
  bool existsSync() {
    return true;
  }

  // تنفيذ باقي الطرق المطلوبة من File
  @override
  File get absolute => this;

  @override
  Future<File> copy(String newPath) async {
    throw UnsupportedError('Copy operation not supported for WebFile');
  }

  @override
  File copySync(String newPath) {
    throw UnsupportedError('Copy operation not supported for WebFile');
  }

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    return this;
  }

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    // لا حاجة لعمل شيء في الويب
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    return this;
  }

  @override
  void deleteSync({bool recursive = false}) {
    // لا حاجة لعمل شيء في الويب
  }

  @override
  Future<DateTime> lastAccessed() async {
    return DateTime.now();
  }

  @override
  DateTime lastAccessedSync() {
    return DateTime.now();
  }

  @override
  Future<DateTime> lastModified() async {
    return DateTime.now();
  }

  @override
  DateTime lastModifiedSync() {
    return DateTime.now();
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    throw UnsupportedError('Open operation not supported for WebFile');
  }

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    throw UnsupportedError('Open operation not supported for WebFile');
  }

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    return Stream.value(bytes);
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    throw UnsupportedError('OpenWrite operation not supported for WebFile');
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    return encoding.decode(bytes);
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    return encoding.decode(bytes);
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) async {
    return (await readAsString(encoding: encoding)).split('\n');
  }

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    return readAsStringSync(encoding: encoding).split('\n');
  }

  @override
  Future<File> rename(String newPath) async {
    return _WebFile(newPath, bytes);
  }

  @override
  File renameSync(String newPath) {
    return _WebFile(newPath, bytes);
  }

  @override
  Future<String> resolveSymbolicLinks() async {
    return path;
  }

  @override
  String resolveSymbolicLinksSync() {
    return path;
  }

  @override
  Future<void> setLastAccessed(DateTime time) async {
    // لا حاجة لعمل شيء في الويب
  }

  @override
  void setLastAccessedSync(DateTime time) {
    // لا حاجة لعمل شيء في الويب
  }

  @override
  Future<void> setLastModified(DateTime time) async {
    // لا حاجة لعمل شيء في الويب
  }

  @override
  void setLastModifiedSync(DateTime time) {
    // لا حاجة لعمل شيء في الويب
  }

  @override
  Future<FileStat> stat() async {
    return _WebFileStat(bytes.length);
  }

  @override
  FileStat statSync() {
    return _WebFileStat(bytes.length);
  }

  @override
  Stream<FileSystemEvent> watch({int events = FileSystemEvent.all, bool recursive = false}) {
    return const Stream.empty();
  }

  @override
  Future<File> writeAsBytes(List<int> bytes, {FileMode mode = FileMode.write, bool flush = false}) async {
    throw UnsupportedError('WriteAsBytes operation not supported for WebFile');
  }

  @override
  void writeAsBytesSync(List<int> bytes, {FileMode mode = FileMode.write, bool flush = false}) {
    throw UnsupportedError('WriteAsBytes operation not supported for WebFile');
  }

  @override
  Future<File> writeAsString(String contents, {FileMode mode = FileMode.write, Encoding encoding = utf8, bool flush = false}) async {
    throw UnsupportedError('WriteAsString operation not supported for WebFile');
  }

  @override
  void writeAsStringSync(String contents, {FileMode mode = FileMode.write, Encoding encoding = utf8, bool flush = false}) {
    throw UnsupportedError('WriteAsString operation not supported for WebFile');
  }

  @override
  Directory get parent => throw UnsupportedError('Parent directory not supported for WebFile');

  @override
  bool get isAbsolute => true;

  @override
  Uri get uri => Uri.file(path);
}

/// كلاس محاكاة لـ FileStat لاستخدامه في الويب
class _WebFileStat implements FileStat {
  final int _size;

  _WebFileStat(this._size);

  @override
  DateTime get accessed => DateTime.now();

  @override
  DateTime get changed => DateTime.now();

  @override
  int get mode => 0;

  @override
  String modeString() => 'rw-r--r--';

  @override
  DateTime get modified => DateTime.now();

  @override
  int get size => _size;

  @override
  FileSystemEntityType get type => FileSystemEntityType.file;
}
