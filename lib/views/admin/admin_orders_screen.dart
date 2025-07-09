import 'package:flutter/material.dart';
import 'package:fodamarket/views/admin/order_details_screen.dart';
import '../../theme/appcolors.dart';
import '../../components/search_field.dart';


class AdminOrdersScreen extends StatefulWidget {
  final String? initialFilter;
  const AdminOrdersScreen({Key? key, this.initialFilter}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

enum OrderStatus { all, newOrder, inProgress, completed, cancelled }

class _Order {
  final String id;
  final String customerName;
  final String date;
  final double total;
  final OrderStatus status;

  const _Order({
    required this.id,
    required this.customerName,
    required this.date,
    required this.total,
    required this.status,
  });
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late OrderStatus selectedStatus;
  final TextEditingController searchController = TextEditingController();

  final List<_Order> allOrders = [
    _Order(id: '12345', customerName: 'أحمد محمد', date: 'اليوم، 2:30 م', total: 250.50, status: OrderStatus.newOrder),
    _Order(id: '12344', customerName: 'فاطمة علي', date: 'اليوم، 1:15 م', total: 180.75, status: OrderStatus.inProgress),
    _Order(id: '12343', customerName: 'محمد حسن', date: 'أمس، 11:45 ص', total: 320.25, status: OrderStatus.completed),
    _Order(id: '12342', customerName: 'سارة أحمد', date: 'أمس، 9:20 ص', total: 95.00, status: OrderStatus.cancelled),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'جديد') {
      selectedStatus = OrderStatus.newOrder;
    } else {
      selectedStatus = OrderStatus.all;
    }
  }

  List<_Order> get filteredOrders {
    String query = searchController.text.trim();
    return allOrders.where((order) {
      bool matchesStatus = selectedStatus == OrderStatus.all || order.status == selectedStatus;
      bool matchesQuery = query.isEmpty ||
        order.customerName.contains(query) ||
        order.id.contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
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

  Future<OrderStatus?> showStatusBottomSheet(BuildContext context, OrderStatus currentStatus) async {
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
            const Text('تغيير حالة الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...statusOptions.map((option) => ListTile(
              leading: Icon(
                statusIcons[option],
                color: statusColors[option],
              ),
              title: Text(statusText(option), style: TextStyle(
                color: option == currentStatus ? statusColors[option] : Colors.black,
                fontWeight: option == currentStatus ? FontWeight.bold : FontWeight.normal,
              )),
              trailing: option == currentStatus ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () => Navigator.pop(context, option),
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Remove custom header row, rely on dashboard app bar
            // const SizedBox(height: 16),
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
                          onSelected: (_) => setState(() => selectedStatus = status),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selectedStatus == status ? Colors.white : AppColors.primary,
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
                        onSelected: (_) => setState(() => selectedStatus = status),
                        selectedColor: statusColor(status),
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selectedStatus == status ? Colors.white : statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Orders list
            Expanded(
              child: ListView.separated(
                itemCount: filteredOrders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
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
                            if (order.status != OrderStatus.all)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor(order.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusText(order.status),
                                  style: TextStyle(
                                    color: statusColor(order.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(order.date, style: TextStyle(color: AppColors.lightGrayColor2, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('ج.م ${order.total}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: statusColor(order.status),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () async {
                                  final newStatus = await showStatusBottomSheet(context, order.status);
                                  if (newStatus != null && newStatus != order.status) {
                                    setState(() {
                                      final idx = allOrders.indexOf(order);
                                      allOrders[idx] = _Order(
                                        id: order.id,
                                        customerName: order.customerName,
                                        date: order.date,
                                        total: order.total,
                                        status: newStatus,
                                      );
                                    });
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                label: const Text('تحديث الحالة', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminOrderDetailsScreen(
                                        orderNumber: order.id,
                                        date: order.date,
                                        status: statusText(order.status),
                                        total: 'ج.م ${order.total}',
                                        items: [
                                          {
                                            'name': 'بيض بلدي',
                                            'qty': '2',
                                            'price': '40 ج.م',
                                            'image': 'assets/home/logo.jpg',
                                          },
                                          {
                                            'name': 'مكرونة',
                                            'qty': '1',
                                            'price': '20 ج.م',
                                            'image': 'assets/home/logo.jpg',
                                          },
                                          {
                                            'name': 'زيت',
                                            'qty': '1',
                                            'price': '60 ج.م',
                                            'image': 'assets/home/logo.jpg',
                                          },
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.remove_red_eye, size: 18, color: Colors.white),
                                label: const Text('عرض التفاصيل', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 