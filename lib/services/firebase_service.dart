import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/product_service.dart';
import '../core/services/category_service.dart';
import '../core/services/search_service.dart';
import '../core/services/favorites_service.dart';
import '../core/services/cart_service.dart';
import '../core/services/order_service.dart';
import '../models/cart_item_model.dart';
import 'dart:io';
import '../../core/services/cloudinary_service.dart';

/// Legacy FirebaseService class that acts as a wrapper for the new separate services
/// This maintains backward compatibility while using the new modular architecture
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Initialize separate services
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final SearchService _searchService = SearchService();
  final FavoritesService _favoritesService = FavoritesService();
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();

  // Authentication methods - delegate to AuthService
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    return await _authService.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: role,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _authService.signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _authService.getUserProfile(userId);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _authService.updateUserProfile(userId, data);
  }

  // Product methods - delegate to ProductService
  Future<List<ProductModel>> getProducts() async {
    return await _productService.getProducts();
  }

  Future<ProductModel?> getProduct(String productId) async {
    return await _productService.getProduct(productId);
  }

  Future<void> addProduct(ProductModel product) async {
    await _productService.addProduct(product);
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    await _productService.updateProduct(productId, data);
  }

  Future<void> deleteProduct(String productId) async {
    await _productService.deleteProduct(productId);
  }

  Future<List<ProductModel>> getProductsForCategory(String categoryId) async {
    return await _productService.getProductsForCategory(categoryId);
  }

  Future<List<ProductModel>> getAllProductsForCategory(
    String categoryId,
  ) async {
    return await _productService.getAllProductsForCategory(categoryId);
  }

  Future<List<ProductModel>> getProductsForCategoryPaginated({
    required String categoryId,
    int limit = 20,
    ProductModel? lastProduct,
  }) async {
    return await _productService.getProductsForCategoryPaginated(
      categoryId: categoryId,
      limit: limit,
      lastProduct: lastProduct,
    );
  }

  Future<List<ProductModel>> getAllProductsForCategoryPaginated({
    required String categoryId,
    int limit = 20,
    ProductModel? lastProduct,
  }) async {
    return await _productService.getAllProductsForCategoryPaginated(
      categoryId: categoryId,
      limit: limit,
      lastProduct: lastProduct,
    );
  }

  Future<int> getProductCountForCategory(String categoryId) async {
    return await _productService.getProductCountForCategory(categoryId);
  }

  Future<int> getAllProductCountForCategory(String categoryId) async {
    return await _productService.getAllProductCountForCategory(categoryId);
  }

  Future<List<ProductModel>> getProductsPaginated({
    int limit = 20,
    ProductModel? lastProduct,
  }) async {
    return await _productService.getProductsPaginated(
      limit: limit,
      lastProduct: lastProduct,
    );
  }

  Future<List<ProductModel>> getBestSellers({
    int limit = 10,
    ProductModel? lastProduct,
  }) async {
    return await _productService.getBestSellers(
      limit: limit,
      lastProduct: lastProduct,
    );
  }

  Future<List<ProductModel>> getSpecialOffers({
    int limit = 10,
    ProductModel? lastProduct,
  }) async {
    return await _productService.getSpecialOffers(
      limit: limit,
      lastProduct: lastProduct,
    );
  }

  Future<List<ProductModel>> getRecommendedProducts({int limit = 10}) async {
    return await _productService.getRecommendedProducts(limit: limit);
  }

  // Category methods - delegate to CategoryService
  Future<List<CategoryModel>> getCategories() async {
    return await _categoryService.getCategories();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _categoryService.addCategory(category);
  }

  Future<List<CategoryModel>> getCategoriesPaginated({
    int limit = 20,
    CategoryModel? lastCategory,
  }) async {
    return await _categoryService.getCategoriesPaginated(
      limit: limit,
      lastCategory: lastCategory,
    );
  }

  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    await _categoryService.updateCategory(categoryId, data);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoryService.deleteCategory(categoryId);
  }

  Future<List<CategoryModel>> getHomeCategories({int limit = 8}) async {
    return await _categoryService.getHomeCategories(limit: limit);
  }

  Future<String?> uploadCategoryImage(File imageFile) async {
    // يمكنك هنا استخدام نفس منطق رفع صورة المنتج أو CloudinaryService
    // مثال بسيط (تأكد من وجود CloudinaryService):
    return await CloudinaryService().uploadImage(imageFile.path);
  }

  // Search methods - delegate to SearchService
  Future<List<ProductModel>> searchProducts(String query) async {
    return await _searchService.searchProducts(query);
  }

  Future<List<ProductModel>> searchVisibleProducts(
    String query, {
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
  }) async {
    return await _searchService.searchVisibleProducts(
      query,
      categories: categories,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  Future<List<ProductModel>> searchProductsInCategory(
    String categoryId,
    String query,
  ) async {
    return await _searchService.searchProductsInCategory(categoryId, query);
  }

  Future<List<ProductModel>> searchVisibleProductsInCategory(
    String categoryId,
    String query,
  ) async {
    return await _searchService.searchVisibleProductsInCategory(
      categoryId,
      query,
    );
  }

  Future<List<CategoryModel>> searchCategories(String query) async {
    return await _categoryService.searchCategories(query);
  }

  Future<List<CategoryModel>> searchCategoriesPaginated({
    required String query,
    int limit = 10,
    CategoryModel? lastCategory,
  }) async {
    return await _categoryService.searchCategoriesPaginated(
      query: query,
      limit: limit,
      lastCategory: lastCategory,
    );
  }

  // Favorite methods - delegate to FavoritesService
  Future<List<String>> getUserFavorites(String userId) async {
    return await _favoritesService.getUserFavorites(userId);
  }

  Future<void> addToFavorites(String userId, String productId) async {
    await _favoritesService.addToFavorites(userId, productId);
  }

  Future<void> removeFromFavorites(String userId, String productId) async {
    await _favoritesService.removeFromFavorites(userId, productId);
  }

  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    return await _favoritesService.getFavoriteProducts(userId);
  }

  Future<bool> isProductFavorite(String userId, String productId) async {
    return await _favoritesService.isProductFavorite(userId, productId);
  }

  // Cart methods - delegate to CartService
  Future<List<CartItemModel>> getCartItems(String userId) async {
    return await _cartService.getCartItems(userId);
  }

  Future<void> addToCart(CartItemModel cartItem) async {
    await _cartService.addToCart(cartItem);
  }

  Future<void> updateCartItem(
    String cartItemId,
    Map<String, dynamic> data,
  ) async {
    await _cartService.updateCartItem(cartItemId, data);
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _cartService.removeFromCart(cartItemId);
  }

  Future<void> clearCart(String userId) async {
    await _cartService.clearCart(userId);
  }

  Future<int> getCartItemsCount(String userId) async {
    return await _cartService.getCartItemsCount(userId);
  }

  Future<double> getCartTotal(String userId) async {
    return await _cartService.getCartTotal(userId);
  }

  // Order methods - delegate to OrderService
  Future<void> createOrder(OrderModel order) async {
    await _orderService.createOrder(order);
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    return await _orderService.getUserOrders(userId);
  }

  Future<List<OrderModel>> getAllOrders() async {
    return await _orderService.getAllOrders();
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    required String adminId,
    String? adminName,
  }) async {
    await _orderService.updateOrderStatus(
      orderId,
      status,
      adminId: adminId,
      adminName: adminName,
    );
  }

  Future<Map<String, dynamic>> getSalesReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _orderService.getSalesReport(startDate, endDate);
  }
}
