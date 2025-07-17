import 'package:flutter/services.dart';

class GoogleApiFix {
  static const MethodChannel _channel = MethodChannel('google_api_fix');

  /// إصلاح مشاكل Google API في المحاكي
  static Future<void> fixGoogleApiIssues() async {
    try {
      await _channel.invokeMethod('fixGoogleApiIssues');
    } catch (e) {
      // تجاهل الأخطاء في المحاكي
      print('Google API fix not available on this platform: $e');
    }
  }

  /// التحقق من توفر Google Play Services
  static Future<bool> isGooglePlayServicesAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isGooglePlayServicesAvailable');
      return result;
    } catch (e) {
      // في المحاكي، نفترض أن Google Play Services غير متوفرة
      return false;
    }
  }
} 