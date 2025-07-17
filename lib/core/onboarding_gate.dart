import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/onbording/OnBording.dart';

class OnboardingGate extends StatefulWidget {
  final Widget child;
  const OnboardingGate({required this.child, super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showOnboarding = !(prefs.getBool('onboarding_seen') ?? false);
    });
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showOnboarding!) {
      // يجب استيراد OnBording من مكانه الصحيح عند الاستخدام
      return OnBording(onFinish: _completeOnboarding);
    }
    return widget.child;
  }
} 