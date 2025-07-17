import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search methods for admin (includes all products)
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThan: '${query.trim()}\uf8ff')
          .orderBy('name')
          .limit(50)
          .get();
      
      final products = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ProductModel.fromJson(data);
          })
          .toList();
      
      if (products.isEmpty) {
        final descQuerySnapshot = await _firestore
            .collection('products')
            .where('description', isGreaterThanOrEqualTo: query.trim())
            .where('description', isLessThan: '${query.trim()}\uf8ff')
            .orderBy('description')
            .limit(20)
            .get();
        
        final descProducts = descQuerySnapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductModel.fromJson(data);
            })
            .toList();
        
        return descProducts;
      }
      
      return products;
    } catch (e) {
      print('Error searching products: $e');
      try {
        final querySnapshot = await _firestore
            .collection('products')
            .get();
        
        final allProducts = querySnapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductModel.fromJson(data);
            })
            .toList();
        
        return allProducts.where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      } catch (e2) {
        print('Error in fallback search: $e2');
        return [];
      }
    }
  }

  // Search methods for users (only visible products)
  Future<List<ProductModel>> searchVisibleProducts(String query, {List<String>? categories, double? minPrice, double? maxPrice}) async {
    if (query.trim().isEmpty && (categories == null || categories.isEmpty) && minPrice == null && maxPrice == null) {
      return [];
    }
    try {
      Query collection = _firestore.collection('products').where('is_visible', isEqualTo: true);
      if (categories != null && categories.isNotEmpty) {
        if (categories.length == 1) {
          collection = collection.where('category_id', isEqualTo: categories.first);
        } else {
          collection = collection.where('category_id', whereIn: categories);
        }
      }
      if (minPrice != null) {
        collection = collection.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        collection = collection.where('price', isLessThanOrEqualTo: maxPrice);
      }
      if (query.trim().isNotEmpty) {
        collection = collection
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThan: '${query.trim()}\uf8ff')
          .orderBy('name');
      } else {
        collection = collection.orderBy('name');
      }
      final querySnapshot = await collection.limit(50).get();
      final products = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
      return products;
    } catch (e) {
      print('Error searching visible products with filters: $e');
      return [];
    }
  }

  // Search in category for admin (includes all products)
  Future<List<ProductModel>> searchProductsInCategory(String categoryId, String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category_id', isEqualTo: categoryId)
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThan: '${query.trim()}\uf8ff')
          .orderBy('name')
          .limit(30)
          .get();
      
      final products = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ProductModel.fromJson(data);
          })
          .toList();
      
      if (products.isEmpty) {
        final descQuerySnapshot = await _firestore
            .collection('products')
            .where('category_id', isEqualTo: categoryId)
            .where('description', isGreaterThanOrEqualTo: query.trim())
            .where('description', isLessThan: '${query.trim()}\uf8ff')
            .orderBy('description')
            .limit(15)
            .get();
        
        final descProducts = descQuerySnapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductModel.fromJson(data);
            })
            .toList();
        
        return descProducts;
      }
      
      return products;
    } catch (e) {
      print('Error searching products in category: $e');
      try {
        final allCategoryProducts = await _firestore
            .collection('products')
            .where('category_id', isEqualTo: categoryId)
            .get();
        
        final products = allCategoryProducts.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductModel.fromJson(data);
            })
            .toList();
        
        return products.where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      } catch (e2) {
        print('Error in fallback category search: $e2');
        return [];
      }
    }
  }

  // Search in category for users (only visible products)
  Future<List<ProductModel>> searchVisibleProductsInCategory(String categoryId, String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category_id', isEqualTo: categoryId)
          .where('is_visible', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThan: '${query.trim()}\uf8ff')
          .orderBy('name')
          .limit(30)
          .get();
      
      final products = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ProductModel.fromJson(data);
          })
          .toList();
      
      if (products.isEmpty) {
        final descQuerySnapshot = await _firestore
            .collection('products')
            .where('category_id', isEqualTo: categoryId)
            .where('is_visible', isEqualTo: true)
            .where('description', isGreaterThanOrEqualTo: query.trim())
            .where('description', isLessThan: '${query.trim()}\uf8ff')
            .orderBy('description')
            .limit(15)
            .get();
        
        final descProducts = descQuerySnapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductModel.fromJson(data);
            })
            .toList();
        
        return descProducts;
      }
      
      return products;
    } catch (e) {
      print('Error searching visible products in category: $e');
      try {
        final visibleCategoryProducts = await _firestore
            .collection('products')
            .where('category_id', isEqualTo: categoryId)
            .where('is_visible', isEqualTo: true)
            .get();
        
        final products = visibleCategoryProducts.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductModel.fromJson(data);
            })
            .toList();
        
        return products.where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      } catch (e2) {
        print('Error in fallback visible category search: $e2');
        return [];
      }
    }
  }
} 