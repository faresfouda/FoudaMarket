import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fodamarket/components/Button.dart';
import 'package:fodamarket/components/CustomTextField.dart';
import 'package:fodamarket/components/Signing.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/blocs/auth/index.dart';
import 'package:fodamarket/views/login/Login.dart';
import 'package:fodamarket/views/SignIn/SignIn.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'user';

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
          role: _selectedRole,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Login(preFilledEmail: state.email)),
              (route) => false,
            );
          });
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          _isLoading = state is AuthLoading;
          
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
              body: Signing(
                title: 'انشاء حساب',
                subTitle: 'أدخل بياناتك للاستمرار',
                screenContent: Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          hinttext: 'اسم المستخدم',
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
                          hinttext: 'البريد الالكتروني',
                          title: "أدخل بريدك الالكتروني",
                          button: null,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال البريد الإلكتروني';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'يرجى إدخال بريد إلكتروني صحيح';
                            }
                            return null;
                          },
                        ),
                        CustomTextField(
                          controller: _phoneController,
                          hinttext: 'رقم الهاتف',
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
                          hinttext: "كلمة المرور",
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
                          hinttext: 'تأكيد كلمة المرور',
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
                        SizedBox(height: 20),
                        // Role selection dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نوع الحساب',
                              style: TextStyle(
                                color: AppColors.mediumGrayColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.blackColor),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.blackColor),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text('مستخدم عادي'),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('مدير'),
                                ),
                                DropdownMenuItem(
                                  value: 'data_entry',
                                  child: Text('مدخل بيانات'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Button(
                          onPressed: _isLoading ? () {} : _handleSignUp,
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
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Login(
                                            preFilledEmail: _emailController.text.trim().isNotEmpty
                                                ? _emailController.text.trim()
                                                : null,
                                          ),
                                        ),
                                      );
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
    );
  }
}
