import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/appcolors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../routes.dart';
import '../../components/connection_aware_widget.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String? phone;
  final String? email;
  final String uid;

  const CompleteProfileScreen({
    super.key,
    this.phone,
    this.email,
    required this.uid,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isOffline = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // تحديد مقدم الخدمة بناءً على البيانات المتوفرة
      String authProvider = 'phone';
      if (widget.email != null && widget.phone == null) {
        authProvider = 'email';
      } else if (widget.email != null && widget.phone != null) {
        authProvider = 'multiple';
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'uid': widget.uid,
        'name': _nameController.text.trim(),
        'phone': widget.phone ?? '',
        'email': widget.email ?? '',
        'role': 'user',
        'isEmailVerified': widget.email != null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'authProviders': [authProvider],
        'profileCompleted': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ البيانات بنجاح')),
      );

      BlocProvider.of<AuthBloc>(context).add(AuthCheckRequested());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أكمل ملفك الشخصي',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أدخل اسمك لإكمال إنشاء الحساب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mediumGrayColor,
                    ),
                  ),
                  SizedBox(height: 30),

                  // عرض معلومات الاتصال
                  if (widget.phone != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Colors.green.shade600),
                          SizedBox(width: 8),
                          Text(
                            'رقم الهاتف: ${widget.phone}',
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),

                  if (widget.email != null)
                    Container(
                      margin: EdgeInsets.only(top: widget.phone != null ? 8 : 0),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.email, color: Colors.blue.shade600),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'البريد الإلكتروني: ${widget.email}',
                              style: TextStyle(color: Colors.blue.shade800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 20),

                  Text(
                    'الاسم الكامل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mediumGrayColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'أدخل اسمك الكامل',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.orangeColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسمك الكامل';
                      }
                      if (value.trim().length < 2) {
                        return 'الاسم يجب أن يكون حرفين على الأقل';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'حفظ البيانات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
