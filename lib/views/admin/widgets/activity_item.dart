import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityItem({
    super.key,
    required this.activity,
  });

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'تفاصيل الطلب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم الطلب: ${activity['orderId']?.substring(0, 8) ?? 'غير محدد'}',
                style: const TextStyle(fontSize: 11),
              ),
              Text(
                '${activity['orderTotal'] ?? 0} ج.م',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحالة: ${_getOrderStatusText(activity['orderStatus'])}',
                style: const TextStyle(fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(activity['orderStatus']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getOrderStatusText(activity['orderStatus']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'تفاصيل المراجعة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (activity['reviewRating'] ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 12,
                );
              }),
              const SizedBox(width: 6),
              Text(
                '${activity['reviewRating'] ?? 0}/5',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          if (activity['reviewText']?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              'التعليق: ${activity['reviewText']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحالة: ${_getReviewStatusText(activity['reviewStatus'])}',
                style: const TextStyle(fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getReviewStatusColor(activity['reviewStatus']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getReviewStatusText(activity['reviewStatus']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    final isNew = activity['isNewProduct'] ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNew ? Icons.add_circle : Icons.edit,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'تفاصيل المنتج',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (activity['productImage'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    activity['productImage'],
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 30,
                        height: 30,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 16, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['productName'] ?? 'غير محدد',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${activity['productPrice'] ?? 0} ج.م',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final String type = activity['type'] ?? '';
    final String text = activity['text'] ?? activity['description'] ?? '';
    final String details = activity['details'] ?? '';
    final DateTime timestamp = _parseTimestamp(activity['timestamp']);
    final String time = activity['time'] ?? _formatTimestamp(timestamp);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getActivityColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getActivityIcon(type),
                  color: _getActivityColor(type),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          // تفاصيل إضافية حسب نوع النشاط
          if (activity['type'] == 'order') ...[
            _buildOrderDetails(),
          ] else if (activity['type'] == 'review') ...[
            _buildReviewDetails(),
          ] else if (activity['type'] == 'product') ...[
            _buildProductDetails(),
          ],
        ],
      ),
    );
  }

  // Helper method to convert Firestore Timestamp to DateTime
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'product':
        return Colors.green;
      case 'user':
        return Colors.orange;
      case 'review':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'product':
        return Icons.inventory;
      case 'user':
        return Icons.person;
      case 'review':
        return Icons.star;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
      return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
    }
  }
}
