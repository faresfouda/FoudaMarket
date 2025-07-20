import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  const LoadingIndicator({Key? key, this.size = 32, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.orangeColor),
        ),
      ),
    );
  }
} 