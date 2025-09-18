import 'package:flutter/material.dart';
import 'package:fouda_market/views/admin/send_notification_screen.dart';
import 'package:fouda_market/views/admin/sales_reports_screen.dart';
import 'package:fouda_market/views/admin/admin_devtools_screen.dart';
import 'package:fouda_market/views/admin/banner_management_screen.dart';
import 'quick_action_card.dart';

class DashboardQuickActions extends StatelessWidget {
  final void Function(int, {String? filter})? onTabChange;
  final void Function() onCreateTestOrder;

  const DashboardQuickActions({
    super.key,
    this.onTabChange,
    required this.onCreateTestOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            QuickActionCard(
              icon: Icons.add,
              label: 'إضافة منتج',
              color: Colors.orange,
              labelColor: Colors.white,
              iconColor: Colors.white,
              onTap: () {
                if (onTabChange != null) {
                  onTabChange!(1);
                }
              },
            ),
            QuickActionCard(
              icon: Icons.notifications_active,
              label: 'إرسال إشعار للعملاء',
              color: Colors.orange[50]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SendNotificationScreen(),
                  ),
                );
              },
            ),
            QuickActionCard(
              icon: Icons.bar_chart,
              label: 'تقارير المبيعات',
              color: Colors.orange[50]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesReportsScreen()),
                );
              },
            ),
            QuickActionCard(
              icon: Icons.list_alt,
              label: 'طلبات جديدة',
              color: Colors.orange[50]!,
              onTap: () {
                if (onTabChange != null) {
                  onTabChange!(2, filter: 'جديد');
                }
              },
            ),
            // QuickActionCard(
            //   icon: Icons.developer_mode,
            //   label: 'أدوات المطور',
            //   color: Colors.grey[200]!,
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => AdminDevToolsScreen(),
            //       ),
            //     );
            //   },
            // ),
            QuickActionCard(
              icon: Icons.image,
              label: 'صور العروض',
              color: Colors.orange[100]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BannerManagementScreen(),
                  ),
                );
              },
            ),
            // QuickActionCard(
            //   icon: Icons.bug_report,
            //   label: 'إنشاء طلب تجريبي',
            //   color: Colors.red[100]!,
            //   onTap: onCreateTestOrder,
            // ),
          ],
        ),
      ],
    );
  }
}
