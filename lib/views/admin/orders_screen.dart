import 'package:flutter/material.dart';
import 'package:fouda_market/views/admin/order_details_screen.dart';
import 'package:fouda_market/models/order_model.dart';
import 'package:fouda_market/core/services/order_service.dart';
import 'package:fouda_market/core/services/auth_service.dart';
import '../../theme/appcolors.dart';
import '../../components/search_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatefulWidget {
  final String? initialFilter;
  const OrdersScreen({Key? key, this.initialFilter}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

enum OrderStatus { all, newOrder, inProgress, completed, cancelled }

class _OrdersScreenState extends State<OrdersScreen> {
  late OrderStatus selectedStatus;
  final TextEditingController searchController = TextEditingController();
  final OrderService _orderService = OrderService();
  
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'جديد') {
      selectedStatus = OrderStatus.newOrder;
    } else {
      selectedStatus = OrderStatus.all;
    }
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orders = await _orderService.getAllOrders();
      
      if (mounted) {
        setState(() {
          _allOrders = orders;
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

  List<OrderModel> get filteredOrders {
    String query = searchController.text.trim();
    return _allOrders.where((order) {
      bool matchesStatus = selectedStatus == OrderStatus.all || 
          _getOrderStatus(order.status) == selectedStatus;
      bool matchesQuery = query.isEmpty ||
          order.deliveryAddressName?.contains(query) == true ||
          order.id.contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  OrderStatus _getOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
        return OrderStatus.newOrder;
      case 'accepted':
      case 'preparing':
      case 'delivering':
        return OrderStatus.inProgress;
      case 'delivered':
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
      case 'failed':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.newOrder;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
        return 'جديد';
      case 'accepted':
        return 'مقبول';
      case 'preparing':
        return 'قيد التحضير';
      case 'delivering':
        return 'قيد التوصيل';
      case 'delivered':
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'failed':
        return 'فشل';
      default:
        return 'جديد';
    }
  }

  Color statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return AppColors.orangeColor;
      case OrderStatus.inProgress:
        return Colors.teal;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  String statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return 'جديد';
      case OrderStatus.inProgress:
        return 'قيد التنفيذ';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.cancelled:
        return 'ملغي';
      default:
        return 'الكل';
    }
  }

  OrderStatus statusFromText(String text) {
    switch (text) {
      case 'جديد':
        return OrderStatus.newOrder;
      case 'قيد التنفيذ':
        return OrderStatus.inProgress;
      case 'مكتمل':
        return OrderStatus.completed;
      case 'ملغي':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.all;
    }
  }

  String _getStatusForUpdate(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return 'pending';
      case OrderStatus.inProgress:
        return 'preparing';
      case OrderStatus.completed:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  Future<OrderStatus?> showStatusBottomSheet(
    BuildContext context,
    OrderStatus currentStatus,
  ) async {
    final List<OrderStatus> statusOptions = [
      OrderStatus.newOrder,
      OrderStatus.inProgress,
      OrderStatus.completed,
      OrderStatus.cancelled,
    ];
    final Map<OrderStatus, IconData> statusIcons = {
      OrderStatus.newOrder: Icons.fiber_new,
      OrderStatus.inProgress: Icons.timelapse,
      OrderStatus.completed: Icons.check_circle,
      OrderStatus.cancelled: Icons.cancel,
    };
    final Map<OrderStatus, Color> statusColors = {
      OrderStatus.newOrder: AppColors.orangeColor,
      OrderStatus.inProgress: AppColors.orangeColor,
      OrderStatus.completed: Colors.green,
      OrderStatus.cancelled: Colors.red,
    };
    return await showModalBottomSheet<OrderStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'تغيير حالة الطلب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...statusOptions.map(
              (option) => ListTile(
                leading: Icon(statusIcons[option], color: statusColors[option]),
                title: Text(
                  statusText(option),
                  style: TextStyle(
                    color: option == currentStatus
                        ? statusColors[option]
                        : Colors.black,
                    fontWeight: option == currentStatus
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: option == currentStatus
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم، ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'أمس، ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            SearchField(
              controller: searchController,
              hintText: '...البحث بالاسم أو رقم الطلب',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Status filter row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...OrderStatus.values.map((status) {
                    if (status == OrderStatus.all) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(statusText(status)),
                          selected: selectedStatus == status,
                          onSelected: (_) =>
                              setState(() => selectedStatus = status),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selectedStatus == status
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(statusText(status)),
                        selected: selectedStatus == status,
                        onSelected: (_) =>
                            setState(() => selectedStatus = status),
                        selectedColor: statusColor(status),
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selectedStatus == status
                              ? Colors.white
                              : statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // أزرار الاختبار
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final isConnected = await _orderService.testVercelApiConnection();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isConnected 
                                ? '✅ الاتصال بـ Vercel API يعمل بشكل صحيح'
                                : '❌ مشكلة في الاتصال بـ Vercel API'),
                              backgroundColor: isConnected ? Colors.green : Colors.red,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ خطأ في اختبار الاتصال: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.wifi, size: 16),
                      label: Text('اختبار الاتصال', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final fcmToken = await _orderService.getUserFcmToken(user.uid);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(fcmToken != null 
                                  ? '✅ FCM Token موجود: ${fcmToken.substring(0, 20)}...'
                                  : '❌ FCM Token غير موجود'),
                                backgroundColor: fcmToken != null ? Colors.green : Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ خطأ في فحص FCM Token: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.token, size: 16),
                      label: Text('فحص FCM Token', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Orders list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'حدث خطأ في تحميل الطلبات',
                                style: TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadOrders,
                                child: Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد طلبات',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
              child: ListView.separated(
                itemCount: filteredOrders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                                  final orderStatus = _getOrderStatus(order.status);
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                                            if (orderStatus != OrderStatus.all)
                                              Flexible(
                                                child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor(
                                                      orderStatus,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                                    _getStatusText(order.status),
                                  style: TextStyle(
                                                      color: statusColor(orderStatus),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                                            Flexible(
                                              child: Text(
                              '#${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                                          order.deliveryAddressName ?? 'عميل غير محدد',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                                          _formatDate(order.createdAt),
                          style: TextStyle(
                            color: AppColors.lightGrayColor2,
                            fontSize: 13,
                          ),
                                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                                          'ج.م ${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // صف الأزرار الأول
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: statusColor(orderStatus),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  final newStatus = await showStatusBottomSheet(
                                    context,
                                    orderStatus,
                                  );
                                  if (newStatus != null &&
                                      newStatus != orderStatus) {
                                    try {
                                      await _orderService.updateOrderStatus(
                                        order.id,
                                        _getStatusForUpdate(newStatus),
                                      );
                                      // Refresh orders after update
                                      _loadOrders();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم تحديث حالة الطلب بنجاح'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('فشل في تحديث حالة الطلب: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'تحديث الحالة',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  try {
                                    // جلب fcmToken للمستخدم
                                    final userDoc = await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(order.userId)
                                        .get();
                                    final userData = userDoc.data();
                                    final fcmToken = userData != null ? userData['fcmToken'] : null;
                                    
                                    if (fcmToken != null && fcmToken.isNotEmpty) {
                                      await _orderService.testNotification(
                                        fcmToken: fcmToken,
                                        orderId: order.id,
                                        status: order.status,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم إرسال إشعار تجريبي'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('لا يوجد FCM Token للمستخدم'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('فشل في إرسال الإشعار التجريبي: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.notifications,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'اختبار الإشعار',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // زر عرض التفاصيل في صف منفصل
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminOrderDetailsScreen(
                                        orderNumber: order.id,
                                        date: _formatDate(order.createdAt),
                                        status: _getStatusText(order.status),
                                        total: 'ج.م ${order.total.toStringAsFixed(2)}',
                                        items: order.items.map((item) => {
                                          'name': item.productName,
                                          'qty': item.quantity.toString(),
                                          'price': '${item.price.toStringAsFixed(2)} ج.م',
                                          'image': item.productImage ?? 'assets/home/logo.jpg',
                                        }).toList(),
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.remove_red_eye,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'عرض التفاصيل',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

