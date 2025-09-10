import 'package:flutter/material.dart';
import 'activity_item.dart';

class DashboardActivity extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final VoidCallback onRefresh;
  final VoidCallback onViewAll;

  const DashboardActivity({
    super.key,
    required this.activities,
    required this.onRefresh,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'النشاط الأخير',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            _buildEmptyState()
          else
            _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.timeline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد نشاط حديث',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيظهر النشاط الأخير هنا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    // Show only the first 5 activities
    final displayActivities = activities.take(5).toList();

    return Column(
      children: [
        ...displayActivities.map((activity) => ActivityItem(activity: activity)),
        if (activities.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'و ${activities.length - 5} أنشطة أخرى...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
