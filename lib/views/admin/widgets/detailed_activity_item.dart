import 'package:flutter/material.dart';

class DetailedActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String time;
  final String details;
  final Map<String, dynamic> activityData;

  const DetailedActivityItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.time,
    required this.details,
    required this.activityData,
  });

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'تفاصيل الطلب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم الطلب: ${activityData['orderId']?.substring(0, 8) ?? 'غير محدد'}',
              ),
              Text('${activityData['orderTotal']} ج.م'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحالة: ${_getOrderStatusText(activityData['orderStatus'])}',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(activityData['orderStatus']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getOrderStatusText(activityData['orderStatus']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (activityData['updatedBy'] != null ||
              activityData['updatedAt'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (activityData['updatedBy'] != null)
                  Expanded(
                    child: Text(
                      'تم التحديث بواسطة: ${activityData['updatedBy']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                if (activityData['updatedAt'] != null) ...[
                  if (activityData['updatedBy'] != null)
                    const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(activityData['updatedAt']),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'تفاصيل المراجعة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (activityData['reviewRating'] ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
              const SizedBox(width: 8),
              Text('${activityData['reviewRating'] ?? 0}/5'),
            ],
          ),
          if (activityData['reviewText']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'التعليق: ${activityData['reviewText']}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحالة: ${_getReviewStatusText(activityData['reviewStatus'])}',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReviewStatusColor(activityData['reviewStatus']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getReviewStatusText(activityData['reviewStatus']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (activityData['updatedBy'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'تم ${_getReviewActionText(activityData['reviewStatus'])} بواسطة: ${activityData['updatedBy']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    final isNew = activityData['isNewProduct'] ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNew ? Icons.add_circle : Icons.edit,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'تفاصيل المنتج',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (activityData['productImage'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    activityData['productImage'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityData['productName'] ?? 'غير محدد',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${activityData['productPrice']} ج.م',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activityData['updatedBy'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'تم ${isNew ? 'الإضافة' : 'التحديث'} بواسطة: ${activityData['updatedBy']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _getOrderStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'في الانتظار';
      case 'confirmed':
      case 'accepted':
        return 'مقبول';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      case 'preparing':
        return 'قيد التحضير';
      case 'delivering':
        return 'قيد التوصيل';
      case 'failed':
        return 'فشل';
      case 'completed':
        return 'مكتمل';
      default:
        return 'غير محدد';
    }
  }

  Color _getOrderStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      case 'preparing':
        return Colors.amber;
      case 'delivering':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getReviewStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'في الانتظار';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير محدد';
    }
  }

  String _getReviewActionText(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'القبول';
      case 'rejected':
        return 'الرفض';
      default:
        return 'التحديث';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime? dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp);
    } else if (timestamp is Map && timestamp['_seconds'] != null) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(
        timestamp['_seconds'] * 1000,
      );
    } else if (timestamp.runtimeType.toString() == 'Timestamp') {
      // Handle Firestore Timestamp
      dateTime = timestamp.toDate();
    }

    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return 'منذ $minutes ${minutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return 'منذ $hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return 'منذ $days ${days == 1 ? 'يوم' : 'أيام'}';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }

  Color _getReviewStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(time, style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            // تفاصيل إضافية حسب نوع النشاط
            if (activityData['type'] == 'order') ...[
              _buildOrderDetails(),
            ] else if (activityData['type'] == 'review') ...[
              _buildReviewDetails(),
            ] else if (activityData['type'] == 'product') ...[
              _buildProductDetails(),
            ],
          ],
        ),
      ),
    );
  }
}
