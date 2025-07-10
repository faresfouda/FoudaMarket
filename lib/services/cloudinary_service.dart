import 'package:cloudinary_public/cloudinary_public.dart';

// تذكر تغيير CLOUD_NAME و UPLOAD_PRESET إلى بيانات حسابك في Cloudinary
class CloudinaryService {
  final cloudinary = CloudinaryPublic('dmmlntyd8', 'Fouda Market', cache: false);

  Future<String?> uploadImage(String filePath) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(filePath, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
} 