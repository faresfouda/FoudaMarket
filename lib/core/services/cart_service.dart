import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cart_item_model.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CartItemModel>> getCartItems(String userId) async {
    try {
      print('🔍 [DEBUG] Getting cart items for user: $userId');
      
      final querySnapshot = await _firestore
          .collection('carts')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CartItemModel.fromJson(data);
      }).toList();
      
      print('✅ [DEBUG] Found ${items.length} cart items for user: $userId');
      return items;
    } catch (e) {
      print('❌ [DEBUG] Error getting cart items: $e');
      return [];
    }
  }

  Future<void> addToCart(CartItemModel cartItem) async {
    try {
      print('🛒 [DEBUG] Adding to cart: ${cartItem.productName} (Qty: ${cartItem.quantity}, Unit: ${cartItem.unit}) for user: ${cartItem.userId}');
      
      // التحقق من وجود المنتج بنفس الوحدة في السلة مسبقاً
      final existingQuery = await _firestore
          .collection('carts')
          .where('user_id', isEqualTo: cartItem.userId)
          .where('product_id', isEqualTo: cartItem.productId)
          .where('unit', isEqualTo: cartItem.unit)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        // تحديث الكمية إذا كان المنتج بنفس الوحدة موجود مسبقاً
        final existingDoc = existingQuery.docs.first;
        final existingData = existingDoc.data();
        final newQuantity = (existingData['quantity'] ?? 0) + cartItem.quantity;
        print('📝 [DEBUG] Updating existing cart item with same unit. Old qty: ${existingData['quantity']}, New qty: $newQuantity');
        await existingDoc.reference.update({
          'quantity': newQuantity,
          'updated_at': FieldValue.serverTimestamp(),
        });
        print('✅ [DEBUG] Cart item updated successfully');
      } else {
        // إضافة منتج جديد بدون id
        print('➕ [DEBUG] Adding new cart item with unit: ${cartItem.unit}');
        final data = cartItem.toJson();
        data.remove('id');
        await _firestore.collection('carts').add(data);
        print('✅ [DEBUG] New cart item added successfully');
      }
    } catch (e) {
      print('❌ [DEBUG] Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateCartItem(String cartItemId, Map<String, dynamic> data) async {
    try {
      print('📝 [DEBUG] Updating cart item: $cartItemId with data: $data');
      await _firestore.collection('carts').doc(cartItemId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('✅ [DEBUG] Cart item updated successfully');
    } catch (e) {
      print('❌ [DEBUG] Error updating cart item: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      print('🗑️ [DEBUG] Removing cart item: $cartItemId');
      await _firestore.collection('carts').doc(cartItemId).delete();
      print('✅ [DEBUG] Cart item removed successfully');
    } catch (e) {
      print('❌ [DEBUG] Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      print('🧹 [DEBUG] Clearing cart for user: $userId');
      final querySnapshot = await _firestore
          .collection('carts')
          .where('user_id', isEqualTo: userId)
          .get();
      
      print('📊 [DEBUG] Found ${querySnapshot.docs.length} items to clear');
      
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ [DEBUG] Cart cleared successfully');
    } catch (e) {
      print('❌ [DEBUG] Error clearing cart: $e');
      rethrow;
    }
  }

  Future<int> getCartItemsCount(String userId) async {
    try {
      print('🔢 [DEBUG] Getting cart items count for user: $userId');
      final querySnapshot = await _firestore
          .collection('carts')
          .where('user_id', isEqualTo: userId)
          .get();
      
      num totalCount = 0;
      for (var doc in querySnapshot.docs) {
        totalCount += (doc.data()['quantity'] ?? 0);
      }
      print('📊 [DEBUG] Total cart items count: ${totalCount.toInt()}');
      return totalCount.toInt();
    } catch (e) {
      print('❌ [DEBUG] Error getting cart items count: $e');
      return 0;
    }
  }

  Future<double> getCartTotal(String userId) async {
    try {
      print('💰 [DEBUG] Getting cart total for user: $userId');
      final cartItems = await getCartItems(userId);
      double total = 0.0;
      for (var item in cartItems) {
        total += item.total;
      }
      print('💵 [DEBUG] Cart total: ${total.toStringAsFixed(2)} EGP');
      return total;
    } catch (e) {
      print('❌ [DEBUG] Error getting cart total: $e');
      return 0.0;
    }
  }
} 