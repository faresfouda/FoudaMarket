import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/blocs/address/address_bloc.dart';
import 'package:fouda_market/blocs/address/address_state.dart';
import 'package:fouda_market/views/profile/notifications_screen.dart';
import 'package:fouda_market/theme/appcolors.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final isRefreshing = false; // يمكنك تمريرها كبراميتر إذا أردت
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.orangeColor.withValues(alpha: 0.1),
                radius: 20,
                child: Image.asset('assets/home/logo.jpg', height: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فودة ماركت',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    BlocBuilder<AddressBloc, AddressState>(
                      builder: (context, state) {
                        if (state is DefaultAddressLoaded &&
                            state.defaultAddress != null) {
                          return GestureDetector(
                            onTap:
                                () {}, // يمكنك تمرير دالة اختيار العنوان إذا أردت
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppColors.orangeColor,
                                  size: 16,
                                ),
                                Flexible(
                                  child: Text(
                                    state.defaultAddress!.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                          );
                        } else {
                          return GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppColors.orangeColor,
                                  size: 16,
                                ),
                                Text(
                                  'إضافة عنوان التوصيل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (isRefreshing)
              Container(
                margin: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orangeColor,
                  ),
                ),
              ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: AppColors.orangeColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
