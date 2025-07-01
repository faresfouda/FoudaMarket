import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      backgroundImage: AssetImage(
                        'assets/marketlogo/marketlogo.png',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'محمد أحمد',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'mohamed.ahmed@email.com',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: Color(0xFFFFA726),
                      size: 22,
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
                  children: const [
                    _ProfileListTile(
                      title: 'الطلبات',
                      iconPath: 'assets/home/Orders icon.svg',
                    ),
                    _ProfileListTile(
                      title: 'بياناتي',
                      iconPath: 'assets/home/My Details icon.svg',
                    ),
                    _ProfileListTile(
                      title: 'عنوان التوصيل',
                      iconPath: 'assets/home/Delicery address.svg',
                    ),
                    _ProfileListTile(
                      title: 'طرق الدفع',
                      iconPath: 'assets/home/Vector icon.svg',
                    ),
                    _ProfileListTile(
                      title: 'كود الخصم',
                      iconPath: 'assets/home/Promo Cord icon.svg',
                    ),
                    _ProfileListTile(
                      title: 'الإشعارات',
                      iconPath: 'assets/home/Bell icon.svg',
                    ),
                    _ProfileListTile(
                      title: 'مساعدة',
                      iconPath: 'assets/home/help icon.svg',
                    ),
                    _ProfileListTile(
                      title: 'حول',
                      iconPath: 'assets/home/about icon.svg',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
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
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final String title;
  final String iconPath;
  const _ProfileListTile({required this.title, required this.iconPath});

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
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        tileColor: Colors.white,
      ),
    );
  }
}
