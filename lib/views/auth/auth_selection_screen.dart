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

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

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
          ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
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
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
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
                              'فودة ماركت',
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'تسوق سريع وآمن',
                              style: TextStyle(
                                color: AppColors.mediumGrayColor,
                                fontSize: 16,
                              ),
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
                          // تسجيل الدخول بالبريد الإلكتروني (لجميع المستخدمين)
                          Button(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.login);
                            },
                            buttonContent: Text(
                              'تسجيل الدخول بالبريد الإلكتروني',
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            buttonColor: AppColors.orangeColor,
                          ),
                          SizedBox(height: 15),

                          // تسجيل الدخول بالهاتف (لجميع المستخدمين)
                          Button(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.phoneLogin,
                              );
                            },
                            buttonContent: Text(
                              'تسجيل الدخول بالهاتف',
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            buttonColor: AppColors.lightBlueColor,
                          ),
                          SizedBox(height: 15),

                          // إنشاء حساب جديد (للمستخدمين العاديين)
                          Button(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.signup);
                            },
                            buttonContent: Text(
                              'إنشاء حساب جديد',
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            buttonColor: AppColors.darkBlueColor,
                          ),
                        ],
                      ),
                    ),

                    // Spacer to push content to center
                    Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
