import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الملف الشخصي'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('تعديل بيانات المستخدم هنا', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
} 