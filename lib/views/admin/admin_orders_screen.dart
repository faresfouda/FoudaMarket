import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';
import '../../components/search_field.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

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
  OrderStatus selectedStatus = OrderStatus.all;
  final TextEditingController searchController = TextEditingController();

  final List<_Order> allOrders = [
    _Order(id: '12345', customerName: 'أحمد محمد', date: 'اليوم، 2:30 م', total: 250.50, status: OrderStatus.newOrder),
    _Order(id: '12344', customerName: 'فاطمة علي', date: 'اليوم، 1:15 م', total: 180.75, status: OrderStatus.inProgress),
    _Order(id: '12343', customerName: 'محمد حسن', date: 'أمس، 11:45 ص', total: 320.25, status: OrderStatus.completed),
    _Order(id: '12342', customerName: 'سارة أحمد', date: 'أمس، 9:20 ص', total: 95.00, status: OrderStatus.cancelled),
  ];

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
                            if (order.status == OrderStatus.newOrder || order.status == OrderStatus.inProgress)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                  label: const Text('تحديث الحالة', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            if (order.status == OrderStatus.completed)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: 0,
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Icons.check, size: 18, color: Colors.green),
                                  label: const Text('مكتمل', style: TextStyle(color: Colors.green)),
                                ),
                              ),
                            if (order.status == OrderStatus.cancelled)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                                  label: const Text('حذف', style: TextStyle(color: Colors.white)),
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
                                onPressed: () {},
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