import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fodamarket/views/home/main_screen.dart';
import 'package:get/get.dart';
import '../../theme/appcolors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../blocs/auth/auth_state.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String phone;
  final String uid;
  const CompleteProfileScreen({super.key, required this.phone, required this.uid});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'id': widget.uid,
        'name': _nameController.text.trim(),
        'phone': widget.phone,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'authProvider': 'phone',
      });
      // اقرأ بيانات المستخدم مباشرة بعد الحفظ
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      final data = doc.data();
      if (data != null) {
        final user = FirebaseAuth.instance.currentUser;
        final userModel = UserModel(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          phone: data['phone'],
          role: data['role'],
          avatarUrl: data['avatar_url'],
          createdAt: data['createdAt'] != null && data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          updatedAt: data['updatedAt'] != null && data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
        BlocProvider.of<AuthBloc>(context).emit(
          Authenticated(user: user!, userProfile: userModel),
        );
      }
      Get.snackbar('تم', 'تم حفظ البيانات بنجاح');
      Get.offAll(() => MainScreen());
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حفظ البيانات');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('إكمال البيانات', style: TextStyle(color: AppColors.blackColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('يرجى إدخال اسمك لإكمال التسجيل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.blackColor)),
              SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.orangeColor), borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(fontSize: 18),
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('حفظ ومتابعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('رقم هاتفك: ${widget.phone}', style: TextStyle(fontSize: 16, color: AppColors.mediumGrayColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 