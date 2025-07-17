import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getUserFavorites(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs.map((doc) => doc.data()['productId'] as String).toList();
    } catch (e) {
      print('Error getting user favorites: $e');
      return [];
    }
  }

  Future<void> addToFavorites(String userId, String productId) async {
    try {
      // التحقق من عدم وجود المفضلة مسبقاً
      final existingQuery = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();
      
      if (existingQuery.docs.isEmpty) {
        await _firestore.collection('favorites').add({
          'userId': userId,
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    try {
      final favorites = await getUserFavorites(userId);
      if (favorites.isEmpty) return [];

      final products = <ProductModel>[];
      for (final productId in favorites) {
        final product = await _getProduct(productId);
        if (product != null && product.isVisible) {
          products.add(product);
        }
      }
      return products;
    } catch (e) {
      print('Error getting favorite products: $e');
      return [];
    }
  }

  Future<bool> isProductFavorite(String userId, String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if product is favorite: $e');
      return false;
    }
  }

  // Helper method to get product
  Future<ProductModel?> _getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }
    return null;
  }
} 