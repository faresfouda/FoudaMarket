import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/components/Button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isVerified = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    if (user != null && user.emailVerified) {
      setState(() {
        _isVerified = true;
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() { _isResending = true; _message = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      setState(() { _message = 'تم إرسال رسالة التحقق مرة أخرى.'; });
    } catch (e) {
      setState(() { _message = 'حدث خطأ أثناء إعادة الإرسال.'; });
    } finally {
      setState(() { _isResending = false; });
    }
  }

  Future<void> _openMailApp() async {
    // يمكن استخدام حزمة مثل url_launcher لفتح تطبيق البريد
    // هنا placeholder فقط
    setState(() { _message = 'يرجى فتح تطبيق البريد الإلكتروني يدوياً.'; });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Image.asset(
                  'assets/login/logo.png'
                ),
              ),
              const SizedBox(height: 32),
              Icon(Icons.email_outlined, size: 64, color: AppColors.orangeColor),
              const SizedBox(height: 24),
              Text(
                'تأكيد البريد الإلكتروني',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'لقد أرسلنا رسالة تأكيد إلى بريدك الإلكتروني التالي. يرجى فتح بريدك والضغط على رابط التفعيل، ثم العودة للتطبيق.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.mediumGrayColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                width: width * 0.9,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightBlueColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkBlueColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              if (_message != null) ...[
                Text(_message!, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
              ],
              Button(
                onPressed: _isResending ? null : _resendEmail,
                buttonContent: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: Colors.white),
                    SizedBox(width: 8),
                    Text(_isResending ? 'جاري الإرسال...' : 'إعادة إرسال رسالة التحقق'),
                  ],
                ),
                buttonColor: AppColors.orangeColor,
              ),
              const SizedBox(height: 32),
              Button(
                onPressed: _isVerified
                    ? () => Navigator.of(context).pop()
                    : () async {
                        await _checkVerification();
                        if (_isVerified) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            _message = 'لم يتم التحقق بعد. يرجى التأكد من الضغط على رابط التفعيل في بريدك.';
                          });
                        }
                      },
                buttonContent: Text(_isVerified ? 'تم التحقق! المتابعة' : 'تحقق من التفعيل ثم اضغط هنا'),
                buttonColor: AppColors.darkBlueColor,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'العودة لتسجيل الدخول',
                  style: TextStyle(
                    color: AppColors.mediumGrayColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 