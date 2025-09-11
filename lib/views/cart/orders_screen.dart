// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fouda_market/models/order_model.dart';
// import 'package:fouda_market/core/services/order_service.dart';
// import 'package:fouda_market/theme/appcolors.dart';
// import 'package:fouda_market/views/cart/order_details_screen.dart';
//
// class OrdersScreen extends StatefulWidget {
//   const OrdersScreen({super.key});
//
//   @override
//   State<OrdersScreen> createState() => _OrdersScreenState();
// }
//
// class _OrdersScreenState extends State<OrdersScreen> {
//   List<OrderModel> _orders = [];
//   bool _isLoading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadOrders();
//   }
//
//   Future<void> _loadOrders() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });
//
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) {
//         throw Exception('يرجى تسجيل الدخول');
//       }
//
//       final orders = await OrderService().getUserOrders(currentUser.uid);
//
//       if (mounted) {
//         setState(() {
//           _orders = orders;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _error = e.toString();
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('طلباتي'),
//           backgroundColor: AppColors.orangeColor,
//           foregroundColor: Colors.white,
//           actions: [
//             IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
//           ],
//         ),
//         body: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _error != null
//             ? _buildErrorState()
//             : _orders.isEmpty
//             ? _buildEmptyState()
//             : _buildOrdersList(),
//       ),
//     );
//   }
//
//   Widget _buildErrorState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
//           const SizedBox(height: 16),
//           Text(
//             'حدث خطأ في تحميل الطلبات',
//             style: TextStyle(fontSize: 18, color: Colors.red[600]),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _error ?? 'خطأ غير معروف',
//             style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadOrders,
//             child: const Text('إعادة المحاولة'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'لا توجد طلبات',
//             style: TextStyle(fontSize: 18, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'لم تقم بأي طلب بعد',
//             style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrdersList() {
//     return RefreshIndicator(
//       onRefresh: _loadOrders,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: _orders.length,
//         itemBuilder: (context, index) {
//           final order = _orders[index];
//           return _buildOrderCard(order);
//         },
//       ),
//     );
//   }
//
//   Widget _buildOrderCard(OrderModel order) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: () => _navigateToOrderDetails(order.id),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // رأس البطاقة
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'طلب رقم ${order.id}',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           _formatDate(order.createdAt),
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   _buildStatusChip(order.status),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // معلومات الطلب
//               Row(
//                 children: [
//                   Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${order.items.length} منتج',
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                   ),
//                   const Spacer(),
//                   if (order.promoCode != null) ...[
//                     Icon(Icons.discount, size: 16, color: Colors.green[600]),
//                     const SizedBox(width: 4),
//                     Text(
//                       'كود خصم: ${order.promoCode}',
//                       style: TextStyle(fontSize: 12, color: Colors.green[600]),
//                     ),
//                     const SizedBox(width: 8),
//                   ],
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // السعر
//               Row(
//                 children: [
//                   Text(
//                     'الإجمالي:',
//                     style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                   ),
//                   const Spacer(),
//                   Text(
//                     '${order.total.toStringAsFixed(2)} جنيه',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.orangeColor,
//                     ),
//                   ),
//                 ],
//               ),
//
//               // زر عرض التفاصيل
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 height: 36,
//                 child: OutlinedButton(
//                   onPressed: () => _navigateToOrderDetails(order.id),
//                   style: OutlinedButton.styleFrom(
//                     side: BorderSide(color: AppColors.orangeColor),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'عرض التفاصيل',
//                     style: TextStyle(color: AppColors.orangeColor),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusChip(String status) {
//     final statusColors = {
//       'pending': Colors.orange,
//       'accepted': Colors.blue,
//       'preparing': Colors.purple,
//       'delivering': Colors.indigo,
//       'delivered': Colors.green,
//       'cancelled': Colors.red,
//       'failed': Colors.red,
//     };
//
//     final statusTexts = {
//       'pending': 'في الانتظار',
//       'accepted': 'تم القبول',
//       'preparing': 'جاري التحضير',
//       'delivering': 'جاري التوصيل',
//       'delivered': 'تم التوصيل',
//       'cancelled': 'ملغي',
//       'failed': 'فشل',
//     };
//
//     final color = statusColors[status] ?? Colors.grey;
//     final text = statusTexts[status] ?? status;
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: 12,
//           color: color,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
//
//   void _navigateToOrderDetails(String orderId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OrderDetailsScreen(orderId: orderId),
//       ),
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
//   }
// }
