import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderNumber;
  final String date;
  final String status;
  final String total;
  const OrderDetailsScreen({super.key, required this.orderNumber, required this.date, required this.status, required this.total});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'بيض بلدي', 'qty': '2', 'price': '40 ج.م'},
      {'name': 'مكرونة', 'qty': '1', 'price': '20 ج.م'},
      {'name': 'زيت', 'qty': '1', 'price': '60 ج.م'},
    ];
    Color statusColor;
    if (status == 'تم التوصيل') {
      statusColor = Colors.green;
    } else if (status == 'قيد التنفيذ') {
      statusColor = AppColors.orangeColor;
    } else {
      statusColor = Colors.red;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          Image.asset(
            'assets/home/backgroundblur.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'تفاصيل الطلب',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(32),
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
                          Text('طلب رقم: $orderNumber', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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
                          Text(date, style: const TextStyle(fontSize: 16, color: Colors.black)),
                          const Spacer(),
                          const Icon(Icons.attach_money, color: Colors.black, size: 22),
                          const SizedBox(width: 8),
                          Text(total, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('المنتجات:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 12),
                      ...products.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag, color: Colors.black, size: 22),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p['name']!, style: const TextStyle(fontSize: 16, color: Colors.black))),
                            Text('x${p['qty']}', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                            const SizedBox(width: 12),
                            Text(p['price']!, style: const TextStyle(fontSize: 16, color: Colors.black)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 