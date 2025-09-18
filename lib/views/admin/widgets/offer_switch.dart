import 'package:flutter/material.dart';
import '../../../theme/appcolors.dart';

class OfferSwitch extends StatelessWidget {
  final bool hasOffer;
  final ValueChanged<bool> onChanged;
  final Widget? offerPriceField;

  const OfferSwitch({
    super.key,
    required this.hasOffer,
    required this.onChanged,
    this.offerPriceField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Switch(
                value: hasOffer,
                onChanged: onChanged,
                activeColor: AppColors.orangeColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تفعيل عرض خاص على هذا المنتج',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasOffer && offerPriceField != null) ...[
          const SizedBox(height: 16),
          offerPriceField!,
        ],
      ],
    );
  }
}
