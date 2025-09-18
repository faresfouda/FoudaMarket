import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/components/Button.dart';
import 'package:fouda_market/theme/appcolors.dart';
import '../../routes.dart';
import 'package:fouda_market/views/auth/phone_login_screen.dart';
import 'package:fouda_market/views/auth/login_screen.dart';
import 'package:fouda_market/views/auth/sign_up_screen.dart';
import 'package:fouda_market/blocs/auth/index.dart';
import '../../core/services/google_auth_service.dart';
import '../../components/connection_aware_widget.dart';

class AuthSelectionScreen extends StatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
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

  void _navigateBasedOnRole(BuildContext context, Authenticated state) {
    if (state.userProfile != null) {
      switch (state.userProfile!.role) {
        case 'admin':
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          break;
        case 'data_entry':
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.dataEntryHome, (route) => false);
          break;
        case 'user':
        default:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.authWrapper, (route) => false);
      }
    } else {
      // منع الدخول بدون ملف شخصي
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في بيانات المستخدم'),
          backgroundColor: Colors.red,
        ),
      );
      context.read<AuthBloc>().add(SignOutRequested());
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
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            SystemNavigator.pop();
          }
        },
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              _navigateBasedOnRole(context, state);
            } else if (state is AuthError) {
              String errorMsg = state.message;
              if (errorMsg.contains('sign_in_canceled')) {
                errorMsg = 'تم إلغاء تسجيل الدخول من جوجل.';
              } else if (errorMsg.contains('network-request-failed')) {
                errorMsg = 'تحقق من اتصال الإنترنت.';
              } else if (errorMsg.contains(
                'account-exists-with-different-credential',
              )) {
                errorMsg = 'البريد مرتبط بطريقة تسجيل مختلفة.';
              } else if (errorMsg.contains('popup_closed_by_user')) {
                errorMsg = 'تم إغلاق نافذة جوجل قبل إكمال العملية.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
            }
          },
          child: Scaffold(
            body: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Logo and welcome section
                      Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Image(image: AssetImage('assets/login/logo.png')),
                            SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'مرحباً بك في فودة ماركت',
                                style: TextStyle(
                                  color: AppColors.blackColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'اختر طريقة تسجيل الدخول المفضلة لديك',
                                style: TextStyle(
                                  color: AppColors.mediumGrayColor,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Login options
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Google Sign In Button
                            _buildGoogleSignInButton(),
                            SizedBox(height: 20),
                            
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
                            SizedBox(height: 20),

                            // تسجيل الدخول بالبريد الإلكتروني
                            Button(
                              onPressed: (_isOffline) ? null : () {
                                Navigator.pushNamed(context, AppRoutes.login);
                              },
                              buttonContent: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email,
                                    color: AppColors.whiteColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'تسجيل الدخول بالبريد الإلكتروني',
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
                            SizedBox(height: 15),

                            // تسجيل الدخول بالهاتف
                            Button(
                              onPressed: (_isOffline) ? null : () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.phoneLogin,
                                );
                              },
                              buttonContent: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: AppColors.orangeColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'تسجيل الدخول بالهاتف',
                                    style: TextStyle(
                                      color: AppColors.orangeColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              buttonColor: Colors.white,
                              borderColor: AppColors.orangeColor,
                            ),
                          ],
                        ),
                      ),

                      // Spacer to push content to center
                      Spacer(),
                      
                      // Terms and Privacy
                      Padding(
                        padding: const EdgeInsets.all(20),
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
        color: Colors.grey.shade50,
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
                    'assets/socialmedia/Google__G__logo.svg.png',
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