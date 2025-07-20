import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/views/cart/widgets/cart_product_widget.dart';
import 'package:fouda_market/blocs/cart/index.dart';
import 'package:fouda_market/blocs/address/address_bloc.dart';
import 'package:fouda_market/blocs/address/address_event.dart';
import 'package:fouda_market/blocs/address/address_state.dart';
import 'package:fouda_market/models/address_model.dart';
import 'package:fouda_market/models/order_model.dart';
import 'package:fouda_market/core/services/order_service.dart';
import 'package:fouda_market/views/cart/order_accepted_screen.dart';
import '../../routes.dart';
import 'package:fouda_market/components/loading_indicator.dart';
import 'package:fouda_market/components/error_view.dart';


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with RouteAware {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // إعادة تحميل العنوان الافتراضي عند العودة من شاشة العناوين
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
    }
  }

  void _loadCart() {
    final user = FirebaseAuth.instance.currentUser;
    print('🔍 [CART_SCREEN] Current user: $user');
    if (user != null) {
      currentUserId = user.uid;
      print('🔍 [CART_SCREEN] User ID: ${user.uid}');
      print('🔍 [CART_SCREEN] Loading cart for user: ${user.uid}');
      context.read<CartBloc>().add(LoadCart(user.uid));
      // تحميل العنوان الافتراضي
      context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
    } else {
      print('❌ [CART_SCREEN] No user logged in');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عربة التسوق'),
        centerTitle: true,
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.cartItems.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearCartDialog(context),
                  tooltip: 'تفريغ السلة',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CartActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CartLoading) {
            return const LoadingIndicator();
          } else if (state is CartEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'عربة التسوق فارغة',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أضف منتجات إلى عربة التسوق',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else if (state is CartLoaded) {
            return Column(
              children: [
                // عرض العنوان الافتراضي
                _buildDeliveryAddressSection(),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = state.cartItems[index];
                      return CartProductWidget(
                        key: ValueKey(cartItem.id), // إضافة key فريد لكل widget
                        cartItem: cartItem,
                        onQuantityChanged: (quantity) {
                          context.read<CartBloc>().add(
                            UpdateCartItem(cartItem.id, quantity, currentUserId!),
                          );
                        },
                        onRemove: () {
                          context.read<CartBloc>().add(
                            RemoveFromCart(cartItem.id, currentUserId!),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildBottomBar(state.total),
              ],
            );
          }
          return const LoadingIndicator();
        },
      ),
    );
  }



  Widget _buildDeliveryAddressSection() {
    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, state) {
        if (state is DefaultAddressLoaded && state.defaultAddress != null) {
          final address = state.defaultAddress!;
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.orangeColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عنوان التوصيل',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        address.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.orangeColor, size: 20),
                  onPressed: () async {
                    // الانتقال لشاشة العناوين
                    final result = await Navigator.pushNamed(context, '/delivery-address');
                    // بعد العودة من شاشة العناوين، أعد تحميل العنوان الافتراضي دائماً
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && mounted) {
                      context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
                    }
                  },
                ),
              ],
            ),
          );
        } else {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.orangeColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'أضف عنوان التوصيل لإكمال الطلب',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.orangeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: AppColors.orangeColor, size: 20),
                  onPressed: () async {
                    // الانتقال لشاشة العناوين
                    final result = await Navigator.pushNamed(context, '/delivery-address');
                    // بعد العودة من شاشة العناوين، أعد تحميل العنوان الافتراضي دائماً
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && mounted) {
                      context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
                    }
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildBottomBar(double total) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(12.0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.orangeColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToCheckout(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_checkout,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'إتمام الطلب - ${total.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCheckout() {
    Navigator.pushNamed(context, '/checkout');
  }

  Future<void> _createOrder(AddressModel defaultAddress, double finalTotal) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingIndicator(),
      );

      // جلب بيانات السلة
      final cartState = context.read<CartBloc>().state;
      if (cartState is! CartLoaded || cartState.cartItems.isEmpty) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('السلة فارغة'), backgroundColor: Colors.red),
        );
        return;
      }

      // إنشاء عناصر الطلب
      final orderItems = cartState.cartItems.map((cartItem) => OrderItemModel(
        productId: cartItem.productId,
        productName: cartItem.productName,
        productImage: cartItem.productImage,
        price: cartItem.price,
        quantity: cartItem.quantity,
        total: cartItem.total,
      )).toList();

      // إنشاء الطلب
      final order = OrderModel(
        id: '', // سيتم إنشاؤه تلقائياً
        userId: currentUserId!,
        items: orderItems,
        subtotal: cartState.total,
        total: finalTotal,
        status: 'pending',
        deliveryAddress: defaultAddress.address,
        deliveryAddressName: defaultAddress.name,
        deliveryPhone: defaultAddress.phone,
        deliveryNotes: null,
        estimatedDeliveryTime: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ الطلب في قاعدة البيانات
      final orderService = OrderService();
      await orderService.createOrder(order);

      // تفريغ السلة
      context.read<CartBloc>().add(ClearCart(currentUserId!));

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      // الانتقال لشاشة نجاح الطلب
      Navigator.pushReplacementNamed(context, AppRoutes.orders + '/accepted');

    } catch (e) {
      // إغلاق مؤشر التحميل
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إنشاء الطلب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تفريغ السلة'),
          content: const Text('هل أنت متأكد من رغبتك في تفريغ سلة التسوق؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (currentUserId != null) {
                  context.read<CartBloc>().add(ClearCart(currentUserId!));
                }
              },
              child: const Text('تفريغ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
