import 'package:flutter/material.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  // Mock data
  final double totalSales = 24500.0;
  final int totalOrders = 187;
  final List<Map<String, dynamic>> topProducts = [
    {'name': 'تفاح أحمر', 'sales': 120, 'amount': 4800.0},
    {'name': 'موز عضوي', 'sales': 90, 'amount': 3600.0},
    {'name': 'خبز بلدي', 'sales': 70, 'amount': 2100.0},
    {'name': 'طماطم بلدي', 'sales': 60, 'amount': 1800.0},
    {'name': 'خيار طازج', 'sales': 50, 'amount': 1500.0},
  ];

  final List<Map<String, dynamic>> topUsers = [
    {'name': 'أحمد محمد', 'spent': 5200.0, 'orders': 18},
    {'name': 'سارة أحمد', 'spent': 4100.0, 'orders': 15},
    {'name': 'فاطمة علي', 'spent': 3900.0, 'orders': 13},
    {'name': 'محمد حسن', 'spent': 3200.0, 'orders': 10},
    {'name': 'خالد يوسف', 'spent': 2800.0, 'orders': 8},
  ];

  String get dateRangeLabel {
    if (fromDate == null && toDate == null) return 'كل الوقت';
    String format(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    if (fromDate != null && toDate != null) {
      return '${format(fromDate!)} - ${format(toDate!)}';
    } else if (fromDate != null) {
      return 'من ${format(fromDate!)}';
    } else {
      return 'حتى ${format(toDate!)}';
    }
  }

  Future<void> pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? fromDate : toDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير المبيعات'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.date_range),
                    label: Text(fromDate == null ? 'من' : '${fromDate!.year}/${fromDate!.month.toString().padLeft(2, '0')}/${fromDate!.day.toString().padLeft(2, '0')}'),
                    onPressed: () => pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.date_range),
                    label: Text(toDate == null ? 'إلى' : '${toDate!.year}/${toDate!.month.toString().padLeft(2, '0')}/${toDate!.day.toString().padLeft(2, '0')}'),
                    onPressed: () => pickDate(isFrom: false),
                  ),
                ),
                if (fromDate != null || toDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () => setState(() { fromDate = null; toDate = null; }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('إجمالي المبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('ج.م $totalSales', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('عدد الطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$totalOrders', style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('المنتجات الأكثر مبيعاً', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = topProducts[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[50],
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('عدد المبيعات: ${p['sales']}'),
                    trailing: Text('ج.م ${p['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('أهم العملاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final u = topUsers[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('عدد الطلبات: ${u['orders']}'),
                    trailing: Text('ج.م ${u['spent']}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 