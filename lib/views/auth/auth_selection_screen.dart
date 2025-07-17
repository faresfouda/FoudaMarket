import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/components/Button.dart';
import 'package:fouda_market/components/phonetextfield.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/views/login/Login.dart';
import 'package:fouda_market/views/home/main_screen.dart';
import 'package:fouda_market/views/admin/dashboard_screen.dart';
import 'package:fouda_market/views/admin/data_entry_home_screen.dart';
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
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          break;
        case 'data_entry':
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dataEntryHome, (route) => false);
          break;
        default:
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      }
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
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
          } else if (state is Guest) {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          } else if (state is AuthError) {
            String errorMsg = state.message;
            if (errorMsg.contains('sign_in_canceled')) {
              errorMsg = 'تم إلغاء تسجيل الدخول من جوجل.';
            } else if (errorMsg.contains('network-request-failed')) {
              errorMsg = 'تحقق من اتصال الإنترنت.';
            } else if (errorMsg.contains('account-exists-with-different-credential')) {
              errorMsg = 'البريد مرتبط بطريقة تسجيل مختلفة.';
            } else if (errorMsg.contains('popup_closed_by_user')) {
              errorMsg = 'تم إغلاق نافذة جوجل قبل إكمال العملية.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
              ),
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
                      padding: const EdgeInsets.only( bottom: 20),
                      child: Column(
                        children: [
                          Image(image: AssetImage('assets/login/logo.png')),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'مع فودة.. البقالة أسهل وأسرع!',
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'اختر طريقة تسجيل الدخول المفضلة لديك',
                            style: TextStyle(
                              color: AppColors.mediumGrayColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Authentication options
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Email/Password Authentication
                            Button(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => LoginScreen()),
                                );
                              },
                              buttonContent: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: AppColors.whiteColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    'تسجيل الدخول بالبريد الإلكتروني',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              buttonColor: AppColors.orangeColor,
                            ),
                            
                            SizedBox(height: 15),
                            
                            // Phone/OTP Authentication
                            Button(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => PhoneLoginScreen()),
                                );
                              },
                              buttonContent: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.whiteColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    'تسجيل الدخول برقم الهاتف',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              buttonColor: AppColors.lightBlueColor,
                            ),
                            
                            SizedBox(height: 15),
                            
                            // Google Authentication
                            Button(
                              onPressed: () {
                                context.read<AuthBloc>().add(GoogleSignInRequested());
                              },
                              buttonContent: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/socialmedia/Google.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    'تسجيل الدخول بجوجل',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              buttonColor: AppColors.darkBlueColor,
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.mediumGrayColor)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'أو',
                                    style: TextStyle(
                                      color: AppColors.mediumGrayColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: AppColors.mediumGrayColor)),
                              ],
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Create new account option
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ليس لديك حساب؟ ',
                                  style: TextStyle(
                                    color: AppColors.blackColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                                    );
                                  },
                                  child: Text(
                                    'أنشئ حساب جديد',
                                    style: TextStyle(
                                      color: AppColors.orangeColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
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
