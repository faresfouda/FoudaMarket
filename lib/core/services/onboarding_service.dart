import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';

  /// التحقق من إكمال Onboarding
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      print('خطأ في التحقق من حالة Onboarding: $e');
      return false;
    }
  }

  /// تحديد إكمال Onboarding
  static Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      print('تم تحديد إكمال Onboarding');
    } catch (e) {
      print('خطأ في حفظ حالة Onboarding: $e');
    }
  }

  /// إعادة تعيين حالة Onboarding (للتطوير)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingKey);
      print('تم إعادة تعيين حالة Onboarding');
    } catch (e) {
      print('خطأ في إعادة تعيين حالة Onboarding: $e');
    }
  }
}
