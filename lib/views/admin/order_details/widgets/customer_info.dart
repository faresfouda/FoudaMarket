import 'package:flutter/material.dart';

class CustomerInfo extends StatelessWidget {
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddressName;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? deliveryNotes;

  const CustomerInfo({
    super.key,
    this.customerName,
    this.customerPhone,
    this.deliveryAddressName,
    this.deliveryAddress,
    this.deliveryPhone,
    this.deliveryNotes,
  });

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.black, size: 28),
              const SizedBox(width: 10),
              const Text(
                'معلومات العميل والتوصيل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (customerName != null) _buildInfoRow('اسم العميل', customerName!),
          if (customerPhone != null)
            _buildInfoRow('هاتف العميل', customerPhone!),
          if (deliveryAddressName != null)
            _buildInfoRow('اسم العنوان', deliveryAddressName!),
          if (deliveryAddress != null)
            _buildInfoRow('عنوان التوصيل', deliveryAddress!),
          if (deliveryPhone != null)
            _buildInfoRow('هاتف التوصيل', deliveryPhone!),
          if (deliveryNotes != null && deliveryNotes!.isNotEmpty)
            _buildInfoRow('ملاحظات التوصيل', deliveryNotes!),
        ],
      ),
    );
  }
}
