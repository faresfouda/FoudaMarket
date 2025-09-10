import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';
import 'package:http/http.dart' as http;

class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  late Future<dynamic> _imageDataFuture;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageDataFuture = _loadImage();
  }

  Future<dynamic> _loadImage() async {
    try {
      // للويب: استخدم Network Image مباشرة
      if (kIsWeb) {
        // التحقق من صحة الرابط أولاً
        final response = await http.head(Uri.parse(widget.imageUrl)).timeout(
          const Duration(seconds: 10),
        );
        if (response.statusCode == 200) {
          return widget.imageUrl; // إرجاع الرابط للويب
        } else {
          throw Exception('Image not found: ${response.statusCode}');
        }
      }

      // للموبايل: استخدم الكاش كما هو
      final cachedFile = await ImageCacheService().getCachedImage(
        widget.imageUrl,
      );
      if (cachedFile != null) {
        return cachedFile;
      }

      // تحميل الصورة من الإنترنت للموبايل
      final response = await http.get(Uri.parse(widget.imageUrl)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 200) {
        final filePath = await ImageCacheService().cacheImage(
          widget.imageUrl,
          response.bodyBytes,
        );
        if (filePath != null) {
          return File(filePath);
        }
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      setState(() {
        _hasError = true;
      });
    }
    return null;
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ?? Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ?? Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: (widget.width != null && widget.width!.isFinite && widget.width! > 0)
            ? widget.width! * 0.3
            : 24,
        color: Colors.grey[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // إذا كان هناك خطأ، اعرض الخطأ مباشرة
    if (_hasError) {
      return _buildErrorWidget();
    }

    return FutureBuilder<dynamic>(
      future: _imageDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildErrorWidget();
        }

        // للويب: استخدم Image.network
        if (kIsWeb && snapshot.data is String) {
          return Image.network(
            snapshot.data as String,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildPlaceholder();
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Network image error: $error');
              return _buildErrorWidget();
            },
          );
        }

        // للموبايل: استخدم Image.file
        if (!kIsWeb && snapshot.data is File) {
          return Image.file(
            snapshot.data as File,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('File image error: $error');
              return _buildErrorWidget();
            },
          );
        }

        // في حالة عدم التطابق
        return _buildErrorWidget();
      },
    );
  }
}
