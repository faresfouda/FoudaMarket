import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  double totalSales = 0.0;
  int totalOrders = 0;
  List<Map<String, dynamic>> topProducts = [];
  List<Map<String, dynamic>> topUsers = [];
  bool _isLoading = false;

  String get dateRangeLabel {
    if (fromDate == null && toDate == null) return 'كل الوقت';
    String format(DateTime d) =>
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
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
      await loadReport();
    }
  }

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<String> getProductName(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (doc.exists && doc.data() != null && doc.data()!['name'] != null) {
        return doc.data()!['name'];
      }
    } catch (_) {}
    return productId;
  }

  Future<String> getUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null && doc.data()!['name'] != null) {
        return doc.data()!['name'];
      }
    } catch (_) {}
    return userId;
  }

  Future<void> loadReport() async {
    setState(() => _isLoading = true);
    try {
      // جلب كل الطلبات المكتملة (بدون فلترة التاريخ من Firestore)
      Query query = FirebaseFirestore.instance.collection('orders')
        .where('status', whereIn: ['delivered', 'completed']);
      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // فلترة الطلبات حسب التاريخ في الكود
      List<Map<String, dynamic>> filteredOrders = orders;
      if (fromDate != null || toDate != null) {
        filteredOrders = orders.where((order) {
          final createdAtRaw = order['created_at'];
          DateTime? createdAt;
          if (createdAtRaw is String) {
            try {
              createdAt = DateTime.parse(createdAtRaw);
            } catch (_) {}
          } else if (createdAtRaw is Timestamp) {
            createdAt = createdAtRaw.toDate();
          }
          if (createdAt == null) return false;
          if (fromDate != null && createdAt.isBefore(fromDate!)) return false;
          if (toDate != null && createdAt.isAfter(toDate!.add(const Duration(days: 1)))) return false;
          return true;
        }).toList();
      }

      totalOrders = filteredOrders.length;
      totalSales = 0.0;
      final Map<String, Map<String, dynamic>> productSales = {};
      final Map<String, Map<String, dynamic>> userSales = {};
      final Set<String> missingProductIds = {};
      final Set<String> missingUserIds = {};
      for (final order in filteredOrders) {
        final total = (order['total'] ?? 0).toDouble();
        totalSales += total;
        // المنتجات
        if (order['items'] != null) {
          final List<Map<String, dynamic>> items = List.from(order['items']).cast<Map<String, dynamic>>();
          for (final item in items) {
            String name = item['product_name'] ?? '';
            if (name.isEmpty && item['product_id'] != null) {
              name = await getProductName(item['product_id']);
              missingProductIds.add(item['product_id']);
            }
            if (name.isEmpty) name = 'منتج';
            final quantity = (item['quantity'] ?? 1);
            final price = (item['price'] ?? 0);
            final amount = (price is num ? price.toDouble() : 0.0) * (quantity is num ? quantity : 1);
            if (!productSales.containsKey(name)) {
              productSales[name] = {'name': name, 'sales': 0, 'amount': 0.0};
            }
            productSales[name]!['sales'] += (quantity is num ? quantity : 1);
            productSales[name]!['amount'] += amount;
          }
        }
        // العملاء
        String userName = '';
        if (order['userId'] != null) {
          userName = await getUserName(order['userId']);
          missingUserIds.add(order['userId']);
        }
        if (userName.isEmpty) userName = 'مستخدم';
        if (!userSales.containsKey(userName)) {
          userSales[userName] = {'name': userName, 'spent': 0.0, 'orders': 0};
        }
        userSales[userName]!['spent'] += total;
        userSales[userName]!['orders'] += 1;
      }
      // جلب أسماء المنتجات المفقودة (احتياطي)
      for (final pid in missingProductIds) {
        final realName = await getProductName(pid);
        if (productSales.containsKey(pid)) {
          productSales[realName] = productSales[pid]!;
          productSales[realName]!['name'] = realName;
          productSales.remove(pid);
        }
      }
      // جلب أسماء المستخدمين المفقودة (احتياطي)
      for (final uid in missingUserIds) {
        final realName = await getUserName(uid);
        if (userSales.containsKey(uid)) {
          userSales[realName] = userSales[uid]!;
          userSales[realName]!['name'] = realName;
          userSales.remove(uid);
        }
      }
      topProducts = productSales.values.toList();
      topProducts.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
      if (topProducts.length > 5) topProducts = topProducts.sublist(0, 5);
      topUsers = userSales.values.toList();
      topUsers.sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));
      if (topUsers.length > 5) topUsers = topUsers.sublist(0, 5);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل التقرير: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقارير المبيعات'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            fromDate == null
                                ? 'من'
                                : '${fromDate!.year}/${fromDate!.month.toString().padLeft(2, '0')}/${fromDate!.day.toString().padLeft(2, '0')}',
                          ),
                          onPressed: () => pickDate(isFrom: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            toDate == null
                                ? 'إلى'
                                : '${toDate!.year}/${toDate!.month.toString().padLeft(2, '0')}/${toDate!.day.toString().padLeft(2, '0')}',
                          ),
                          onPressed: () => pickDate(isFrom: false),
                        ),
                      ),
                      if (fromDate != null || toDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () async {
                            setState(() {
                              fromDate = null;
                              toDate = null;
                            });
                            await loadReport();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'إجمالي المبيعات',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ج.م $totalSales',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'عدد الطلبات',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$totalOrders',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'المنتجات الأكثر مبيعاً',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  (topProducts.isEmpty)
                      ? Text('لا توجد بيانات في الفترة المختارة', style: TextStyle(color: Colors.grey))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topProducts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = topProducts[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange[50],
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  p['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('عدد المبيعات: ${p['sales']}'),
                                trailing: Text(
                                  'ج.م ${p['amount']}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),
                  Text(
                    'أهم العملاء',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  (topUsers.isEmpty)
                      ? Text('لا توجد بيانات في الفترة المختارة', style: TextStyle(color: Colors.grey))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topUsers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final u = topUsers[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[50],
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  u['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('عدد الطلبات: ${u['orders']}'),
                                trailing: Text(
                                  'ج.م ${u['spent']}',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
