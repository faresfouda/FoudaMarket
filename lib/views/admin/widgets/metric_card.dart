import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String percent;
  final Color percentColor;

  const MetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.percent,
    required this.percentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20 to 16
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
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40, // Reduced from 48 to 40
                height: 40, // Reduced from 48 to 40
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10), // Adjusted accordingly
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20, // Reduced from 24 to 20
                ),
              ),
              Flexible( // Added Flexible to prevent overflow
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, // Reduced from 8 to 6
                    vertical: 3, // Reduced from 4 to 3
                  ),
                  decoration: BoxDecoration(
                    color: percentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10), // Reduced from 12
                  ),
                  child: Text(
                    percent,
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12 to 11
                      fontWeight: FontWeight.w600,
                      color: percentColor,
                    ),
                    overflow: TextOverflow.ellipsis, // Added overflow handling
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16 to 12
          Flexible( // Added Flexible wrapper
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13, // Reduced from 14 to 13
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2, // Added line limit
              overflow: TextOverflow.ellipsis, // Added overflow handling
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8 to 6
          Flexible( // Added Flexible wrapper
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20, // Reduced from 24 to 20
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 1, // Added line limit
              overflow: TextOverflow.ellipsis, // Added overflow handling
            ),
          ),
        ],
      ),
    );
  }
}
