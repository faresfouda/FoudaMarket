import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../components/cached_image.dart';

class ProductImagePicker extends StatelessWidget {
  final dynamic pickedImage; // يمكن أن يكون File أو Uint8List
  final String? imageUrl;
  final VoidCallback onTap;

  const ProductImagePicker({
    super.key,
    this.pickedImage,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (pickedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _buildPickedImage(),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl != null
            ? CachedImage(
                imageUrl: imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.broken_image, size: 48),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            'اضغط لاختيار صورة',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JPG, PNG',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      );
    }
  }

  Widget _buildPickedImage() {
    if (kIsWeb && pickedImage is Uint8List) {
      // على الويب، استخدم Memory Image
      return Image.memory(
        pickedImage as Uint8List,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && pickedImage != null) {
      // على المنصات الأخرى، استخدم File Image
      return Image.file(
        pickedImage,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      return const Icon(Icons.broken_image, size: 48);
    }
  }
}
