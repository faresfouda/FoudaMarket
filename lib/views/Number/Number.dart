import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fodamarket/components/phonetextfield.dart';
import 'package:fodamarket/components/navigatorbutton.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:get/get.dart';

import '../../components/Button.dart';
import '../home/main_screen.dart';
import 'package:fodamarket/views/SignIn/SignIn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'complete_profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/data_entry_home_screen.dart';

class Number extends StatefulWidget {
  const Number({super.key});

  @override
  State<Number> createState() => _NumberState();
}

class _NumberState extends State<Number> {
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;

  void sendCode() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      Get.snackbar("تنبيه", "من فضلك أدخل رقم الهاتف");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+20$phone',
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification if SMS is received automatically
        _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar("خطأ", e.message ?? "فشل التحقق");
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
        });
        Get.to(() => OtpScreen(
          verificationId: verificationId,
          phoneNumber: '+20$phone',
        ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  void _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Get.snackbar("تم", "تم تسجيل الدخول بنجاح");
          final userData = doc.data() as Map<String, dynamic>;
          final userRole = userData['role'] ?? 'user';
          
          switch (userRole) {
            case 'admin':
              Get.offAll(() => AdminDashboardMain());
              break;
            case 'data_entry':
              Get.offAll(() => DataEntryHomeScreen());
              break;
            default:
              Get.offAll(() => MainScreen());
          }
        } else {
          Get.offAll(() => CompleteProfileScreen(phone: user.phoneNumber ?? '', uid: user.uid));
        }
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل في تسجيل الدخول");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SignIn()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.blackColor),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => SignIn()),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'أدخل رقم الهاتف',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'سنرسل لك رمز التحقق عبر الرسائل النصية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mediumGrayColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'رقم الهاتف',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mediumGrayColor,
                ),
              ),
              SizedBox(height: 8),
              PhoneTextField(
                controller: phoneController,
                autofocus: true,
                onTap: () {},
              ),
              SizedBox(height: 30),
              Button(
                onPressed: _isLoading ? () {} : sendCode,
                buttonContent: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'إرسال رمز التحقق',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                buttonColor: AppColors.orangeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool _isLoading = false;
  int _timeLeft = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
            _startTimer();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  void verifyCode() async {
    final smsCode = otpController.text.trim();
    
    if (smsCode.isEmpty) {
      Get.snackbar("تنبيه", "من فضلك أدخل رمز التحقق");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: smsCode,
    );

    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Get.snackbar("تم", "تم تسجيل الدخول بنجاح");
          final userData = doc.data() as Map<String, dynamic>;
          final userRole = userData['role'] ?? 'user';
          
          switch (userRole) {
            case 'admin':
              Get.offAll(() => AdminDashboardMain());
              break;
            case 'data_entry':
              Get.offAll(() => DataEntryHomeScreen());
              break;
            default:
              Get.offAll(() => MainScreen());
          }
        } else {
          Get.offAll(() => CompleteProfileScreen(phone: user.phoneNumber ?? '', uid: user.uid));
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar("خطأ", "الكود غير صحيح");
    }
  }

  void resendCode() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _timeLeft = 60;
    });

    _startTimer();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        Get.snackbar("خطأ", e.message ?? "فشل إرسال الكود");
      },
      codeSent: (String verificationId, int? resendToken) {
        Get.snackbar("تم", "تم إرسال الكود مرة أخرى");
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Get.snackbar("تم", "تم تسجيل الدخول بنجاح");
          final userData = doc.data() as Map<String, dynamic>;
          final userRole = userData['role'] ?? 'user';
          
          switch (userRole) {
            case 'admin':
              Get.offAll(() => AdminDashboardMain());
              break;
            case 'data_entry':
              Get.offAll(() => DataEntryHomeScreen());
              break;
            default:
              Get.offAll(() => MainScreen());
          }
        } else {
          Get.offAll(() => CompleteProfileScreen(phone: user.phoneNumber ?? '', uid: user.uid));
        }
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل في تسجيل الدخول");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SignIn()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.blackColor),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => SignIn()),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/login/logo.png'),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'أدخل الكود المرسل إلى ${widget.phoneNumber}',
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "كود التحقق",
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.orangeColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child:                   Button(
                      onPressed: _isLoading ? () {} : verifyCode,
                    buttonContent: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'تأكيد',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    buttonColor: AppColors.orangeColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لم تستلم الكود؟ ',
                      style: TextStyle(
                        color: AppColors.mediumGrayColor,
                        fontSize: 14,
                      ),
                    ),
                    if (_canResend)
                      GestureDetector(
                        onTap: resendCode,
                        child: Text(
                          'إعادة إرسال',
                          style: TextStyle(
                            color: AppColors.orangeColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        'إعادة إرسال خلال $_timeLeft ثانية',
                        style: TextStyle(
                          color: AppColors.mediumGrayColor,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
