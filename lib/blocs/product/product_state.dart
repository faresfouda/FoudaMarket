import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductState {}

class ProductsLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<ProductModel> products;
  final bool hasMore;
  const ProductsLoaded(this.products, {this.hasMore = true});
  @override
  List<Object?> get props => [products, hasMore];
}

class ProductsError extends ProductState {
  final String message;
  const ProductsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductsSearching extends ProductState {}

class ProductsSearchLoaded extends ProductState {
  final List<ProductModel> products;
  final String query;
  const ProductsSearchLoaded(this.products, this.query);
  @override
  List<Object?> get props => [products, query];
}

// Home screen states
class BestSellersLoaded extends ProductState {
  final List<ProductModel> products;
  const BestSellersLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class SpecialOffersLoaded extends ProductState {
  final List<ProductModel> products;
  const SpecialOffersLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class RecommendedProductsLoaded extends ProductState {
  final List<ProductModel> products;
  const RecommendedProductsLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

// Home screen combined state
class HomeProductsLoaded extends ProductState {
  final List<ProductModel> specialOffers;
  final List<ProductModel> bestSellers;
  final List<ProductModel> recommendedProducts;
  final bool isLoadingSpecialOffers;
  final bool isLoadingBestSellers;
  final bool isLoadingRecommended;

  const HomeProductsLoaded({
    this.specialOffers = const [],
    this.bestSellers = const [],
    this.recommendedProducts = const [],
    this.isLoadingSpecialOffers = false,
    this.isLoadingBestSellers = false,
    this.isLoadingRecommended = false,
  });

  @override
  List<Object?> get props => [
    specialOffers,
    bestSellers,
    recommendedProducts,
    isLoadingSpecialOffers,
    isLoadingBestSellers,
    isLoadingRecommended,
  ];

  HomeProductsLoaded copyWith({
    List<ProductModel>? specialOffers,
    List<ProductModel>? bestSellers,
    List<ProductModel>? recommendedProducts,
    bool? isLoadingSpecialOffers,
    bool? isLoadingBestSellers,
    bool? isLoadingRecommended,
  }) {
    return HomeProductsLoaded(
      specialOffers: specialOffers ?? this.specialOffers,
      bestSellers: bestSellers ?? this.bestSellers,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      isLoadingSpecialOffers:
          isLoadingSpecialOffers ?? this.isLoadingSpecialOffers,
      isLoadingBestSellers: isLoadingBestSellers ?? this.isLoadingBestSellers,
      isLoadingRecommended: isLoadingRecommended ?? this.isLoadingRecommended,
    );
  }
}

class CategoryProductsLoaded extends ProductState {
  final List<ProductModel> products;
  final String categoryId;
  const CategoryProductsLoaded(this.products, this.categoryId);
  @override
  List<Object?> get props => [products, categoryId];
}

// Favorite states
class FavoritesLoading extends ProductState {}

class FavoritesLoaded extends ProductState {
  final List<ProductModel> favorites;
  const FavoritesLoaded(this.favorites);
  @override
  List<Object?> get props => [favorites];
}

class FavoritesError extends ProductState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}

class FavoriteStatusLoaded extends ProductState {
  final String productId;
  final bool isFavorite;
  const FavoriteStatusLoaded(this.productId, this.isFavorite);
  @override
  List<Object?> get props => [productId, isFavorite];
}

// State for general favorites update
class FavoritesUpdated extends ProductState {
  final Set<String> favoriteProductIds;
  const FavoritesUpdated(this.favoriteProductIds);
  @override
  List<Object?> get props => [favoriteProductIds];
}

// Combined state that includes both products and favorites
class ProductsWithFavoritesLoaded extends ProductState {
  final List<ProductModel> products;
  final bool hasMore;
  final List<ProductModel> favorites;
  const ProductsWithFavoritesLoaded(
    this.products, {
    this.hasMore = true,
    this.favorites = const [],
  });
  @override
  List<Object?> get props => [products, hasMore, favorites];
}
