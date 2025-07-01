import 'package:flutter/material.dart';
import 'package:fodamarket/theme/appcolors.dart';
import 'package:fodamarket/views/profile/order_details_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {
        'number': '123456',
        'date': '2024-06-01',
        'status': 'تم التوصيل',
        'total': '250 ج.م',
      },
      {
        'number': '123457',
        'date': '2024-05-28',
        'status': 'قيد التنفيذ',
        'total': '180 ج.م',
      },
      {
        'number': '123458',
        'date': '2024-05-20',
        'status': 'ملغي',
        'total': '90 ج.م',
      },
    ];
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
                // AppBar style title bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'الطلبات',
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
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      Color statusColor;
                      if (order['status'] == 'تم التوصيل') {
                        statusColor = Colors.green;
                      } else if (order['status'] == 'قيد التنفيذ') {
                        statusColor = AppColors.orangeColor;
                      } else {
                        statusColor = Colors.red;
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(
                                orderNumber: order['number']!,
                                date: order['date']!,
                                status: order['status']!,
                                total: order['total']!,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.symmetric(horizontal: 0),
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
                                  Text(
                                    'طلب رقم: ${order['number']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      order['status']!,
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
                                  Text(
                                    order['date']!,
                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                  ),
                                  const Spacer(),
                                  Text(
                                    order['total']!,
                                    style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 