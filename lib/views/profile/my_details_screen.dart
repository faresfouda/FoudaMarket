import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/components/Button.dart';
import '../../blocs/auth/index.dart';
import '../../core/services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  bool isEditing = false;
  bool isLoading = false;
  File? pickedImage;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && authState.userProfile != null) {
      nameController = TextEditingController(text: authState.userProfile!.name);
      phoneController = TextEditingController(
        text: authState.userProfile!.phone,
      );
      emailController = TextEditingController(
        text: authState.userProfile!.email ?? '',
      );
      imageUrl = authState.userProfile!.avatarUrl;
    } else {
      nameController = TextEditingController();
      phoneController = TextEditingController();
      emailController = TextEditingController();
      imageUrl = null;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
    });
    final authState = context.read<AuthBloc>().state;
    String? uploadedUrl = imageUrl;
    if (pickedImage != null) {
      // رفع الصورة الجديدة فقط إذا تم اختيارها
      final url = await CloudinaryService().uploadImage(pickedImage!.path);
      if (url != null) {
        uploadedUrl = url;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل رفع صورة البروفايل')));
      }
    }
    if (authState is Authenticated && authState.userProfile != null) {
      try {
        await AuthService().updateUserProfile(authState.userProfile!.id, {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          if (uploadedUrl != null) 'avatar_url': uploadedUrl,
        });
        context.read<AuthBloc>().add(AuthCheckRequested());
        setState(() {
          isEditing = false;
          pickedImage = null;
          imageUrl = uploadedUrl;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل حفظ البيانات: $e')));
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    if (!isEditing) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        pickedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is Authenticated && state.userProfile != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F6F6),
            body: Stack(
              children: [
                Image.asset(
                  'assets/home/backgroundblur.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black,
                                size: 26,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Expanded(
                              child: Text(
                                'الملف الشخصي',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 60),
                              padding: const EdgeInsets.only(
                                top: 80,
                                bottom: 32,
                                left: 24,
                                right: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.98),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // حقل الاسم بشكل واضح
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isEditing
                                          ? Colors.orange.withOpacity(0.08)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isEditing
                                            ? Colors.orange
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: nameController,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              color: Colors.black,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              hintText: 'اسم المستخدم',
                                            ),
                                            readOnly: !isEditing,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: isEditing
                                                ? Colors.orange
                                                : Colors.grey,
                                            size: 24,
                                          ),
                                          tooltip: isEditing
                                              ? 'جاري التعديل'
                                              : 'تعديل الاسم',
                                          onPressed: isEditing
                                              ? null
                                              : () {
                                                  setState(() {
                                                    isEditing = true;
                                                  });
                                                },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  _ProfileInfoEditField(
                                    label: 'الهاتف',
                                    controller: phoneController,
                                    icon: Icons.phone,
                                    readOnly: !isEditing,
                                  ),
                                  const SizedBox(height: 24),
                                  _ProfileInfoEditField(
                                    label: 'البريد الإلكتروني',
                                    controller: emailController,
                                    icon: Icons.email,
                                    readOnly: !isEditing,
                                  ),
                                  if (isEditing) ...[
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: Button(
                                        onPressed: isLoading
                                            ? null
                                            : _saveProfile,
                                        buttonContent: isLoading
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                  SizedBox(width: 16),
                                                  Text(
                                                    'جاري حفظ البيانات...',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Text(
                                                'حفظ البيانات',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        buttonColor: AppColors.orangeColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 56,
                                      backgroundImage: pickedImage != null
                                          ? FileImage(pickedImage!)
                                          : (imageUrl != null &&
                                                        imageUrl!.isNotEmpty
                                                    ? NetworkImage(imageUrl!)
                                                    : const AssetImage(
                                                        'assets/home/logo.jpg',
                                                      ))
                                                as ImageProvider,
                                    ),
                                  ),
                                  if (isEditing) // السماح بتغيير الصورة فقط في وضع التعديل
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: isLoading
                                            ? null
                                            : _pickProfileImage,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        // حالة عدم وجود بيانات مستخدم
        return const Scaffold(
          body: Center(child: Text('لا توجد بيانات مستخدم')),
        );
      },
    );
  }
}

class _ProfileInfoEditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool readOnly;

  const _ProfileInfoEditField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                      readOnly: readOnly,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(icon, color: Colors.black, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
