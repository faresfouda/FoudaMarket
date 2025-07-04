import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final String orderNumber;
  final String date;
  final String status;
  final String total;
  final List<Map<String, String>> items; // Each item: name, qty, price, image

  const AdminOrderDetailsScreen({
    Key? key,
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
  }) : super(key: key);

  @override
  State<AdminOrderDetailsScreen> createState() => _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = widget.status;
  }

  void _changeStatus() async {
    final List<String> statusOptions = [
      'جديد',
      'قيد التنفيذ',
      'مكتمل',
      'تم التوصيل',
      'ملغي',
    ];
    final Map<String, IconData> statusIcons = {
      'جديد': Icons.fiber_new,
      'قيد التنفيذ': Icons.timelapse,
      'مكتمل': Icons.check_circle,
      'تم التوصيل': Icons.local_shipping,
      'ملغي': Icons.cancel,
    };
    final Map<String, Color> statusColors = {
      'جديد': AppColors.orangeColor,
      'قيد التنفيذ': AppColors.orangeColor,
      'مكتمل': Colors.green,
      'تم التوصيل': Colors.green,
      'ملغي': Colors.red,
    };
    String? selected = await showModalBottomSheet<String>(
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
              title: Text(option, style: TextStyle(
                color: option == status ? statusColors[option] : Colors.black,
                fontWeight: option == status ? FontWeight.bold : FontWeight.normal,
              )),
              trailing: option == status ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () => Navigator.pop(context, option),
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
    if (selected != null && selected != status) {
      setState(() {
        status = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (status == 'مكتمل' || status == 'تم التوصيل') {
      statusColor = Colors.green;
    } else if (status == 'قيد التنفيذ' || status == 'جديد') {
      statusColor = AppColors.orangeColor;
    } else {
      statusColor = Colors.red;
    }

    // Calculate item totals and overall total
    double overallTotal = 0;
    List<Map<String, dynamic>> itemDetails = widget.items.map((item) {
      int qty = int.tryParse(item['qty'] ?? '0') ?? 0;
      double price = double.tryParse(item['price'] ?? '0') ?? 0.0;
      double itemTotal = qty * price;
      overallTotal += itemTotal;
      return {
        ...item,
        'qty': qty,
        'price': price,
        'itemTotal': itemTotal,
      };
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('تفاصيل الطلب', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                        const Icon(Icons.receipt_long, color: Colors.black, size: 28),
                        const SizedBox(width: 10),
                        Text('طلب رقم: ${widget.orderNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(fontSize: 15, color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.black, size: 22),
                        const SizedBox(width: 8),
                        Text(widget.date, style: const TextStyle(fontSize: 16, color: Colors.black)),
                        const Spacer(),
                        const Icon(Icons.attach_money, color: Colors.black, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          overallTotal.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('المنتجات المطلوبة:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              ...itemDetails.map((item) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: item['image'] != null && (item['image'] as String).isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            item['image'],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, size: 48, color: Colors.grey),
                  title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text('الكمية: ${item['qty']} × السعر: ${item['price']}'),
                  trailing: Text(
                    (item['itemTotal'] as double).toStringAsFixed(2),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              )),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _changeStatus,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('تغيير حالة الطلب', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 