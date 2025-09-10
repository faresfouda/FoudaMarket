import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class WebImagePickerService {
  /// اختيار صورة واحدة من الجهاز على الويب
  static Future<Uint8List?> pickImageWeb() async {
    if (!kIsWeb) {
      throw Exception('This service is only available on web platform');
    }

    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      await uploadInput.onChange.first;

      if (uploadInput.files!.isEmpty) return null;

      final html.File file = uploadInput.files!.first;
      final html.FileReader reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      return reader.result as Uint8List;
    } catch (e) {
      print('Error picking image on web: $e');
      return null;
    }
  }

  /// اختيار عدة صور من الجهاز على الويب
  static Future<List<Uint8List>> pickMultipleImagesWeb() async {
    if (!kIsWeb) {
      throw Exception('This service is only available on web platform');
    }

    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.multiple = true;
      uploadInput.click();

      await uploadInput.onChange.first;

      if (uploadInput.files!.isEmpty) return [];

      final List<Uint8List> imageBytes = [];

      for (final html.File file in uploadInput.files!) {
        final html.FileReader reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        imageBytes.add(reader.result as Uint8List);
      }

      return imageBytes;
    } catch (e) {
      print('Error picking multiple images on web: $e');
      return [];
    }
  }

  /// التحقق من نوع الملف
  static bool isValidImageType(String fileName) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final lowerFileName = fileName.toLowerCase();
    return validExtensions.any((ext) => lowerFileName.endsWith(ext));
  }

  /// الحصول على حجم الملف بالميجابايت
  static double getFileSizeInMB(int bytes) {
    return bytes / (1024 * 1024);
  }
}
