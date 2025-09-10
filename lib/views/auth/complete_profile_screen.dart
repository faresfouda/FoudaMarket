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
  final String phone;
  final String uid;
  const CompleteProfileScreen({
    super.key,
    required this.phone,
    required this.uid,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isOffline = false; // جديد

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'id': widget.uid,
        'name': _nameController.text.trim(),
        'phone': widget.phone,
        'email': '', // إضافة حقل email فارغ للتناسق
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'authProvider': 'phone',
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم حفظ البيانات بنجاح')));
      // Use BLoC to update auth state instead of direct emit
      BlocProvider.of<AuthBloc>(context).add(AuthCheckRequested());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل حفظ البيانات')));
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
              switch (state.userProfile!.role) {
                case 'admin':
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.adminDashboard,
                    (route) => false,
                  );
                  break;
                case 'data_entry':
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.dataEntryHome,
                    (route) => false,
                  );
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
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'إكمال البيانات',
              style: TextStyle(
                color: AppColors.blackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يرجى إدخال اسمك لإكمال التسجيل',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.orangeColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'أدخل اسمك الكامل',
                    ),
                    style: TextStyle(fontSize: 18),
                    validator: (value) => value == null || value.isEmpty
                        ? 'يرجى إدخال الاسم'
                        : null,
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (_isLoading || _isOffline)
                          ? null
                          : _saveProfile,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'حفظ ومتابعة',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'رقم هاتفك: ${widget.phone}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mediumGrayColor,
                      ),
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
}
