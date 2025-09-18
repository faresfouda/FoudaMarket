import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fouda_market/views/profile/my_details_screen.dart';
import 'package:fouda_market/views/profile/delivery_address_screen.dart' as delivery;
import 'package:fouda_market/views/profile/promo_code_screen.dart';
import 'package:fouda_market/views/profile/notifications_screen.dart';
import 'package:fouda_market/views/profile/about_screen.dart';
import 'package:fouda_market/views/profile/my_reviews_screen.dart';
import 'package:fouda_market/views/profile/orders_screen.dart' as profile_orders;
import 'package:fouda_market/blocs/auth/index.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:flutter/services.dart';
import '../../routes.dart';
import '../admin/promo_codes_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.authSelection, (route) => false);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated && state.userProfile != null) {
            // User is authenticated - show profile
            return _buildAuthenticatedProfile(context, state);
          } else if (state is Guest) {
            return _buildGuestProfile(context);
          } else {
            // User is not authenticated - show login option
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
                          backgroundImage:
                              (state.userProfile!.avatarUrl != null &&
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(height: 6),
                              if (state.userProfile!.email != null &&
                                  state.userProfile!.email!.isNotEmpty)
                                Text(
                                  state.userProfile!.email!,
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 15,
                                  ),
                                ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
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
                        if (state is! Guest) ...[
                          _ProfileListTile(
                            title: 'الطلبات',
                            iconPath: 'assets/home/Orders icon.svg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const profile_orders.OrdersScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        if (state is Guest) ...[
                          _ProfileListTile(
                            title: 'الطلبات (متاحة بعد تسجيل الدخول)',
                            iconPath: 'assets/home/Orders icon.svg',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'يجب تسجيل الدخول لعرض الطلبات',
                                  ),
                                ),
                              );
                            },
                            enabled: false,
                          ),
                        ],
                        _ProfileListTile(
                          title: 'بياناتي',
                          iconPath: 'assets/home/My Details icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const MyDetailsScreen(),
                              ),
                            );
                          },
                        ),
                        if (state is! Guest) ...[
                          _ProfileListTile(
                            title: 'إدارة الحسابات المربوطة',
                            iconPath: 'assets/home/Orders icon.svg', // يمكن تغيير الأيقونة
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.linkedAccounts,
                              );
                            },
                          ),
                        ],
                        _ProfileListTile(
                          title: 'عنوان التوصيل',
                          iconPath: 'assets/home/Delicery address.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const delivery.DeliveryAddressScreen(),
                              ),
                            );
                          },
                        ),
                        // عرض كود الخصم للمستخدمين العاديين فقط، وإدارة أكواد الخصم للمدير فقط
                        if (state.userProfile!.role == 'admin') ...[
                          _ProfileListTile(
                            title: 'إدارة أكواد الخصم',
                            iconPath: 'assets/home/Promo Cord icon.svg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const PromoCodesScreen(),
                                ),
                              );
                            },
                          ),
                        ] else if (state.userProfile!.role == 'user') ...[
                          _ProfileListTile(
                            title: 'كود الخصم',
                            iconPath: 'assets/home/Promo Cord icon.svg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const PromoCodeScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        _ProfileListTile(
                          title: 'الإشعارات',
                          iconPath: 'assets/home/Bell icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        if (state is! Guest) ...[
                          _ProfileListTile(
                            title: 'مراجعاتي',
                            iconPath:
                                'assets/home/help icon.svg', // يمكن تغيير الأيقونة لاحقاً
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const MyReviewsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        _ProfileListTile(
                          title: 'حول',
                          iconPath: 'assets/home/about icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const AboutScreen(),
                              ),
                            );
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
                        icon: Icon(Icons.logout, color: Color(0xFFFFA726)),
                        label: Text(
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
                          backgroundColor: AppColors.orangeColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: AppColors.orangeColor,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً بك',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'سجل دخولك للوصول إلى ملفك الشخصي',
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
                            Icons.account_circle,
                            size: 80,
                            color: AppColors.orangeColor.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'لم تسجل دخولك بعد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'سجل دخولك للوصول إلى جميع الميزات',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.authSelection,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orangeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 18,
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

  Widget _buildGuestProfile(BuildContext context) {
    return _buildAuthenticatedProfile(context, Guest() as Authenticated);
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'user':
        return 'مستخدم';
      default:
        return 'زائر';
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'تسجيل الخروج',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          content: Text(
            'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(SignOutRequested());
              },
              child: Text('تأكيد', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;
  final bool enabled;

  const _ProfileListTile({
    required this.title,
    required this.iconPath,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.9),
      ),
      child: ListTile(
        onTap: enabled ? onTap : null,
        leading: SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            enabled ? Colors.black : Colors.grey,
            BlendMode.srcIn,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: enabled ? Colors.black : Colors.grey,
          size: 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
      ),
    );
  }
}
