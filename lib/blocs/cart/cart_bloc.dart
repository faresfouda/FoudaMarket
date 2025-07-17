import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../services/firebase_service.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final FirebaseService _firebaseService = FirebaseService();

  CartBloc() : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItem>(_onUpdateCartItem);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<RefreshCart>(_onRefreshCart);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    try {
      print('🔄 [CART_BLOC] Loading cart for user: ${event.userId}');
      emit(CartLoading());
      
      final cartItems = await _firebaseService.getCartItems(event.userId);
      final total = await _firebaseService.getCartTotal(event.userId);
      final itemsCount = await _firebaseService.getCartItemsCount(event.userId);

      print('📊 [CART_BLOC] Cart loaded - Items: ${cartItems.length}, Total: $total, Count: $itemsCount');

      if (cartItems.isEmpty) {
        print('📭 [CART_BLOC] Cart is empty');
        emit(CartEmpty());
      } else {
        print('✅ [CART_BLOC] Cart loaded successfully');
        emit(CartLoaded(
          cartItems: cartItems,
          total: total,
          itemsCount: itemsCount,
        ));
      }
    } catch (e) {
      print('❌ [CART_BLOC] Error loading cart: $e');
      emit(CartError('فشل في تحميل سلة التسوق: $e'));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      print('➕ [CART_BLOC] Adding to cart: ${event.cartItem.productName}');
      emit(CartActionLoading());
      
      await _firebaseService.addToCart(event.cartItem);
      
      print('✅ [CART_BLOC] Product added to cart successfully');
      emit(CartActionSuccess('تم إضافة المنتج إلى السلة بنجاح'));
      
      // إعادة تحميل السلة
      print('🔄 [CART_BLOC] Reloading cart after adding item');
      final cartItems = await _firebaseService.getCartItems(event.cartItem.userId);
      final total = await _firebaseService.getCartTotal(event.cartItem.userId);
      final itemsCount = await _firebaseService.getCartItemsCount(event.cartItem.userId);

      print('📊 [CART_BLOC] Cart reloaded - Items: ${cartItems.length}, Total: $total');
      emit(CartLoaded(
        cartItems: cartItems,
        total: total,
        itemsCount: itemsCount,
      ));
    } catch (e) {
      print('❌ [CART_BLOC] Error adding to cart: $e');
      emit(CartActionError('فشل في إضافة المنتج إلى السلة: $e'));
    }
  }

  Future<void> _onUpdateCartItem(UpdateCartItem event, Emitter<CartState> emit) async {
    try {
      print('📝 [CART_BLOC] Updating cart item: ${event.cartItemId} with quantity: ${event.quantity}');
      
      // تحديث الحالة المحلية فوراً للاستجابة السريعة
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.id == event.cartItemId) {
            return item.copyWith(quantity: event.quantity);
          }
          return item;
        }).toList();
        
        // حساب الإجمالي الجديد
        final newTotal = updatedItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
        
        // إصدار الحالة المحدثة فوراً
        emit(CartLoaded(
          cartItems: updatedItems,
          total: newTotal,
          itemsCount: currentState.itemsCount,
        ));
      }
      
      // تحديث Firebase في الخلفية
      await _firebaseService.updateCartItem(event.cartItemId, {
        'quantity': event.quantity,
      });
      
      print('✅ [CART_BLOC] Cart item updated successfully');
      
      // إعادة تحميل السلة للتأكد من التزامن
      print('🔄 [CART_BLOC] Syncing cart after update');
      final cartItems = await _firebaseService.getCartItems(event.userId);
      final total = await _firebaseService.getCartTotal(event.userId);
      final itemsCount = await _firebaseService.getCartItemsCount(event.userId);

      print('📊 [CART_BLOC] Cart synced after update - Items: ${cartItems.length}, Total: $total');

      if (cartItems.isEmpty) {
        print('📭 [CART_BLOC] Cart is now empty after update');
        emit(CartEmpty());
      } else {
        print('✅ [CART_BLOC] Cart synced successfully after update');
        emit(CartLoaded(
          cartItems: cartItems,
          total: total,
          itemsCount: itemsCount,
        ));
      }
    } catch (e) {
      print('❌ [CART_BLOC] Error updating cart item: $e');
      emit(CartActionError('فشل في تحديث الكمية: $e'));
    }
  }

  Future<void> _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) async {
    try {
      print('🗑️ [CART_BLOC] Removing cart item: ${event.cartItemId}');
      
      // تحديث الحالة المحلية فوراً للاستجابة السريعة
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.where((item) => item.id != event.cartItemId).toList();
        
        if (updatedItems.isEmpty) {
          // إذا أصبحت السلة فارغة، إصدار الحالة فوراً
          emit(CartEmpty());
        } else {
          // حساب الإجمالي الجديد
          final newTotal = updatedItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
          
          // إصدار الحالة المحدثة فوراً
          emit(CartLoaded(
            cartItems: updatedItems,
            total: newTotal,
            itemsCount: currentState.itemsCount - 1,
          ));
        }
      }
      
      // حذف من Firebase في الخلفية
      await _firebaseService.removeFromCart(event.cartItemId);
      
      print('✅ [CART_BLOC] Product removed from cart successfully');
      
      // إعادة تحميل السلة للتأكد من التزامن
      print('🔄 [CART_BLOC] Syncing cart after removal');
      final cartItems = await _firebaseService.getCartItems(event.userId);
      final total = await _firebaseService.getCartTotal(event.userId);
      final itemsCount = await _firebaseService.getCartItemsCount(event.userId);

      print('📊 [CART_BLOC] Cart synced after removal - Items: ${cartItems.length}, Total: $total');

      if (cartItems.isEmpty) {
        print('📭 [CART_BLOC] Cart is now empty after removal');
        emit(CartEmpty());
      } else {
        print('✅ [CART_BLOC] Cart synced successfully after removal');
        emit(CartLoaded(
          cartItems: cartItems,
          total: total,
          itemsCount: itemsCount,
        ));
      }
    } catch (e) {
      print('❌ [CART_BLOC] Error removing from cart: $e');
      emit(CartActionError('فشل في إزالة المنتج من السلة: $e'));
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      emit(CartActionLoading());
      
      await _firebaseService.clearCart(event.userId);
      
      emit(CartActionSuccess('تم تفريغ السلة بنجاح'));
      emit(CartEmpty());
    } catch (e) {
      emit(CartActionError('فشل في تفريغ السلة: $e'));
    }
  }

  Future<void> _onRefreshCart(RefreshCart event, Emitter<CartState> emit) async {
    try {
      final cartItems = await _firebaseService.getCartItems(event.userId);
      final total = await _firebaseService.getCartTotal(event.userId);
      final itemsCount = await _firebaseService.getCartItemsCount(event.userId);

      if (cartItems.isEmpty) {
        emit(CartEmpty());
      } else {
        emit(CartLoaded(
          cartItems: cartItems,
          total: total,
          itemsCount: itemsCount,
        ));
      }
    } catch (e) {
      emit(CartError('فشل في تحديث سلة التسوق: $e'));
    }
  }
} 