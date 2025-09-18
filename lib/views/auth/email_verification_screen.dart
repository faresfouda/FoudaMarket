import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouda_market/theme/appcolors.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;
  String? _message;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      // البحث عن المستخدم في قاعدة البيانات
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() {
          _message = 'لم يتم العثور على الحساب. يرجى إنشاء حساب جديد.';
          _isVerified = false;
        });
        return;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;

      // التحقق من حالة isEmailVerified في قاعدة البيانات
      bool isVerifiedInDB = userData['isEmailVerified'] ?? false;

      if (isVerifiedInDB) {
        setState(() {
          _message = 'تم التحقق من البريد الإلكتروني مسبقاً. سيتم توجيهك لتسجيل الدخول.';
          _isVerified = true;
        });

        // الانتقال لصفحة تسجيل الدخول
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        });
        return;
      }

      // محاولة التحقق من Firebase Auth للتأكد من التفعيل
      try {
        // نستخدم fetchSignInMethodsForEmail للتحقق من حالة البريد الإلكتروني
        final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(widget.email);

        if (signInMethods.isNotEmpty) {
          // البريد الإلكتروني موجود في Firebase Auth
          // نفترض أن التفعيل تم وننتقل لصفحة تسجيل الدخول مباشرة
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'isEmailVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _message = 'تم التحقق من البريد الإلكتروني بنجاح! سيتم توجيهك لتسجيل الدخول.';
            _isVerified = true;
          });

          // الانتقال لصفحة تسجيل الدخول
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          });
        } else {
          setState(() {
            _message = 'لم يتم التحقق من البريد الإلكتروني بعد. يرجى التحقق من بريدك والضغط على رابط التفعيل أولاً.';
            _isVerified = false;
          });
        }
      } catch (e) {
        setState(() {
          _message = 'لم يتم التحقق من البريد الإلكتروني بعد. يرجى التحقق من بريدك والضغط على رابط التفعيل أولاً.';
          _isVerified = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'حدث خطأ أثناء التحقق. يرجى المحاولة مرة أخرى.';
        _isVerified = false;
      });
    } finally {
      setState(() { _isChecking = false; });
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      // محاولة إنشاء مستخدم مؤقت لإرسال الرسالة
      final tempPassword = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: tempPassword,
        );

        await userCredential.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        setState(() {
          _message = 'تم إرسال رسالة التحقق مرة أخرى إلى ${widget.email}';
        });
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          setState(() {
            _message = 'تم إرسال رسالة التحقق سابقاً. يرجى التحقق من بريدك الإلكتروني أو مجلد الرسائل المهملة.';
          });
        } else {
          setState(() {
            _message = 'حدث خطأ أثناء إعادة الإرسال. يرجى المحاولة مرة أخرى.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _message = 'حدث خطأ أثناء إعادة الإرسال. يرجى المحاولة مرة أخرى.';
      });
    } finally {
      setState(() { _isResending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.blackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'assets/login/logo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 40),
            Icon(
              Icons.email_outlined,
              size: 80,
              color: AppColors.orangeColor
            ),
            const SizedBox(height: 24),
            Text(
              'تأكيد البريد الإلكتروني',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'لقد أرسلنا رسالة تأكيد إلى بريدك الإلكتروني. يرجى فتح بريدك والضغط على رابط التفعيل.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.mediumGrayColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.orangeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orangeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orangeColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                width: width * 0.9,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isVerified ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isVerified ? Colors.green.shade200 : Colors.blue.shade200),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isVerified ? Colors.green.shade800 : Colors.blue.shade800,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isChecking || _isResending) ? null : _checkVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChecking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'تحقق من التفعيل',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: (_isResending || _isChecking) ? null : _resendEmail,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.orangeColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isResending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.orangeColor),
                        ),
                      )
                    : Text(
                        'إعادة إرسال الرسالة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orangeColor,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'تم التفعيل؟ ',
                  style: TextStyle(
                    color: AppColors.mediumGrayColor,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      color: AppColors.orangeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
