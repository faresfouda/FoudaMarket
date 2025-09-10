import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static const String _cacheDirName = 'image_cache';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const int _maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

  Directory? _cacheDir;
  final Map<String, DateTime> _cacheTimestamps = {};

  /// تهيئة مجلد التخزين المؤقت
  Future<void> initialize() async {
    // تجاهل التهيئة للويب لأنه يستخدم ذاكرة التخزين المؤقت للمتصفح
    if (kIsWeb) {
      debugPrint('ImageCacheService: Web platform detected, using browser cache');
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      // تحميل timestamps الموجودة
      await _loadCacheTimestamps();
      
      // تنظيف التخزين المؤقت القديم
      await _cleanupOldCache();
      
      debugPrint('ImageCacheService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ImageCacheService: $e');
    }
  }

  /// تحميل timestamps من ملف
  Future<void> _loadCacheTimestamps() async {
    if (kIsWeb) return;

    try {
      final timestampsFile = File('${_cacheDir!.path}/timestamps.json');
      if (await timestampsFile.exists()) {
        final content = await timestampsFile.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        _cacheTimestamps.clear();
        data.forEach((key, value) {
          _cacheTimestamps[key] = DateTime.parse(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading cache timestamps: $e');
    }
  }

  /// حفظ timestamps إلى ملف
  Future<void> _saveCacheTimestamps() async {
    if (kIsWeb) return;

    try {
      final timestampsFile = File('${_cacheDir!.path}/timestamps.json');
      final Map<String, String> data = {};
      _cacheTimestamps.forEach((key, value) {
        data[key] = value.toIso8601String();
      });
      await timestampsFile.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving cache timestamps: $e');
    }
  }

  /// إنشاء مفتاح فريد للصورة
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// الحصول على مسار الملف في التخزين المؤقت
  String _getCacheFilePath(String cacheKey) {
    if (kIsWeb) return '';
    return '${_cacheDir!.path}/$cacheKey.jpg';
  }

  /// حفظ صورة في التخزين المؤقت
  Future<String?> cacheImage(String url, Uint8List imageData) async {
    // للويب: لا نحتاج تخزين مؤقت لأن المتصفح يتولى ذلك
    if (kIsWeb) {
      debugPrint('ImageCacheService: Web platform uses browser cache for $url');
      return null;
    }

    try {
      if (_cacheDir == null) await initialize();
      
      final cacheKey = _generateCacheKey(url);
      final cachePath = _getCacheFilePath(cacheKey);
      
      // حفظ الصورة
      final file = File(cachePath);
      await file.writeAsBytes(imageData);
      
      // تحديث timestamp
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveCacheTimestamps();
      
      // التحقق من حجم التخزين المؤقت
      await _checkCacheSize();
      
      debugPrint('Image cached successfully: $cachePath');
      return cachePath;
    } catch (e) {
      debugPrint('Error caching image: $e');
      return null;
    }
  }

  /// الحصول على صورة من التخزين المؤقت
  Future<File?> getCachedImage(String url) async {
    // للويب: إرجاع null لأن المتصفح يتولى التخزين المؤقت
    if (kIsWeb) {
      return null;
    }

    try {
      if (_cacheDir == null) await initialize();
      
      final cacheKey = _generateCacheKey(url);
      final cachePath = _getCacheFilePath(cacheKey);
      final file = File(cachePath);
      
      if (await file.exists()) {
        // التحقق من عمر الملف
        final timestamp = _cacheTimestamps[cacheKey];
        if (timestamp != null) {
          final age = DateTime.now().difference(timestamp).inMilliseconds;
          if (age > _maxCacheAge) {
            // الملف قديم، احذفه
            await file.delete();
            _cacheTimestamps.remove(cacheKey);
            await _saveCacheTimestamps();
            return null;
          }
        }

        debugPrint('Found cached image: $cachePath');
        return file;
      }
    } catch (e) {
      debugPrint('Error getting cached image: $e');
    }

    return null;
  }

  /// التحقق من وجود صورة في التخزين المؤقت
  Future<bool> isImageCached(String url) async {
    try {
      if (_cacheDir == null) await initialize();
      
      final cacheKey = _generateCacheKey(url);
      final cachePath = _getCacheFilePath(cacheKey);
      final file = File(cachePath);
      
      if (await file.exists()) {
        final timestamp = _cacheTimestamps[cacheKey];
        if (timestamp != null) {
          final age = DateTime.now().difference(timestamp).inMilliseconds;
          return age < _maxCacheAge;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking cached image: $e');
      return false;
    }
  }

  /// الحصول على معلومات مساحة التخزين المؤقت
  Future<CacheInfo> getCacheInfo() async {
    try {
      if (_cacheDir == null) await initialize();
      
      int totalSize = 0;
      int fileCount = 0;
      int validFiles = 0;
      
      if (await _cacheDir!.exists()) {
        final files = await _cacheDir!.list().toList();
        
        for (final entity in files) {
          if (entity is File && entity.path.endsWith('.jpg')) {
            final size = await entity.length();
            totalSize += size;
            fileCount++;
            
            // التحقق من صحة الملف
            final fileName = entity.path.split('/').last;
            final timestamp = _cacheTimestamps[fileName];
            if (timestamp != null) {
              final age = DateTime.now().difference(timestamp).inMilliseconds;
              if (age < _maxCacheAge) {
                validFiles++;
              }
            }
          }
        }
      }
      
      return CacheInfo(
        totalSize: totalSize,
        fileCount: fileCount,
        validFiles: validFiles,
        maxSize: _maxCacheSize,
        maxAge: _maxCacheAge,
      );
    } catch (e) {
      debugPrint('Error getting cache info: $e');
      return CacheInfo(
        totalSize: 0,
        fileCount: 0,
        validFiles: 0,
        maxSize: _maxCacheSize,
        maxAge: _maxCacheAge,
      );
    }
  }

  /// تنظيف التخزين المؤقت القديم
  Future<void> _cleanupOldCache() async {
    if (kIsWeb) return;

    try {
      if (_cacheDir == null) return;

      final now = DateTime.now();
      final filesToDelete = <String>[];

      _cacheTimestamps.forEach((cacheKey, timestamp) {
        final age = now.difference(timestamp).inMilliseconds;
        if (age > _maxCacheAge) {
          filesToDelete.add(cacheKey);
        }
      });
      
      for (final cacheKey in filesToDelete) {
        final cachePath = _getCacheFilePath(cacheKey);
        final file = File(cachePath);
        if (await file.exists()) {
          await file.delete();
        }
        _cacheTimestamps.remove(cacheKey);
      }
      
      if (filesToDelete.isNotEmpty) {
        await _saveCacheTimestamps();
        debugPrint('Cleaned up ${filesToDelete.length} old cached images');
      }
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
  }

  /// التحقق من حجم التخزين المؤقت
  Future<void> _checkCacheSize() async {
    if (kIsWeb) return;

    try {
      if (_cacheDir == null) return;

      int totalSize = 0;
      final files = await _cacheDir!.list().toList();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      if (totalSize > _maxCacheSize) {
        debugPrint('Cache size exceeded, cleaning up...');
        await _cleanupOldCache();
      }
    } catch (e) {
      debugPrint('Error checking cache size: $e');
    }
  }

  /// مسح جميع الصور المخزنة مؤقتاً
  Future<void> clearCache() async {
    if (kIsWeb) {
      debugPrint('ImageCacheService: Cannot clear browser cache programmatically');
      return;
    }

    try {
      if (_cacheDir == null) return;

      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      }
      
      _cacheTimestamps.clear();
      await _saveCacheTimestamps();
      
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// الحصول على حجم التخزين المؤقت
  Future<int> getCacheSize() async {
    if (kIsWeb) return 0;

    try {
      if (_cacheDir == null) return 0;

      int totalSize = 0;
      final files = await _cacheDir!.list().toList();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }
}

/// معلومات التخزين المؤقت
class CacheInfo {
  final int totalSize; // بالبايت
  final int fileCount;
  final int validFiles;
  final int maxSize;
  final int maxAge;

  CacheInfo({
    required this.totalSize,
    required this.fileCount,
    required this.validFiles,
    required this.maxSize,
    required this.maxAge,
  });

  /// الحصول على حجم التخزين المؤقت بالميجابايت
  double get totalSizeMB => totalSize / (1024 * 1024);
  
  /// الحصول على الحد الأقصى بالميجابايت
  double get maxSizeMB => maxSize / (1024 * 1024);
  
  /// الحصول على نسبة الاستخدام
  double get usagePercentage => (totalSize / maxSize) * 100;
  
  /// الحصول على العمر الأقصى بالأيام
  int get maxAgeDays => maxAge ~/ (24 * 60 * 60 * 1000);

  @override
  String toString() {
    return 'CacheInfo(totalSize: ${totalSizeMB.toStringAsFixed(2)} MB, '
           'fileCount: $fileCount, validFiles: $validFiles, '
           'usagePercentage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}
