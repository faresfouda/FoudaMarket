import 'dart:typed_data';
import 'dart:io';
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
  late Future<File?> _imageFileFuture;

  @override
  void initState() {
    super.initState();
    _imageFileFuture = _loadImage();
  }

  Future<File?> _loadImage() async {
    // جرب جلب الصورة من الكاش
    final cachedFile = await ImageCacheService().getCachedImage(widget.imageUrl);
    if (cachedFile != null) {
      return cachedFile;
    }
    // إذا لم تكن موجودة بالكاش، حملها من الإنترنت
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        final filePath = await ImageCacheService().cacheImage(widget.imageUrl, response.bodyBytes);
        if (filePath != null) {
          return File(filePath);
        }
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _imageFileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
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
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image_not_supported,
              size: widget.width != null ? widget.width! * 0.3 : 24,
              color: Colors.grey[400],
            ),
          );
        } else {
          return Image.file(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.broken_image,
                  size: widget.width != null ? widget.width! * 0.3 : 24,
                  color: Colors.grey[400],
                ),
              );
            },
          );
        }
      },
    );
  }
} 