import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Basic product methods
  Future<List<ProductModel>> getProducts({int limit = 20}) async {
    final querySnapshot = await _firestore
        .collection('products')
        .where('is_visible', isEqualTo: true)
        .limit(limit)
        .get();
    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ProductModel.fromJson(data);
        })
        .toList();
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }
    return null;
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection('products').doc(product.id).set(product.toJson());
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

  // Category-based product methods
  Future<List<ProductModel>> getProductsForCategory(String categoryId, {int limit = 20}) async {
    final querySnapshot = await _firestore
        .collection('products')
        .where('category_id', isEqualTo: categoryId)
        .where('is_visible', isEqualTo: true)
        .limit(limit)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }).toList();
  }

  Future<List<ProductModel>> getAllProductsForCategory(String categoryId, {int limit = 20}) async {
    final querySnapshot = await _firestore
        .collection('products')
        .where('category_id', isEqualTo: categoryId)
        .limit(limit)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }).toList();
  }

  Future<List<ProductModel>> getProductsForCategoryPaginated({
    required String categoryId,
    int limit = 20,
    ProductModel? lastProduct,
  }) async {
    var query = _firestore
        .collection('products')
        .where('category_id', isEqualTo: categoryId)
        .where('is_visible', isEqualTo: true)
        .orderBy('created_at')
        .limit(limit);
    
    if (lastProduct != null) {
      query = query.startAfter([lastProduct.createdAt.toIso8601String()]);
    }
    
    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }).toList();
  }

  Future<List<ProductModel>> getAllProductsForCategoryPaginated({
    required String categoryId,
    int limit = 20,
    ProductModel? lastProduct,
  }) async {
    var query = _firestore
        .collection('products')
        .where('category_id', isEqualTo: categoryId)
        .orderBy('created_at')
        .limit(limit);
    
    if (lastProduct != null) {
      query = query.startAfter([lastProduct.createdAt.toIso8601String()]);
    }
    
    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }).toList();
  }

  // Product count methods
  Future<int> getProductCountForCategory(String categoryId) async {
    final querySnapshot = await _firestore
        .collection('products')
        .where('category_id', isEqualTo: categoryId)
        .where('is_visible', isEqualTo: true)
        .get();
    return querySnapshot.size;
  }

  Future<int> getAllProductCountForCategory(String categoryId) async {
    final querySnapshot = await _firestore
        .collection('products')
        .where('category_id', isEqualTo: categoryId)
        .get();
    return querySnapshot.size;
  }

  // Pagination methods
  Future<List<ProductModel>> getProductsPaginated({int limit = 20, ProductModel? lastProduct}) async {
    var query = _firestore
        .collection('products')
        .where('is_visible', isEqualTo: true)
        .orderBy('created_at')
        .limit(limit);
    if (lastProduct != null) {
      query = query.startAfter([lastProduct.createdAt.toIso8601String()]);
    }
    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ProductModel.fromJson(data);
    }).toList();
  }

  // Home screen product methods
  Future<List<ProductModel>> getBestSellers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('is_best_seller', isEqualTo: true)
          .where('is_visible', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting best sellers: $e');
      try {
        final querySnapshot = await _firestore
            .collection('products')
            .where('is_visible', isEqualTo: true)
            .orderBy('created_at', descending: true)
            .limit(limit)
            .get();
        
        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ProductModel.fromJson(data);
        }).toList();
      } catch (e2) {
        print('Error getting products without filters: $e2');
        return [];
      }
    }
  }

  Future<List<ProductModel>> getSpecialOffers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('original_price', isGreaterThan: 0)
          .where('is_visible', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      print('🔍 Special Offers Query: Found ${querySnapshot.docs.length} products with original_price > 0');
      
      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
      
      for (var product in products) {
        print('📦 Product: ${product.name} | Price: ${product.price} | Original: ${product.originalPrice} | Has Discount: ${product.hasDiscount}');
      }
      
      final specialOffers = products.where((product) {
        return product.originalPrice != null && 
               product.originalPrice! > 0 &&
               product.price < product.originalPrice!;
      }).toList();
      
      print('🎯 Special Offers After Filter: ${specialOffers.length} products with real discount');
      
      return specialOffers;
    } catch (e) {
      print('Error getting special offers: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getRecommendedProducts({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('is_visible', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting recommended products: $e');
      return [];
    }
  }
} 