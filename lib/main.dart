import 'package:fodamarket/views/admin/admin_dashboard_screen.dart';
import 'package:fodamarket/views/admin/data_entry_home_screen.dart';
import 'package:fodamarket/views/home/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:fodamarket/views/role_selection_screen.dart';
import 'package:get/get.dart';

void main() {
  runApp(FodaMarket());
}

class FodaMarket extends StatelessWidget {
  const FodaMarket({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      locale: Locale('ar'),
      theme: ThemeData(fontFamily: 'Gilroy'),
      debugShowCheckedModeBanner: false,
      home: RoleSelectionScreen(),
    );
  }
}
