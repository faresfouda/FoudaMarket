import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/cart/index.dart';
import '../../blocs/address/address_bloc.dart';
import '../../blocs/address/address_event.dart';
import '../../blocs/address/address_state.dart';
import '../../blocs/promo_code/index.dart';
import '../../models/address_model.dart';
import '../../models/promo_code_model.dart';
import '../../theme/appcolors.dart';
import 'order_accepted_screen.dart';
import '../../core/services/order_service.dart';
import '../../models/order_model.dart';
import '../../routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _promoCodeController = TextEditingController();
  PromoCodeModel? _appliedPromoCode;
  String? _appliedPromoCodeId;
  double _discountAmount = 0.0;
  bool _isApplyingPromoCode = false;
  String? _promoCodeError;
  bool _isPromoCodeValid = false;

  @override
  void initState() {
    super.initState();
    // تحميل العنوان الافتراضي
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
    }
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  void _onPromoCodeChanged(String value, CartLoaded cartState) async {
    final code = value.trim();
    if (code.isEmpty) {
      setState(() {
        _promoCodeError = null;
        _isPromoCodeValid = false;
      });
      return;
    }
    context.read<PromoCodeBloc>().add(ValidatePromoCode(code, cartState.total));
    await Future.delayed(const Duration(milliseconds: 400));
    final promoCodeState = context.read<PromoCodeBloc>().state;
    if (promoCodeState is PromoCodeValidated) {
      // إذا الكود غير مفعل اعتبره غير موجود للمستخدم
      if (promoCodeState.isValid &&
          promoCodeState.promoCode != null &&
          promoCodeState.promoCode!.isActive) {
        setState(() {
          _promoCodeError = null;
          _isPromoCodeValid = true;
        });
      } else if (promoCodeState.promoCode != null &&
          !promoCodeState.promoCode!.isActive) {
        setState(() {
          _promoCodeError = 'كود الخصم غير موجود';
          _isPromoCodeValid = false;
        });
      } else {
        setState(() {
          _promoCodeError = promoCodeState.message;
          _isPromoCodeValid = false;
        });
      }
    } else if (promoCodeState is PromoCodeError) {
      setState(() {
        _promoCodeError = promoCodeState.message;
        _isPromoCodeValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إتمام الطلب',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is CartEmpty) {
            return const Center(child: Text('السلة فارغة'));
          }

          if (cartState is CartLoaded) {
            return _buildCheckoutContent(cartState);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildCheckoutContent(CartLoaded cartState) {
    final subtotal = cartState.total;
    final finalTotal = subtotal - _discountAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان التوصيل
          _buildDeliveryAddressSection(),
          const SizedBox(height: 20),

          // كود الخصم
          _buildPromoCodeSection(cartState),
          const SizedBox(height: 20),

          // تفاصيل الطلب
          _buildOrderDetailsSection(cartState, subtotal, finalTotal),
          const SizedBox(height: 20),

          // زر إتمام الطلب
          _buildCheckoutButton(cartState, finalTotal),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, addressState) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.orangeColor),
                    const SizedBox(width: 8),
                    const Text(
                      'عنوان التوصيل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (addressState is DefaultAddressLoaded &&
                    addressState.defaultAddress != null) ...[
                  _buildAddressInfo(addressState.defaultAddress!),
                ] else if (addressState is AddressesLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else ...[
                  _buildNoAddressState(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressInfo(AddressModel address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                address.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                address.phone,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address.address,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لا يوجد عنوان توصيل محدد',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سيتم استخدام العنوان الافتراضي من ملفك الشخصي',
                  style: TextStyle(color: Colors.orange[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(CartLoaded cartState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.discount, color: AppColors.orangeColor),
                const SizedBox(width: 8),
                const Text(
                  'كود الخصم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_appliedPromoCode != null) ...[
              _buildAppliedPromoCode(),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    onChanged: (val) => _onPromoCodeChanged(val, cartState),
                    decoration: InputDecoration(
                      hintText: 'أدخل كود الخصم',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      errorText: _promoCodeError,
                      suffixIcon: _isPromoCodeValid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplyingPromoCode || !_isPromoCodeValid
                      ? null
                      : () => _applyPromoCode(cartState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: _isApplyingPromoCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'تطبيق',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppliedPromoCode() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كود مطبق: ${_appliedPromoCode!.code}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  'خصم ${_appliedPromoCode!.discountPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(color: Colors.green[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removePromoCode,
            icon: Icon(Icons.close, color: Colors.green[600]),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSummary() {
    if (_appliedPromoCode == null || !_isPromoCodeValid)
      return const SizedBox.shrink();
    final isFixed =
        _appliedPromoCode!.fixedAmount != null &&
        _appliedPromoCode!.fixedAmount! > 0;
    return Row(
      children: [
        Icon(Icons.discount, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          isFixed
              ? 'خصم ${_appliedPromoCode!.fixedAmount!.toStringAsFixed(2)} جنيه'
              : 'خصم ${_appliedPromoCode!.discountPercentage.toStringAsFixed(2)}%',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '-${_discountAmount.toStringAsFixed(2)} جنيه',
          style: TextStyle(color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsSection(
    CartLoaded cartState,
    double subtotal,
    double finalTotal,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: AppColors.orangeColor),
                const SizedBox(width: 8),
                const Text(
                  'تفاصيل الطلب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOrderItem('المجموع الفرعي', subtotal.toStringAsFixed(2)),
            if (_discountAmount > 0) ...[
              _buildOrderItem(
                'الخصم',
                '-${_discountAmount.toStringAsFixed(2)}',
              ),
            ],
            const Divider(),
            _buildOrderItem(
              'الإجمالي',
              finalTotal.toStringAsFixed(2),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[600],
            ),
          ),
          Text(
            '$value جنيه',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.orangeColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(CartLoaded cartState, double finalTotal) {
    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, addressState) {
        final hasDefaultAddress =
            addressState is DefaultAddressLoaded &&
            addressState.defaultAddress != null;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: hasDefaultAddress
                ? () => _createOrder(addressState.defaultAddress!, finalTotal)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasDefaultAddress
                  ? AppColors.orangeColor
                  : Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'إتمام الطلب - ${finalTotal.toStringAsFixed(2)} جنيه',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyPromoCode(CartLoaded cartState) async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _promoCodeError = 'يرجى إدخال كود الخصم';
      });
      return;
    }
    setState(() {
      _isApplyingPromoCode = true;
    });
    try {
      context.read<PromoCodeBloc>().add(
        ValidatePromoCode(code, cartState.total),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      final promoCodeState = context.read<PromoCodeBloc>().state;
      if (promoCodeState is PromoCodeValidated) {
        // إذا الكود غير مفعل اعتبره غير موجود للمستخدم
        if (promoCodeState.isValid &&
            promoCodeState.promoCode != null &&
            promoCodeState.promoCode!.isActive) {
          setState(() {
            _appliedPromoCode = promoCodeState.promoCode;
            _appliedPromoCodeId = promoCodeState.promoCode!.id;
            _discountAmount = promoCodeState.discountAmount ?? 0.0;
            _isApplyingPromoCode = false;
            _promoCodeError = null;
            _isPromoCodeValid = true;
          });
          _showSnackBar('تم تطبيق كود الخصم بنجاح');
        } else if (promoCodeState.promoCode != null &&
            !promoCodeState.promoCode!.isActive) {
          setState(() {
            _isApplyingPromoCode = false;
            _promoCodeError = 'كود الخصم غير موجود';
            _isPromoCodeValid = false;
          });
          _showSnackBar('كود الخصم غير موجود', isError: true);
        } else {
          setState(() {
            _isApplyingPromoCode = false;
            _promoCodeError = promoCodeState.message;
            _isPromoCodeValid = false;
          });
          _showSnackBar(promoCodeState.message, isError: true);
        }
      } else if (promoCodeState is PromoCodeError) {
        setState(() {
          _isApplyingPromoCode = false;
          _promoCodeError = promoCodeState.message;
          _isPromoCodeValid = false;
        });
        _showSnackBar(promoCodeState.message, isError: true);
      }
    } catch (e) {
      setState(() {
        _isApplyingPromoCode = false;
        _promoCodeError = 'حدث خطأ أثناء تطبيق كود الخصم';
        _isPromoCodeValid = false;
      });
      _showSnackBar('حدث خطأ أثناء تطبيق كود الخصم', isError: true);
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _appliedPromoCodeId = null;
      _discountAmount = 0.0;
      _promoCodeController.clear();
      _promoCodeError = null;
      _isPromoCodeValid = false;
    });
    _showSnackBar('تم إزالة كود الخصم');
  }

  Future<void> _createOrder(
    AddressModel defaultAddress,
    double finalTotal,
  ) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      _showSnackBar('يرجى تسجيل الدخول', isError: true);
      return;
    }
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded) {
      _showSnackBar('خطأ في تحميل السلة', isError: true);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      // جلب بيانات المستخدم الحقيقية من قاعدة البيانات
      String actualCustomerName = 'غير محدد';
      String actualCustomerPhone = defaultAddress.phone; // استخدام هاتف العنوان كاحتياطي
      
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          actualCustomerName = userData['name'] ?? 'غير محدد';
          actualCustomerPhone = userData['phone'] ?? defaultAddress.phone;
        }
      } catch (e) {
        print('خطأ في جلب بيانات المستخدم: $e');
        // في حالة الخطأ، استخدم بيانات العنوان كاحتياطي
        actualCustomerName = defaultAddress.name;
        actualCustomerPhone = defaultAddress.phone;
      }

      final orderItems = cartState.cartItems
          .map(
            (item) => OrderItemModel(
              productId: item.productId,
              productName: item.productName,
              productImage: item.productImage,
              price: item.price,
              quantity: item.quantity,
              total: item.total,
            ),
          )
          .toList();
      double discountAmount = 0.0;
      String? promoCodeId;
      String? promoCode;
      double? promoCodeDiscountPercentage;
      double? promoCodeMaxDiscount;
      if (_appliedPromoCode != null && _appliedPromoCodeId != null) {
        discountAmount = _discountAmount;
        promoCodeId = _appliedPromoCodeId;
        promoCode = _appliedPromoCode!.code;
        promoCodeDiscountPercentage = _appliedPromoCode!.discountPercentage;
        promoCodeMaxDiscount = _appliedPromoCode!.maxDiscountAmount;
      }
      final order = OrderModel(
        id: '',
        userId: currentUserId,
        items: orderItems,
        subtotal: cartState.total,
        discountAmount: discountAmount,
        total: finalTotal,
        status: 'pending',
        deliveryAddress: defaultAddress.address,
        deliveryAddressName: defaultAddress.name,
        deliveryPhone: defaultAddress.phone,
        deliveryNotes: null,
        estimatedDeliveryTime: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        promoCodeId: promoCodeId,
        promoCode: promoCode,
        promoCodeDiscountPercentage: promoCodeDiscountPercentage,
        promoCodeMaxDiscount: promoCodeMaxDiscount,
        customerName: actualCustomerName,    // ← استخدام الاسم الحقيقي
        customerPhone: actualCustomerPhone,  // ← استخدام الهاتف الحقيقي
      );
      final orderId = await OrderService().createOrder(order);
      print('[DEBUG] Order created with ID: $orderId');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<CartBloc>().add(ClearCart(user.uid));
      }
      if (mounted) {
        Navigator.pop(context);
      }
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-accepted/$orderId',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      print('[ERROR] Failed to create order: $e');
      _showSnackBar('حدث خطأ أثناء إنشاء الطلب: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
