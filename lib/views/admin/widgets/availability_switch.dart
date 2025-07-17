import 'package:flutter/material.dart';

class AvailabilitySwitch extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const AvailabilitySwitch({
    super.key,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
          const SizedBox(width: 12),
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            isAvailable ? 'متوفر للطلب' : 'غير متوفر',
            style: TextStyle(
              color: isAvailable ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
