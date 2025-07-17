import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fouda_market/models/order_model.dart';
import 'package:fouda_market/core/services/order_service.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/views/profile/orders_screen.dart';
import '../../routes.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final order = await OrderService().getOrderById(widget.orderId);
      
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الطلب'),
          backgroundColor: AppColors.orangeColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // التحقق من وجود صفحات سابقة في الـ navigation stack
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(AppRoutes.orders);
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _order != null
                    ? _buildOrderDetails()
                    : _buildNotFoundState(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل تفاصيل الطلب',
            style: TextStyle(fontSize: 18, color: Colors.red[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'خطأ غير معروف',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لم يتم العثور على الطلب',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'الطلب برقم ${widget.orderId} غير موجود',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    final order = _order!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الطلب الأساسية
          _buildOrderHeader(order),
          const SizedBox(height: 16),
          
          // حالة الطلب
          _buildOrderStatus(order),
          const SizedBox(height: 16),
          
          // معلومات التوصيل
          _buildDeliveryInfo(order),
          const SizedBox(height: 16),
          
          // عناصر الطلب
          _buildOrderItems(order),
          const SizedBox(height: 16),
          
          // ملخص السعر
          _buildPriceSummary(order),
          const SizedBox(height: 16),
          
          // معلومات كود الخصم
          if (order.promoCode != null) ...[
            _buildPromoCodeInfo(order),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: AppColors.orangeColor),
                const SizedBox(width: 8),
                const Text(
                  'معلومات الطلب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('رقم الطلب', order.id),
            _buildInfoRow('تاريخ الطلب', _formatDate(order.createdAt)),
            _buildInfoRow('وقت الطلب', _formatTime(order.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus(OrderModel order) {
    final statusColors = {
      'pending': Colors.orange,
      'accepted': Colors.blue,
      'preparing': Colors.purple,
      'delivering': Colors.indigo,
      'delivered': Colors.green,
      'cancelled': Colors.red,
      'failed': Colors.red,
    };

    final statusTexts = {
      'pending': 'في انتظار التأكيد',
      'accepted': 'تم القبول',
      'preparing': 'جاري التحضير',
      'delivering': 'جاري التوصيل',
      'delivered': 'تم التوصيل',
      'cancelled': 'ملغي',
      'failed': 'فشل',
    };

    final color = statusColors[order.status] ?? Colors.grey;
    final text = statusTexts[order.status] ?? order.status;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.info_outline, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.orangeColor),
                const SizedBox(width: 8),
                const Text(
                  'معلومات التوصيل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (order.deliveryAddressName != null)
              _buildInfoRow('الاسم', order.deliveryAddressName!),
            if (order.deliveryPhone != null)
              _buildInfoRow('الهاتف', order.deliveryPhone!),
            if (order.deliveryAddress != null)
              _buildInfoRow('العنوان', order.deliveryAddress!),
            if (order.estimatedDeliveryTime != null)
              _buildInfoRow('وقت التوصيل المتوقع', _formatDateTime(order.estimatedDeliveryTime!)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag, color: AppColors.orangeColor),
                const SizedBox(width: 8),
                const Text(
                  'المنتجات المطلوبة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (item.productImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.productImage!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image, color: Colors.grey[600]),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'الكمية: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'السعر: ${item.price.toStringAsFixed(2)} جنيه',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${item.total.toStringAsFixed(2)} جنيه',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppColors.orangeColor),
                const SizedBox(width: 8),
                const Text(
                  'ملخص السعر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPriceRow('المجموع الفرعي', order.subtotal),
            if (order.discountAmount != null && order.discountAmount! > 0)
              _buildPriceRow('الخصم', -order.discountAmount!, isDiscount: true),
            const Divider(),
            _buildPriceRow('الإجمالي', order.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeInfo(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.discount, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'كود الخصم المستخدم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('الكود', order.promoCode!),
            if (order.promoCodeDiscountPercentage != null)
              _buildInfoRow('نسبة الخصم', '${order.promoCodeDiscountPercentage!.toStringAsFixed(0)}%'),
            if (order.promoCodeMaxDiscount != null)
              _buildInfoRow('الحد الأقصى للخصم', '${order.promoCodeMaxDiscount!.toStringAsFixed(2)} جنيه'),
            if (order.discountAmount != null)
              _buildInfoRow('قيمة الخصم المطبقة', '${order.discountAmount!.toStringAsFixed(2)} جنيه'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${amount.toStringAsFixed(2)} جنيه',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.orangeColor : (isDiscount ? Colors.green : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }
} 