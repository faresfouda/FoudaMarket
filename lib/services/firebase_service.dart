import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;

  // Authentication methods
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'id': credential.user!.uid,
            'email': email,
            'name': name,
            'phone': phone,
            'role': role, // Use the provided role
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          await credential.user!.updateDisplayName(name);
        } catch (firestoreError) {
          // If Firestore fails, still return the credential but log the error
          print('Firestore error during signup: $firestoreError');
          // You might want to delete the user if Firestore fails
          // await credential.user!.delete();
        }
      }

      return credential;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User profile methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Product methods
  Future<List<ProductModel>> getProducts() async {
    final querySnapshot = await _firestore.collection('products').get();
    return querySnapshot.docs
        .map((doc) => ProductModel.fromJson(doc.data()))
        .toList();
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    return doc.exists ? ProductModel.fromJson(doc.data()!) : null;
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection('products').add(product.toJson());
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _firestore.collection('products').doc(productId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // Category methods
  Future<List<CategoryModel>> getCategories() async {
    final querySnapshot = await _firestore.collection('categories').get();
    return querySnapshot.docs
        .map((doc) => CategoryModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _firestore.collection('categories').add(category.toJson());
  }

  // Cart methods
  Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    final querySnapshot = await _firestore
        .collection('cart_items')
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addToCart(Map<String, dynamic> cartItem) async {
    await _firestore.collection('cart_items').add(cartItem);
  }

  Future<void> updateCartItem(String cartItemId, Map<String, dynamic> data) async {
    await _firestore.collection('cart_items').doc(cartItemId).update(data);
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _firestore.collection('cart_items').doc(cartItemId).delete();
  }

  Future<void> clearCart(String userId) async {
    final querySnapshot = await _firestore
        .collection('cart_items')
        .where('userId', isEqualTo: userId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Order methods
  Future<void> createOrder(OrderModel order) async {
    await _firestore.collection('orders').add(order.toJson());
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    final querySnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => OrderModel.fromJson(doc.data()))
        .toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final querySnapshot = await _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => OrderModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Favorites methods
  Future<List<String>> getUserFavorites(String userId) async {
    final doc = await _firestore.collection('favorites').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('productIds')) {
      return List<String>.from(doc.data()!['productIds']);
    }
    return [];
  }

  Future<void> addToFavorites(String userId, String productId) async {
    await _firestore.collection('favorites').doc(userId).set({
      'productIds': FieldValue.arrayUnion([productId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFromFavorites(String userId, String productId) async {
    await _firestore.collection('favorites').doc(userId).update({
      'productIds': FieldValue.arrayRemove([productId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // // Storage methods
  // Future<String> uploadImage(File imageFile, String path) async {
  //   // final ref = _storage.ref().child(path);
  //   // final uploadTask = ref.putFile(imageFile);
  //   final snapshot = await uploadTask;
  //   return await snapshot.ref.getDownloadURL();
  // }
  //
  // Future<void> deleteImage(String imageUrl) async {
  //   // final ref = _storage.refFromURL(imageUrl);
  //   // await ref.delete();
  // }

  // Search methods
  Future<List<ProductModel>> searchProducts(String query) async {
    final querySnapshot = await _firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .get();
    
    return querySnapshot.docs
        .map((doc) => ProductModel.fromJson(doc.data()))
        .toList();
  }

  // Analytics and reporting
  Future<Map<String, dynamic>> getSalesReport(DateTime startDate, DateTime endDate) async {
    final querySnapshot = await _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .where('status', isEqualTo: 'completed')
        .get();

    double totalSales = 0;
    int totalOrders = querySnapshot.docs.length;

    for (var doc in querySnapshot.docs) {
      final orderData = doc.data();
      totalSales += (orderData['totalAmount'] ?? 0).toDouble();
    }

    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
    };
  }
} 