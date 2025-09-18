import 'package:flutter/material.dart';
import 'metric_card.dart';

class DashboardMetrics extends StatelessWidget {
  final Map<String, dynamic> stats;

  const DashboardMetrics({super.key, required this.stats});

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} ج.م';
  }

  Color _getPercentColor(int percent) {
    if (percent > 0) {
      return Colors.green;
    } else if (percent < 0) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  String _formatPercent(int percent) {
    if (percent > 0) {
      return '+$percent%';
    } else if (percent < 0) {
      return '$percent%';
    } else {
      return '0%';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 20,
      childAspectRatio: 0.8,
      children: [
        MetricCard(
          icon: Icons.shopping_bag,
          iconColor: Colors.blue,
          title: 'الطلبات الجديدة',
          value: '${stats['newOrders'] ?? 0}',
          percent: _formatPercent(stats['ordersChangePercent'] ?? 0),
          percentColor: _getPercentColor(stats['ordersChangePercent'] ?? 0),
        ),
        MetricCard(
          icon: Icons.bar_chart,
          iconColor: Colors.orange,
          title: 'إجمالي المبيعات',
          value: _formatCurrency(stats['todaySales'] ?? 0.0),
          percent: _formatPercent(stats['salesChangePercent'] ?? 0),
          percentColor: _getPercentColor(stats['salesChangePercent'] ?? 0),
        ),
        MetricCard(
          icon: Icons.people,
          iconColor: Colors.purple,
          title: 'إجمالي العملاء',
          value: '${stats['totalCustomers'] ?? 0}',
          percent: _formatPercent(stats['customersChangePercent'] ?? 0),
          percentColor: _getPercentColor(stats['customersChangePercent'] ?? 0),
        ),
        MetricCard(
          icon: Icons.rate_review,
          iconColor: Colors.blue,
          title: 'مراجعات بانتظار الموافقة',
          value: '${stats['pendingReviews'] ?? 0}',
          percent:
              stats['pendingReviews'] != null && stats['pendingReviews'] > 0
              ? 'جديد'
              : 'لا يوجد',
          percentColor:
              stats['pendingReviews'] != null && stats['pendingReviews'] > 0
              ? Colors.blue
              : Colors.grey,
        ),
      ],
    );
  }
}
