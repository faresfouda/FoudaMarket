import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../components/Button.dart';
import '../../components/connection_aware_widget.dart';
import '../../components/otp_input_field.dart';
import '../../routes.dart';
import 'complete_profile_screen.dart';

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
  String otpCode = '';
  bool _isLoading = false;
  int _timeLeft = 60;
  bool _canResend = false;
  bool _isOffline = false;

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
    if (otpCode.isEmpty || otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("من فضلك أدخل رمز التحقق كاملاً")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: otpCode,
    );

    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تم تسجيل الدخول بنجاح")),
          );
          BlocProvider.of<AuthBloc>(context).add(AuthCheckRequested());
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                phone: user.phoneNumber ?? '',
                uid: user.uid,
              ),
            ),
            (route) => false,
          );
        }
      }
      setState(() {
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      String errorMsg = e.message ?? "فشل في تسجيل الدخول";
      if (e.code == 'invalid-verification-code') {
        errorMsg = 'الكود غير صحيح.';
      } else if (e.code == 'session-expired') {
        errorMsg = 'انتهت صلاحية الكود. أعد الإرسال.';
      } else if (e.code == 'network-request-failed') {
        errorMsg = 'تحقق من اتصال الإنترنت.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "فشل إرسال الكود")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم إرسال الكود مرة أخرى")),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تم تسجيل الدخول بنجاح")),
          );
          BlocProvider.of<AuthBloc>(context).add(AuthCheckRequested());
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                phone: user.phoneNumber ?? '',
                uid: user.uid,
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في تسجيل الدخول")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionAwareWidget(
      onConnectionChanged: (offline) {
        if (_isOffline != offline) {
          setState(() {
            _isOffline = offline;
          });
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (state.userProfile != null) {
              switch (state.userProfile!.role) {
                case 'admin':
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.adminDashboard,
                    (route) => false,
                  );
                  break;
                case 'data_entry':
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.dataEntryHome,
                    (route) => false,
                  );
                  break;
                default:
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.main,
                    (route) => false,
                  );
                  break;
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ في بيانات المستخدم'),
                  backgroundColor: Colors.red,
                ),
              );
              context.read<AuthBloc>().add(SignOutRequested());
            }
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.authSelection);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Image.asset('assets/login/logo.png'),
                      Positioned(
                        top: 25,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.blackColor,
                          ),
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.authSelection),
                        ),
                      ),
                    ],
                  ),
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
                    child: OtpInputField(
                      onCompleted: (value) {
                        setState(() {
                          otpCode = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Button(
                      onPressed: (_isLoading || _isOffline) ? null : verifyCode,
                      buttonContent: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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
                        _canResend
                            ? 'لم يصلك الكود؟'
                            : 'يمكنك إعادة الإرسال بعد $_timeLeft ثانية',
                        style: TextStyle(
                          color: AppColors.mediumGrayColor,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: (!_canResend || _isOffline) ? null : resendCode,
                        child: Text('إعادة الإرسال'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
