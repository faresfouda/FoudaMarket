import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ExpandableSection extends StatelessWidget {
  final String title;
  final Widget? contentWidget;
  final bool isExpanded;
  final VoidCallback onTap;
  final String? trailingText;
  final Widget? trailingWidget;

  const ExpandableSection({
    super.key,
    required this.title,
    this.contentWidget,
    required this.isExpanded,
    required this.onTap,
    this.trailingText,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isExpanded && trailingText != null)
                      Text(
                        trailingText!,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (!isExpanded && trailingWidget != null) trailingWidget!,
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && contentWidget != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: contentWidget!,
          ),
      ],
    );
  }
}
