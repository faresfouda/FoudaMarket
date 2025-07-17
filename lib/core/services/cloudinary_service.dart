import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic('your-cloud-name', 'your-upload-preset', cache: false);

  Future<String?> uploadImage(String filePath) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(filePath, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
} 