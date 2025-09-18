import 'package:flutter/material.dart';
import 'package:fouda_market/core/services/onboarding_service.dart';
import 'package:fouda_market/views/onbording/OnBording.dart';
import 'package:fouda_market/core/auth_wrapper.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final isCompleted = await OnboardingService.isOnboardingCompleted();

      if (mounted) {
        setState(() {
          _showOnboarding = !isCompleted;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('خطأ في التحقق من حالة Onboarding: $e');
      if (mounted) {
        setState(() {
          _showOnboarding = false; // في حالة الخطأ، نتخطى Onboarding
          _isLoading = false;
        });
      }
    }
  }

  void _onOnboardingFinish() async {
    try {
      await OnboardingService.markOnboardingCompleted();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } catch (e) {
      print('خطأ في حفظ حالة Onboarding: $e');
      // حتى لو فشل الحفظ، ننتقل للشاشة التالية
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showOnboarding) {
      return OnBording(onFinish: _onOnboardingFinish);
    } else {
      return const AuthWrapper();
    }
  }
}
