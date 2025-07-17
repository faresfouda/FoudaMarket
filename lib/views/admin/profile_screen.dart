import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/views/admin/promo_codes_screen.dart';
import '../../theme/appcolors.dart';
import '../../blocs/auth/index.dart';
import 'package:fouda_market/views/auth/auth_selection_screen.dart';
import 'update_password_screen.dart';
import 'widgets/cache_info_widget.dart';
import '../../blocs/promo_code/promo_code_bloc.dart';
import '../../blocs/promo_code/promo_code_stats_bloc.dart';
import '../../routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.authSelection, (route) => false);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated && state.userProfile != null) {
            return _buildAuthenticatedProfile(context, state);
          } else {
            return _buildUnauthenticatedProfile(context);
          }
        },
      ),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, Authenticated state) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Profile header
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 24.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: AssetImage('assets/home/logo.jpg'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.userProfile!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (state.userProfile!.email != null &&
                              state.userProfile!.email!.isNotEmpty)
                            Text(
                              state.userProfile!.email!,
                              style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 15,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orangeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleText(state.userProfile!.role),
                              style: TextStyle(
                                color: AppColors.orangeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(thickness: 1, color: Color(0xFFF0F0F0)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  children: [
                    _ProfileListTile(
                      title: 'تغيير كلمة المرور',
                      icon: Icons.lock_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdatePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileListTile(
                      title: 'حول التطبيق',
                      icon: Icons.info_outline,
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                    _ProfileListTile(
                      title: 'معلومات التخزين المؤقت',
                      icon: Icons.storage,
                      onTap: () {
                        _showCacheInfoDialog(context);
                      },
                    ),
                    _ProfileListTile(
                      title: 'الكودات الخصمية',
                      icon: Icons.lock_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiBlocProvider(
                              providers: [
                                BlocProvider<PromoCodeBloc>(create: (_) => PromoCodeBloc()),
                                BlocProvider<PromoCodeStatsBloc>(create: (_) => PromoCodeStatsBloc()),
                              ],
                              child: const PromoCodesScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // تسجيل الخروج
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showSignOutDialog(context);
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFFFFA726)),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: Color(0xFFFFA726),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6F6F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 24.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.orangeColor.withOpacity(0.1),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 36,
                        color: AppColors.orangeColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'لوحة الإدارة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'يجب تسجيل الدخول كمدير للوصول',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(thickness: 1, color: Color(0xFFF0F0F0)),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 80,
                        color: AppColors.orangeColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'غير مصرح لك بالوصول',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'يجب تسجيل الدخول بحساب مدير للوصول إلى لوحة الإدارة',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AuthSelectionScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orangeColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text('تسجيل الخروج'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد من تسجيل الخروج من لوحة الإدارة؟'),
              SizedBox(height: 8),
              Text(
                'سيتم تسجيل خروجك من جميع الأجهزة',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(SignOutRequested());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('تم تسجيل الخروج بنجاح'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد الخروج'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: AppColors.orangeColor, size: 24),
              const SizedBox(width: 8),
              const Text('حول التطبيق'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فودا ماركت - لوحة الإدارة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('الإصدار: 1.0.0'),
              SizedBox(height: 8),
              Text('نظام إدارة متجر إلكتروني متكامل'),
              SizedBox(height: 16),
              Text('المميزات:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('إدارة المنتجات والفئات'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.shopping_cart, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('إدارة الطلبات والمبيعات'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.analytics, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('التقارير والإحصائيات'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('إدارة المستخدمين'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.notifications, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('نظام الإشعارات'),
                ],
              ),
              SizedBox(height: 16),
              Text('المطور: فريق فودا ماركت'),
              Text('جميع الحقوق محفوظة © 2024'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _showCacheInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storage, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'معلومات التخزين المؤقت',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: const CacheInfoWidget()),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'data_entry':
        return 'مدخل بيانات';
      default:
        return 'مستخدم';
    }
  }
}

class _ProfileListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const _ProfileListTile({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
