import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({Key? key, required this.message, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.orangeColor, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangeColor),
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
            ),
          ]
        ],
      ),
    );
  }
} 