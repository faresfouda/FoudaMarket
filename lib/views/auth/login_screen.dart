import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/components/Button.dart';
import 'package:fouda_market/components/CustomTextField.dart';
import 'package:fouda_market/components/Signing.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/views/auth/sign_up_screen.dart';
import 'package:fouda_market/views/auth/auth_selection_screen.dart';
import 'package:fouda_market/blocs/auth/index.dart';
import 'package:fouda_market/views/home/main_screen.dart';
import 'package:fouda_market/views/admin/dashboard_screen.dart';
import 'package:fouda_market/views/admin/data_entry_home_screen.dart';
import 'package:fouda_market/views/SignIn/SignIn.dart';
import '../../routes.dart';
import '../../components/connection_aware_widget.dart';

class LoginScreen extends StatefulWidget {
  final String? preFilledEmail;
  
  const LoginScreen({super.key, this.preFilledEmail});

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isOffline = false; // جديد

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.preFilledEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _handleForgotPassword() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      PasswordResetRequested(email: _emailController.text.trim()),
    );
  }

  void _navigateBasedOnRole(Authenticated state) {
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
          _navigateBasedOnRole(state);
        } else if (state is AuthError) {
            String errorMsg = state.message;
            if (errorMsg.contains('user-not-found')) {
              errorMsg = 'البريد الإلكتروني غير مسجل.';
            } else if (errorMsg.contains('wrong-password')) {
              errorMsg = 'كلمة المرور غير صحيحة.';
            } else if (errorMsg.contains('invalid-email')) {
              errorMsg = 'صيغة البريد الإلكتروني غير صحيحة.';
            } else if (errorMsg.contains('user-disabled')) {
              errorMsg = 'تم تعطيل هذا الحساب.';
            } else if (errorMsg.contains('too-many-requests')) {
              errorMsg = 'تم حظر المحاولة مؤقتًا بسبب محاولات متكررة. حاول لاحقًا.';
            } else if (errorMsg.contains('network-request-failed')) {
              errorMsg = 'تحقق من اتصال الإنترنت.';
            }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is PasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى ${state.email}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          _isLoading = state is AuthLoading;
          
          return WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
              return false;
            },
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: AppColors.blackColor),
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false),
                ),
              ),
              body: Signing(
                title: 'تسجيل الدخول',
                subTitle: 'ادخل البريد الالكتروني وكلمة السر',
                screenContent: Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        CustomTextField(
                          controller: _emailController,
                            hinttext: 'مثال: example@email.com',
                          title: 'البريد الالكتروني',
                          button: null,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال البريد الإلكتروني';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) {
                              return 'يرجى إدخال بريد إلكتروني صحيح';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        CustomTextField(
                          controller: _passwordController,
                            hinttext: 'أدخل كلمة المرور (6 أحرف على الأقل)',
                          title: 'كلمة السر',
                          button: IconButton(
                            onPressed: _togglePasswordVisibility,
                            icon: Icon(
                              _obscurePassword 
                                ? Icons.remove_red_eye_outlined
                                : Icons.visibility_off_outlined,
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال كلمة المرور';
                            }
                            if (value.length < 6) {
                              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: (_isLoading || _isOffline) ? null : _handleForgotPassword,
                              child: Text(
                                'هل نسيت كلمة السر؟',
                                style: TextStyle(
                                  color: AppColors.blackColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Button(
                            onPressed: (_isLoading || _isOffline) ? null : _handleSignIn,
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
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.whiteColor,
                                ),
                              ),
                          buttonColor: AppColors.orangeColor,
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ليس لديك حساب؟ ',
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            GestureDetector(
                                onTap: () {
                                  if (!_isLoading && !_isOffline) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                    );
                                  }
                                  },
                              child: Text(
                                'أنشئ حساب',
                                style: TextStyle(
                                  color: AppColors.orangeColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        },
        ),
      ),
    );
  }
}
