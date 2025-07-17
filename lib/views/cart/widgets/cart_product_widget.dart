import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/models/cart_item_model.dart';
import 'package:fouda_market/components/cached_image.dart';
import 'package:fouda_market/blocs/cart/index.dart';
import 'dart:async';

class CartProductWidget extends StatefulWidget {
  final CartItemModel cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartProductWidget({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<CartProductWidget> createState() => _CartProductWidgetState();
}

class _CartProductWidgetState extends State<CartProductWidget> {
  late int _quantity;
  bool _isUpdating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _quantity = widget.cartItem.quantity;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CartProductWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تحديث الكمية إذا تغيرت
    if (oldWidget.cartItem.quantity != widget.cartItem.quantity) {
      _quantity = widget.cartItem.quantity;
    }
    // إعادة تعيين حالة التحديث إذا تغير المنتج
    if (oldWidget.cartItem.id != widget.cartItem.id) {
      _isUpdating = false;
      _debounceTimer?.cancel();
    }
  }

  void _debouncedUpdate(int newQuantity) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      widget.onQuantityChanged(newQuantity);
    });
  }

  void _incrementQuantity() {
    if (_isUpdating) return;
    
    setState(() {
      _quantity++;
      _isUpdating = true;
    });
    
    // تحديث فوري للواجهة مع debounce
    _debouncedUpdate(_quantity);
    
    // إعادة تعيين حالة التحديث بعد فترة قصيرة
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    });
  }

  void _decrementQuantity() {
    if (_isUpdating || _quantity <= 1) return;
    
    setState(() {
      _quantity--;
      _isUpdating = true;
    });
    
    // تحديث فوري للواجهة مع debounce
    _debouncedUpdate(_quantity);
    
    // إعادة تعيين حالة التحديث بعد فترة قصيرة
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    });
  }

  Widget _buildQuantityRow({required bool isLoading}) {
    return Row(
      children: [
        // + button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (_isUpdating || isLoading) 
                ? Colors.grey[300] 
                : AppColors.orangeColor,
            shape: BoxShape.circle,
            boxShadow: (_isUpdating || isLoading) ? null : [
              BoxShadow(
                color: AppColors.orangeColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: (_isUpdating || isLoading) ? null : _incrementQuantity,
              child: Icon(
                Icons.add, 
                color: (_isUpdating || isLoading) 
                    ? Colors.grey[600] 
                    : Colors.white, 
                size: 22
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Quantity
        Container(
          width: 50,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              '$_quantity',
              key: ValueKey(_quantity),
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // - button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (_isUpdating || isLoading || _quantity <= 1) 
                ? Colors.grey[300] 
                : AppColors.orangeColor,
            shape: BoxShape.circle,
            boxShadow: (_isUpdating || isLoading || _quantity <= 1) ? null : [
              BoxShadow(
                color: AppColors.orangeColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: (_isUpdating || isLoading || _quantity <= 1) 
                  ? null 
                  : _decrementQuantity,
              child: Icon(
                Icons.remove, 
                color: (_isUpdating || isLoading || _quantity <= 1) 
                    ? Colors.grey[600] 
                    : Colors.white, 
                size: 22
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${widget.cartItem.price.toStringAsFixed(0)} ج.م',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6F00), // Orange
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            'الإجمالي: ${(widget.cartItem.price * _quantity).toStringAsFixed(0)} ج.م',
            key: ValueKey(_quantity),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final isLoading = state is CartActionLoading;
        
        return Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CachedImage(
                      key: ValueKey('cart_image_${widget.cartItem.id}'), // إضافة key فريد للصورة
                      imageUrl: widget.cartItem.productImage ?? '',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                      errorWidget: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product info and price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cartItem.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.cartItem.unit,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 320;
                            return isNarrow
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildQuantityRow(isLoading: isLoading),
                                      const SizedBox(height: 8),
                                      _buildPriceColumn(),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Flexible(child: _buildQuantityRow(isLoading: isLoading)),
                                      const SizedBox(width: 8),
                                      _buildPriceColumn(),
                                    ],
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            // Remove button (top left)
            Positioned(
              top: 6,
              left: 6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (_isUpdating || isLoading) ? null : widget.onRemove,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (_isUpdating || isLoading) ? Colors.grey : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 