import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../components/Button.dart';
import '../../components/connection_aware_widget.dart';
import '../../core/services/google_auth_service.dart';
import '../../theme/appcolors.dart';
import '../../routes.dart';
import 'phone_login_screen.dart';


class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isGoogleLoading = false;
  bool _isOffline = false;

  Future<void> _signInWithGoogle() async {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تحقق من اتصال الإنترنت')),
      );
      return;
    }

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final userCredential = await _googleAuthService.signInWithGoogle();

      if (userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
        );

        // تحديث حالة المصادقة
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    } catch (e) {
      String errorMessage = 'فشل في تسجيل الدخول بالجوجل';

      if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'تم إلغاء تسجيل الدخول';
      } else if (e.toString().contains('network_error')) {
        errorMessage = 'خطأ في الشبكة';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'فشل في تسجيل الدخول';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
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
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/login/logo.png',
                          height: 120,
                        ),
                        const SizedBox(height: 40),

                        // Welcome Text
                        Text(
                          'مرحباً بك في فودا ماركت',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'اختر طريقة تسجيل الدخول المفضلة لديك',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGrayColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Google Sign In Button
                        _buildGoogleSignInButton(),
                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: AppColors.lightGrayColor),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'أو',
                                style: TextStyle(
                                  color: AppColors.mediumGrayColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppColors.lightGrayColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Phone Login Button
                        Button(
                          onPressed: _isOffline ? null : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PhoneLoginScreen(),
                              ),
                            );
                          },
                          buttonContent: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone,
                                color: AppColors.whiteColor,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'تسجيل الدخول برقم الهاتف',
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          buttonColor: AppColors.orangeColor,
                        ),
                        const SizedBox(height: 15),

                        // Email Login Button
                        // Button(
                        //   onPressed: _isOffline ? null : () {
                        //     Navigator.of(context).push(
                        //       MaterialPageRoute(
                        //         builder: (context) => EmailLoginScreen(),
                        //       ),
                        //     );
                        //   },
                        //   buttonContent: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Icon(
                        //         Icons.email,
                        //         color: AppColors.orangeColor,
                        //         size: 20,
                        //       ),
                        //       const SizedBox(width: 10),
                        //       Text(
                        //         'تسجيل الدخول بالبريد الإلكتروني',
                        //         style: TextStyle(
                        //           color: AppColors.orangeColor,
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w600,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        //   buttonColor: Colors.white,
                        // ),
                      ],
                    ),
                  ),

                  // Terms and Privacy
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'بتسجيل الدخول، أنت توافق على شروط الخدمة وسياسة الخصوصية',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumGrayColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrayColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isGoogleLoading || _isOffline ? null : _signInWithGoogle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGoogleLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.orangeColor,
                      ),
                    ),
                  )
                else
                  Image.asset(
                    'assets/socialmedia/google.png',
                    height: 24,
                    width: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isGoogleLoading
                      ? 'جاري تسجيل الدخول...'
                      : 'تسجيل الدخول بحساب Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
