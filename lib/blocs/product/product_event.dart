import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';
import 'dart:io';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class SetCurrentCategory extends ProductEvent {
  final String categoryId;
  const SetCurrentCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class FetchProducts extends ProductEvent {
  final String categoryId;
  final int limit;
  final ProductModel? lastProduct;
  const FetchProducts(this.categoryId, {this.limit = 20, this.lastProduct});
  @override
  List<Object?> get props => [categoryId, limit, lastProduct];
}

class LoadMoreProducts extends ProductEvent {
  final String categoryId;
  final int limit;
  final ProductModel? lastProduct;
  const LoadMoreProducts(this.categoryId, {this.limit = 20, this.lastProduct});
  @override
  List<Object?> get props => [categoryId, limit, lastProduct];
}

class AddProduct extends ProductEvent {
  final ProductModel product;
  const AddProduct(this.product);
  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final ProductModel product;
  const UpdateProduct(this.product);
  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends ProductEvent {
  final String productId;
  const DeleteProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}

class AddProductWithImage extends ProductEvent {
  final ProductModel product;
  final File imageFile;
  const AddProductWithImage(this.product, this.imageFile);
  @override
  List<Object?> get props => [product, imageFile];
}

class UpdateProductWithImage extends ProductEvent {
  final ProductModel product;
  final File imageFile;
  const UpdateProductWithImage(this.product, this.imageFile);
  @override
  List<Object?> get props => [product, imageFile];
}

// Home screen events
class FetchBestSellers extends ProductEvent {
  final int limit;
  const FetchBestSellers({this.limit = 10});
  @override
  List<Object?> get props => [limit];
}

class FetchSpecialOffers extends ProductEvent {
  final int limit;
  const FetchSpecialOffers({this.limit = 10});
  @override
  List<Object?> get props => [limit];
}

class FetchRecommendedProducts extends ProductEvent {
  final int limit;
  const FetchRecommendedProducts({this.limit = 10});
  @override
  List<Object?> get props => [limit];
}

// Admin search events (includes all products)
class SearchProducts extends ProductEvent {
  final String query;
  const SearchProducts(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchProductsInCategory extends ProductEvent {
  final String categoryId;
  final String query;
  const SearchProductsInCategory(this.categoryId, this.query);
  @override
  List<Object?> get props => [categoryId, query];
}

class SearchAllProductsInCategory extends ProductEvent {
  final String categoryId;
  final String query;
  const SearchAllProductsInCategory(this.categoryId, this.query);
  @override
  List<Object?> get props => [categoryId, query];
}

// User search events (only visible products)
class SearchVisibleProducts extends ProductEvent {
  final String query;
  final List<String>? categories;
  final double? minPrice;
  final double? maxPrice;
  const SearchVisibleProducts(this.query, {this.categories, this.minPrice, this.maxPrice});
  @override
  List<Object?> get props => [query, categories, minPrice, maxPrice];
}

class SearchVisibleProductsInCategory extends ProductEvent {
  final String categoryId;
  final String query;
  const SearchVisibleProductsInCategory(this.categoryId, this.query);
  @override
  List<Object?> get props => [categoryId, query];
}

class FetchProductsByCategory extends ProductEvent {
  final String categoryId;
  final int limit;
  const FetchProductsByCategory({required this.categoryId, this.limit = 10});
  @override
  List<Object?> get props => [categoryId, limit];
}

// Favorite events
class LoadFavorites extends ProductEvent {
  final String userId;
  const LoadFavorites(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AddToFavorites extends ProductEvent {
  final String userId;
  final String productId;
  const AddToFavorites(this.userId, this.productId);
  @override
  List<Object?> get props => [userId, productId];
}

class RemoveFromFavorites extends ProductEvent {
  final String userId;
  final String productId;
  const RemoveFromFavorites(this.userId, this.productId);
  @override
  List<Object?> get props => [userId, productId];
}

class CheckFavoriteStatus extends ProductEvent {
  final String userId;
  final String productId;
  const CheckFavoriteStatus(this.userId, this.productId);
  @override
  List<Object?> get props => [userId, productId];
}

class FetchAllProductsForCategory extends ProductEvent {
  final String categoryId;
  final int limit;
  const FetchAllProductsForCategory(this.categoryId, {this.limit = 20});
  @override
  List<Object?> get props => [categoryId, limit];
}

class LoadMoreAllProducts extends ProductEvent {
  final String categoryId;
  final int limit;
  final ProductModel? lastProduct;
  const LoadMoreAllProducts(
    this.categoryId, {
    this.limit = 20,
    this.lastProduct,
  });
  @override
  List<Object?> get props => [categoryId, limit, lastProduct];
}

class ResetHomeProducts extends ProductEvent {
  const ResetHomeProducts();
}
