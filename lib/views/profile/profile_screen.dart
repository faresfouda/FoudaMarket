import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fodamarket/views/profile/orders_screen.dart';
import 'package:fodamarket/views/profile/my_details_screen.dart';
import 'package:fodamarket/views/profile/delivery_address_screen.dart';
import 'package:fodamarket/views/profile/promo_code_screen.dart';
import 'package:fodamarket/views/profile/notifications_screen.dart';
import 'package:fodamarket/views/profile/help_screen.dart';
import 'package:fodamarket/views/profile/about_screen.dart';
import 'package:fodamarket/blocs/auth/index.dart';
import 'package:fodamarket/views/login/Login.dart';
import 'package:fodamarket/theme/appcolors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Login()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated && state.userProfile != null) {
            // User is authenticated - show profile
            return _buildAuthenticatedProfile(context, state);
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
                          backgroundImage: AssetImage(
                            'assets/home/logo.jpg',
                          ),
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
                              Text(
                                state.userProfile!.email,
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          title: 'الطلبات',
                          iconPath: 'assets/home/Orders icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OrdersScreen()),
                            );
                          },
                        ),
                        _ProfileListTile(
                          title: 'بياناتي',
                          iconPath: 'assets/home/My Details icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyDetailsScreen()),
                            );
                          },
                        ),
                        _ProfileListTile(
                          title: 'عنوان التوصيل',
                          iconPath: 'assets/home/Delicery address.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DeliveryAddressScreen()),
                            );
                          },
                        ),
                        _ProfileListTile(
                          title: 'كود الخصم',
                          iconPath: 'assets/home/Promo Cord icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PromoCodeScreen()),
                            );
                          },
                        ),
                        _ProfileListTile(
                          title: 'الإشعارات',
                          iconPath: 'assets/home/Bell icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                          },
                        ),
                        _ProfileListTile(
                          title: 'مساعدة',
                          iconPath: 'assets/home/help icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HelpScreen()),
                            );
                          },
                        ),
                        _ProfileListTile(
                          title: 'حول',
                          iconPath: 'assets/home/about icon.svg',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AboutScreen()),
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
                          backgroundColor: AppColors.orangeColor.withOpacity(0.1),
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
                            color: AppColors.orangeColor.withOpacity(0.3),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Login()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orangeColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
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

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تسجيل الخروج'),
          content: Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(SignOutRequested());
              },
              child: Text(
                'تأكيد',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'data_entry':
        return 'مدخل بيانات';
      default:
        return 'مستخدم';
    }
  }
}

class _ProfileListTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback? onTap;
  const _ProfileListTile({required this.title, required this.iconPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            iconPath,
            color: Colors.black,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black),
        ),
        trailing: Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black,
          size: 18,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        tileColor: Colors.white,
      ),
    );
  }
}
