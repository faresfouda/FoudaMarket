import 'package:flutter/material.dart';
import '../../../../theme/appcolors.dart';

class StatusUpdateButton extends StatelessWidget {
  final bool isUpdating;
  final bool isOffline;
  final Function(String) onStatusChange;

  const StatusUpdateButton({
    super.key,
    required this.isUpdating,
    required this.isOffline,
    required this.onStatusChange,
  });

  void _changeStatus(BuildContext context) async {
    final List<String> statusOptions = [
      'جديد',
      'مقبول',
      'قيد التحضير',
      'قيد التوصيل',
      'مكتمل',
      'ملغي',
    ];
    final Map<String, IconData> statusIcons = {
      'جديد': Icons.fiber_new,
      'مقبول': Icons.check_circle_outline,
      'قيد التحضير': Icons.timelapse,
      'قيد التوصيل': Icons.local_shipping,
      'مكتمل': Icons.check_circle,
      'ملغي': Icons.cancel,
    };
    final Map<String, Color> statusColors = {
      'جديد': AppColors.orangeColor,
      'مقبول': Colors.blue,
      'قيد التحضير': AppColors.orangeColor,
      'قيد التوصيل': Colors.teal,
      'مكتمل': Colors.green,
      'ملغي': Colors.red,
    };
    String? selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'تغيير حالة الطلب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...statusOptions.map(
              (option) => ListTile(
                leading: Icon(statusIcons[option], color: statusColors[option]),
                title: Text(
                  option,
                  style: TextStyle(
                    color: statusColors[option],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => Navigator.pop(context, option),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
    if (selected != null) {
      onStatusChange(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: (isUpdating || isOffline)
          ? null
          : () => _changeStatus(context),
      backgroundColor: AppColors.orangeColor,
      icon: isUpdating
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.edit, color: Colors.white),
      label: Text(
        isUpdating ? 'جاري التحديث...' : 'تغيير الحالة',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
