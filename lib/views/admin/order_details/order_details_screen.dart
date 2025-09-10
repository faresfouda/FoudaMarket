import 'package:flutter/material.dart';
import 'package:fouda_market/core/services/order_service.dart';
import 'package:fouda_market/core/services/auth_service.dart';
import '../../../components/connection_aware_widget.dart';
import '../../../theme/appcolors.dart';
import 'widgets/order_header.dart';
import 'widgets/customer_info.dart';
import 'widgets/products_list.dart';
import 'widgets/status_update_button.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final String orderNumber;
  final String date;
  final String status;
  final String total;
  final List<Map<String, String>> items;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? deliveryAddressName;
  final String? deliveryPhone;
  final String? deliveryNotes;

  const AdminOrderDetailsScreen({
    super.key,
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryAddressName,
    this.deliveryPhone,
    this.deliveryNotes,
  });

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  late String status;
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  bool _isUpdating = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    status = widget.status;
  }

  String _getStatusForUpdate(String displayStatus) {
    switch (displayStatus) {
      case 'جديد':
        return 'pending';
      case 'مقبول':
        return 'accepted';
      case 'قيد التحضير':
        return 'preparing';
      case 'قيد التوصيل':
        return 'delivering';
      case 'مكتمل':
      case 'تم التوصيل':
        return 'delivered';
      case 'ملغي':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      setState(() {
        _isUpdating = true;
      });

      // الحصول على معلومات المسؤول
      final adminInfo = await _authService.getCurrentAdminInfo();
      if (adminInfo == null) {
        throw Exception('غير مصرح لك بتحديث حالة الطلب');
      }

      await _orderService.updateOrderStatus(
        widget.orderNumber,
        _getStatusForUpdate(newStatus),
        adminId: adminInfo['id']!,
        adminName: adminInfo['name'],
      );

      setState(() {
        status = newStatus;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة الطلب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث حالة الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (status == 'مكتمل' || status == 'تم التوصيل') {
      statusColor = Colors.green;
    } else if (status == 'قيد التوصيل' || status == 'قيد التحضير') {
      statusColor = Colors.teal;
    } else if (status == 'مقبول') {
      statusColor = Colors.blue;
    } else if (status == 'قيد التنفيذ' || status == 'جديد') {
      statusColor = AppColors.orangeColor;
    } else {
      statusColor = Colors.red;
    }

    // Calculate item totals
    List<Map<String, dynamic>> itemDetails = widget.items.map((item) {
      int qty = int.tryParse(item['qty'] ?? '0') ?? 0;
      double price =
          double.tryParse(item['price']?.replaceAll(' ج.م', '') ?? '0') ?? 0.0;
      double itemTotal = qty * price;
      return {...item, 'qty': qty, 'price': price, 'itemTotal': itemTotal};
    }).toList();

    return ConnectionAwareWidget(
      onConnectionChanged: (offline) {
        if (_isOffline != offline) {
          setState(() {
            _isOffline = offline;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'تفاصيل الطلب',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        floatingActionButton: StatusUpdateButton(
          isUpdating: _isUpdating,
          isOffline: _isOffline,
          onStatusChange: _updateOrderStatus,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderHeader(
                  orderNumber: widget.orderNumber,
                  date: widget.date,
                  total: widget.total,
                  status: status,
                  statusColor: statusColor,
                ),
                const SizedBox(height: 24),
                if (widget.customerName != null ||
                    widget.deliveryAddress != null)
                  CustomerInfo(
                    customerName: widget.customerName,
                    customerPhone: widget.customerPhone,
                    deliveryAddressName: widget.deliveryAddressName,
                    deliveryAddress: widget.deliveryAddress,
                    deliveryPhone: widget.deliveryPhone,
                    deliveryNotes: widget.deliveryNotes,
                  ),
                const SizedBox(height: 24),
                ProductsList(itemDetails: itemDetails),
                // إضافة مساحة في النهاية لتجنب تغطية FloatingActionButton
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
