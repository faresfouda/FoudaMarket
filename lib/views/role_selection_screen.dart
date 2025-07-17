// import 'package:flutter/material.dart';
// import 'package:fodamarket/views/admin/dashboard_screen.dart';
// import 'package:fodamarket/views/admin/data_entry_home_screen.dart';
// import 'package:fodamarket/views/home/main_screen.dart';
// import '../routes.dart';

// class RoleSelectionScreen extends StatelessWidget {
//   final void Function(String role)? onRoleSelected;
//   const RoleSelectionScreen({Key? key, this.onRoleSelected}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('اختر نوع الدخول'),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           centerTitle: true,
//           iconTheme: const IconThemeData(color: Colors.black),
//           titleTextStyle: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 22,
//           ),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _RoleCard(
//                 icon: Icons.person,
//                 label: 'مستخدم',
//                 color: Colors.orange,
//                 onTap: () => Navigator.pushNamed(context, AppRoutes.main),
//               ),
//               const SizedBox(height: 24),
//               _RoleCard(
//                 icon: Icons.edit,
//                 label: 'مدخل بيانات',
//                 color: Colors.blue,
//                 onTap: () => Navigator.pushNamed(context, AppRoutes.dataEntryHome),
//               ),
//               const SizedBox(height: 24),
//               _RoleCard(
//                 icon: Icons.admin_panel_settings,
//                 label: 'مسؤول',
//                 color: Colors.green,
//                 onTap: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RoleCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//   const _RoleCard({required this.icon, required this.label, required this.color, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: color.withOpacity(0.08),
//       borderRadius: BorderRadius.circular(20),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20),
//         onTap: onTap,
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                   color: color,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Icon(icon, color: color, size: 36),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// } 