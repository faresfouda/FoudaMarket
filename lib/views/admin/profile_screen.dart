import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.authSelection,
            (route) => false,
          );
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
        // حذف bottomNavigationBar لإزالة شريط المهام
        body: Stack(
          children: [
            Image.asset(
              'assets/home/backgroundblur.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SafeArea(
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
                          backgroundImage: (state.userProfile!.avatarUrl != null &&
                              state.userProfile!.avatarUrl!.isNotEmpty)
                              ? NetworkImage(state.userProfile!.avatarUrl!)
                              : const AssetImage('assets/home/logo.jpg')
                                  as ImageProvider,
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
                                  color: AppColors.orangeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getRoleText(state.userProfile!.role),
                                  style: TextStyle(
                                    color: AppColors.orangeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(thickness: 1, color: Color(0xFFF0F0F0)),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      children: [
                        // إظهار إدارة أكواد الخصم للمدير فقط
                        if (state.userProfile!.role == 'admin')
                          _ProfileListTile(
                            title: 'إدارة الكودات الخصمية',
                            iconPath: 'assets/home/Promo Cord icon.svg',
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
                        _ProfileListTile(
                          title: 'تغيير كلمة المرور',
                          iconPath: 'assets/home/help icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpdatePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        // _ProfileListTile(
                        //   title: 'معلومات التخزين المؤقت',
                        //   iconPath: 'assets/home/about icon.svg',
                        //   onTap: () {
                        //     _showCacheInfoDialog(context);
                        //   },
                        // ),
                        _ProfileListTile(
                          title: 'حول التطبيق',
                          iconPath: 'assets/home/about icon.svg',
                          onTap: () {
                            _showAboutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
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
                          'تسجيل الخروج من الإدارة',
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
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Image.asset(
              'assets/home/backgroundblur.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SafeArea(
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
                          backgroundColor: AppColors.orangeColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 36,
                            color: AppColors.orangeColor,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                            color: AppColors.orangeColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'غير مصرح لك بالوصول',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'يجب تسجيل الدخول بحساب مدير للوصول إلى لوحة الإدارة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
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
                                  MaterialPageRoute(
                                    builder: (context) => const AuthSelectionScreen(),
                                  ),
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
          ],
        ),
      ),
    );
  }

  // Helper Methods
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

  void _showCacheInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Expanded(child: CacheInfoWidget()),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: AppColors.orangeColor),
            const SizedBox(width: 8),
            const Text('حول النظام'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'فودا ماركت - نظام الإدارة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text('الإصدار: 1.0.0'),
            SizedBox(height: 16),
            Text('نظام إدارة متجر إلكتروني متكامل للمواد الغذائية والمنزلية'),
            SizedBox(height: 16),
            Text('المميزات:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• إدارة المنتجات والفئات'),
            Text('• إدارة الطلبات والمبيعات'),
            Text('• التقارير والإحصائيات'),
            Text('• إدارة المستخدمين'),
            Text('• نظام الإشعارات'),
            SizedBox(height: 16),
            Text('المطور: فريق فودا ماركت'),
            Text('جميع الحقوق محفوظة © 2024'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('تسجيل الخروج'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من تسجيل الخروج من لوحة الإدارة؟'),
            SizedBox(height: 8),
            Text(
              'سيتم إنهاء جلسة الإدارة وإعادتك لصفحة تسجيل الدخول',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback? onTap;
  final bool? enabled;

  const _ProfileListTile({
    required this.title,
    required this.iconPath,
    this.onTap,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled == false ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
