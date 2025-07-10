import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/components/phonetextfield.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/Number/Number.dart';
import 'package:fodamarket/views/login/Login.dart';
import 'package:fodamarket/views/signup/Signup.dart';
import 'package:fodamarket/blocs/auth/index.dart';
import 'package:fodamarket/views/home/main_screen.dart';
import 'package:fodamarket/views/admin/admin_dashboard_screen.dart';
import 'package:get/get.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  void _navigateBasedOnRole(BuildContext context, Authenticated state) {
    if (state.userProfile != null) {
      switch (state.userProfile!.role) {
        case 'admin':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminDashboardMain()),
          );
          break;
        case 'data_entry':
          // Navigate to data entry screen
          break;
        default:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
      }
    } else {
      // Default navigation for users without profile
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
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
            // Navigate to main screen for guest users
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
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
                      padding: const EdgeInsets.only(top: 60, bottom: 20),
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
                                Get.to(() => Login());
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
                                Get.to(() => Number());
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
                                    Get.to(() => Signup());
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
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.read<AuthBloc>().add(GuestLoginRequested());
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.orangeColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'الدخول كزائر',
                                  style: TextStyle(color: AppColors.orangeColor, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SizedBox(height: 40), // Extra padding at bottom for scrolling
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
