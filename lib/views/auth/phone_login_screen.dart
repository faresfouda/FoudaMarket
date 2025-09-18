import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/components/phonetextfield.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../components/Button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'complete_profile_screen.dart';
import '../../routes.dart';
import '../../components/connection_aware_widget.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isOffline = false;

  void sendCode() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("من فضلك أدخل رقم الهاتف")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+20$phone',
      verificationCompleted: (PhoneAuthCredential credential) {
        _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "فشل التحقق")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: '+2$phone',
            ),
          ),
        );
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
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.authWrapper,
                (route) => false,
              );
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
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: AppColors.blackColor),
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.authSelection),
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
                    onPressed: (_isLoading || _isOffline) ? null : sendCode,
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
        ),
      ),
    );
  }
}

