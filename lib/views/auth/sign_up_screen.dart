import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/components/Button.dart';
import 'package:fouda_market/components/CustomTextField.dart';
import 'package:fouda_market/components/Signing.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/blocs/auth/index.dart';
import 'package:fouda_market/views/auth/login_screen.dart';
import 'package:fouda_market/views/auth/auth_selection_screen.dart';
import '../../routes.dart';
import '../../components/connection_aware_widget.dart';
import 'package:fouda_market/views/auth/email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final String _selectedRole = 'user';
  bool _isOffline = false; // جديد

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: 'user',
        ),
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
          if (state is EmailVerificationRequired) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => EmailVerificationScreen(email: state.email),
              ),
            );
            return;
          }
          if (state is SignUpSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Navigate to login screen after a short delay
            Future.delayed(Duration(seconds: 2), () {
              // إذا أردت تمرير بيانات (preFilledEmail) استخدم push مع MaterialPageRoute
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            });
          } else if (state is AuthError) {
            String errorMsg = state.message;
            if (errorMsg.contains('email-already-in-use')) {
              errorMsg = 'البريد الإلكتروني مستخدم مسبقًا.';
            } else if (errorMsg.contains('weak-password')) {
              errorMsg = 'كلمة المرور ضعيفة. يجب أن تكون 6 أحرف على الأقل.';
            } else if (errorMsg.contains('invalid-email')) {
              errorMsg = 'صيغة البريد الإلكتروني غير صحيحة.';
            } else if (errorMsg.contains('network-request-failed')) {
              errorMsg = 'تحقق من اتصال الإنترنت.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            _isLoading = state is AuthLoading;

            return WillPopScope(
              onWillPop: () async {
                Navigator.of(context).pushReplacementNamed(AppRoutes.signIn);
                return false;
              },
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.blackColor,
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.signIn),
                  ),
                ),
                body: Signing(
                  title: 'إنشاء حساب جديد',
                  subTitle: 'أدخل بياناتك للاستمرار',
                  screenContent: Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            hinttext: 'أدخل اسمك الكامل',
                            title: "ادخل اسمك الثنائي",
                            button: null,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسمك';
                              }
                              if (value.length < 2) {
                                return 'الاسم يجب أن يكون حرفين على الأقل';
                              }
                              return null;
                            },
                          ),
                          CustomTextField(
                            controller: _emailController,
                            hinttext: 'مثال: example@email.com',
                            title: "أدخل بريدك الالكتروني",
                            button: null,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال البريد الإلكتروني';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'يرجى إدخال بريد إلكتروني صحيح';
                              }
                              return null;
                            },
                          ),
                          CustomTextField(
                            controller: _phoneController,
                            hinttext: 'أدخل رقم الهاتف بدون صفر في البداية',
                            title: "أدخل رقم هاتفك",
                            button: null,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال رقم الهاتف';
                              }
                              if (value.length < 10) {
                                return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                              }
                              return null;
                            },
                          ),
                          CustomTextField(
                            controller: _passwordController,
                            hinttext: 'أدخل كلمة المرور (6 أحرف على الأقل)',
                            title: "ادخل كلمة المرور",
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
                          CustomTextField(
                            controller: _confirmPasswordController,
                            hinttext: 'أعد إدخال كلمة المرور',
                            title: "تأكيد كلمة المرور",
                            button: IconButton(
                              onPressed: _toggleConfirmPasswordVisibility,
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.remove_red_eye_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى تأكيد كلمة المرور';
                              }
                              if (value != _passwordController.text) {
                                return 'كلمة المرور غير متطابقة';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 30),
                          Button(
                            onPressed: (_isLoading || _isOffline)
                                ? null
                                : _handleSignUp,
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
                                    'أنشئ حساب',
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
                                'لديك حساب بالفعل؟ ',
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
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(
                                          preFilledEmail:
                                              _emailController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? _emailController.text.trim()
                                              : null,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  "تسجيل الدخول",
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
