import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../components/Button.dart';
import '../../core/services/google_auth_service.dart';
import '../../theme/appcolors.dart';

class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;
  User? _currentUser;
  List<String> _linkedProviders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      setState(() {
        _linkedProviders = _googleAuthService.getLinkedProviders();
      });
    }
  }

  Future<void> _linkGoogleAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _googleAuthService.linkGoogleAccount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم ربط حساب Google بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unlinkGoogleAccount() async {
    // التأكد من وجود أكثر من طريقة مصادقة
    if (_linkedProviders.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن إلغاء ربط آخر طريقة مصادقة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // إظهار تأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء ربط حساب Google'),
        content: Text('هل أنت متأكد من إلغاء ربط حساب Google؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _googleAuthService.unlinkGoogleAccount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إلغاء ربط حساب Google'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('الحسابات المربوطة'),
        backgroundColor: AppColors.orangeColor,
        foregroundColor: Colors.white,
      ),
      body: _currentUser == null
          ? Center(child: Text('لا يوجد مستخدم مسجل دخول'))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حسابك مربوط مع:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // عرض مقدمي الخدمة المربوطين
                  Expanded(
                    child: ListView(
                      children: [
                        // Phone Authentication
                        if (_linkedProviders.contains('phone'))
                          _buildProviderCard(
                            icon: Icons.phone,
                            title: 'رقم الهاتف',
                            subtitle: _currentUser?.phoneNumber ?? 'مربوط',
                            isLinked: true,
                            canUnlink: _linkedProviders.length > 1,
                            onUnlink: null, // لا يمكن إلغاء ربط الهاتف حالياً
                          ),

                        // Email Authentication
                        if (_linkedProviders.contains('password'))
                          _buildProviderCard(
                            icon: Icons.email,
                            title: 'البريد الإلكتروني',
                            subtitle: _currentUser?.email ?? 'مربوط',
                            isLinked: true,
                            canUnlink: _linkedProviders.length > 1,
                            onUnlink: null, // لا يمكن إلغاء ربط البريد حالياً
                          ),

                        // Google Authentication
                        _buildProviderCard(
                          icon: Icons.g_mobiledata,
                          title: 'حساب Google',
                          subtitle: _linkedProviders.contains('google.com')
                              ? _googleAuthService.getGoogleProviderData()?.email ?? 'مربوط'
                              : 'غير مربوط',
                          isLinked: _linkedProviders.contains('google.com'),
                          canUnlink: _linkedProviders.length > 1,
                          onLink: _linkGoogleAccount,
                          onUnlink: _unlinkGoogleAccount,
                        ),

                        // مساحة إضافية
                        const SizedBox(height: 20),

                        // معلومات إضافية
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'نصائح مهمة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• يمكنك ربط عدة طرق للمصادقة لسهولة الوصول\n'
                                '• يجب الاحتفاظ بطريقة واحدة على الأقل للمصادقة\n'
                                '• استخدم Google للدخول السريع والآمن',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProviderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLinked,
    required bool canUnlink,
    VoidCallback? onLink,
    VoidCallback? onUnlink,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLinked ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isLinked ? Colors.green.shade600 : Colors.grey.shade600,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mediumGrayColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isLinked && canUnlink && onUnlink != null)
              TextButton(
                onPressed: onUnlink,
                child: Text(
                  'إلغاء الربط',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else if (!isLinked && onLink != null)
              TextButton(
                onPressed: onLink,
                child: Text(
                  'ربط',
                  style: TextStyle(color: AppColors.orangeColor),
                ),
              )
            else if (isLinked)
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
