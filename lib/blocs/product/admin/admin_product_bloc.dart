import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../models/product_model.dart';
import '../../../services/firebase_service.dart';
import '../../../services/cloudinary_service.dart';

// Events
abstract class AdminProductEvent extends Equatable {
  const AdminProductEvent();
  @override
  List<Object?> get props => [];
}

class AddProduct extends AdminProductEvent {
  final ProductModel product;

  const AddProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends AdminProductEvent {
  final ProductModel product;

  const UpdateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends AdminProductEvent {
  final String productId;

  const DeleteProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

class AddProductWithImage extends AdminProductEvent {
  final ProductModel product;
  final File imageFile;

  const AddProductWithImage(this.product, this.imageFile);

  @override
  List<Object?> get props => [product, imageFile];
}

class UpdateProductWithImage extends AdminProductEvent {
  final ProductModel product;
  final File imageFile;

  const UpdateProductWithImage(this.product, this.imageFile);

  @override
  List<Object?> get props => [product, imageFile];
}

class FetchAllProductsForCategory extends AdminProductEvent {
  final String categoryId;
  final int limit;
  final ProductModel? lastProduct;

  const FetchAllProductsForCategory(
    this.categoryId, {
    this.limit = 20,
    this.lastProduct,
  });

  @override
  List<Object?> get props => [categoryId, limit, lastProduct];
}

class LoadMoreAllProducts extends AdminProductEvent {
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

class SearchAllProductsInCategory extends AdminProductEvent {
  final String categoryId;
  final String query;

  const SearchAllProductsInCategory(this.categoryId, this.query);

  @override
  List<Object?> get props => [categoryId, query];
}

// States
abstract class AdminProductState extends Equatable {
  const AdminProductState();
  @override
  List<Object?> get props => [];
}

class AdminProductInitial extends AdminProductState {
  const AdminProductInitial();
}

class AdminProductLoading extends AdminProductState {
  const AdminProductLoading();
}

class AdminProductsLoaded extends AdminProductState {
  final List<ProductModel> products;
  final bool hasMore;
  final String? categoryId;

  const AdminProductsLoaded({
    required this.products,
    required this.hasMore,
    this.categoryId,
  });

  @override
  List<Object?> get props => [products, hasMore, categoryId];
}

class AdminProductSuccess extends AdminProductState {
  final String message;
  final ProductModel? product;

  const AdminProductSuccess(this.message, {this.product});

  @override
  List<Object?> get props => [message, product];
}

class AdminProductError extends AdminProductState {
  final String message;

  const AdminProductError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminProductSearchLoaded extends AdminProductState {
  final List<ProductModel> products;
  final String query;
  final String categoryId;

  const AdminProductSearchLoaded(this.products, this.query, this.categoryId);

  @override
  List<Object?> get props => [products, query, categoryId];
}

// Bloc
class AdminProductBloc extends Bloc<AdminProductEvent, AdminProductState> {
  final FirebaseService _firebaseService;
  final CloudinaryService _cloudinaryService;

  List<ProductModel> _allProducts = [];
  bool _hasMore = true;
  String? _currentCategoryId;

  AdminProductBloc({
    FirebaseService? firebaseService,
    CloudinaryService? cloudinaryService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _cloudinaryService = cloudinaryService ?? CloudinaryService(),
        super(const AdminProductInitial()) {
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<AddProductWithImage>(_onAddProductWithImage);
    on<UpdateProductWithImage>(_onUpdateProductWithImage);
    on<FetchAllProductsForCategory>(_onFetchAllProductsForCategory);
    on<LoadMoreAllProducts>(_onLoadMoreAllProducts);
    on<SearchAllProductsInCategory>(_onSearchAllProductsInCategory);
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductLoading());

      await _firebaseService.addProduct(event.product);

      emit(AdminProductSuccess(
        'Product added successfully',
        product: event.product,
      ));

      // Refresh the current category if set
      if (_currentCategoryId != null) {
        add(FetchAllProductsForCategory(_currentCategoryId!));
      }
    } catch (e) {
      emit(AdminProductError('Failed to add product: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductLoading());

      await _firebaseService.updateProduct(
        event.product.id,
        event.product.toJson(),
      );

      emit(AdminProductSuccess(
        'Product updated successfully',
        product: event.product,
      ));

      // Refresh the current category if set
      if (_currentCategoryId != null) {
        add(FetchAllProductsForCategory(_currentCategoryId!));
      }
    } catch (e) {
      emit(AdminProductError('Failed to update product: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductLoading());

      await _firebaseService.deleteProduct(event.productId);

      emit(const AdminProductSuccess('Product deleted successfully'));

      // Refresh the current category if set
      if (_currentCategoryId != null) {
        add(FetchAllProductsForCategory(_currentCategoryId!));
      }
    } catch (e) {
      emit(AdminProductError('Failed to delete product: ${e.toString()}'));
    }
  }

  Future<void> _onAddProductWithImage(
    AddProductWithImage event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductLoading());

      final imageUrl = await _cloudinaryService.uploadImage(event.imageFile.path);

      if (imageUrl == null) {
        emit(const AdminProductError('Image upload failed'));
        return;
      }

      final now = DateTime.now();
      final product = event.product.copyWith(
        images: [imageUrl],
        createdAt: now,
        updatedAt: now,
      );

      await _firebaseService.addProduct(product);

      emit(AdminProductSuccess(
        'Product with image added successfully',
        product: product,
      ));

      // Refresh the current category if set
      if (_currentCategoryId != null) {
        add(FetchAllProductsForCategory(_currentCategoryId!));
      }
    } catch (e) {
      emit(AdminProductError('Failed to add product with image: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProductWithImage(
    UpdateProductWithImage event,
    Emitter<AdminProductState> emit,
  ) async {
    try {
      emit(const AdminProductLoading());

      final imageUrl = await _cloudinaryService.uploadImage(event.imageFile.path);

      if (imageUrl == null) {
        emit(const AdminProductError('Image upload failed'));
        return;
      }

      final now = DateTime.now();
      final product = event.product.copyWith(
        images: [imageUrl],
        updatedAt: now,
      );

      await _firebaseService.updateProduct(product.id, product.toJson());

      emit(AdminProductSuccess(
        'Product with image updated successfully',
        product: product,
      ));

      // Refresh the current category if set
      if (_currentCategoryId != null) {
        add(FetchAllProductsForCategory(_currentCategoryId!));
      }
    } catch (e) {
      emit(AdminProductError('Failed to update product with image: ${e.toString()}'));
    }
  }

  Future<void> _onFetchAllProductsForCategory(
    FetchAllProductsForCategory event,
    Emitter<AdminProductState> emit,
  ) async {
    emit(const AdminProductLoading());

    try {
      _currentCategoryId = event.categoryId;

      final products = await _firebaseService.getAllProductsForCategoryPaginated(
        categoryId: event.categoryId,
        limit: event.limit,
        lastProduct: event.lastProduct,
      );

      _allProducts = products;
      _hasMore = products.length == event.limit;

      emit(AdminProductsLoaded(
        products: List<ProductModel>.from(_allProducts),
        hasMore: _hasMore,
        categoryId: event.categoryId,
      ));
    } catch (e) {
      emit(AdminProductError('Failed to fetch all products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreAllProducts(
    LoadMoreAllProducts event,
    Emitter<AdminProductState> emit,
  ) async {
    if (state is AdminProductLoading) return;

    try {
      final products = await _firebaseService.getAllProductsForCategoryPaginated(
        categoryId: event.categoryId,
        limit: event.limit,
        lastProduct: event.lastProduct,
      );

      if (products.isNotEmpty) {
        _allProducts.addAll(products);
        _hasMore = products.length == event.limit;

        emit(AdminProductsLoaded(
          products: List<ProductModel>.from(_allProducts),
          hasMore: _hasMore,
          categoryId: event.categoryId,
        ));
      } else {
        _hasMore = false;
        emit(AdminProductsLoaded(
          products: List<ProductModel>.from(_allProducts),
          hasMore: false,
          categoryId: event.categoryId,
        ));
      }
    } catch (e) {
      emit(AdminProductError('Failed to load more all products: ${e.toString()}'));
    }
  }

  Future<void> _onSearchAllProductsInCategory(
    SearchAllProductsInCategory event,
    Emitter<AdminProductState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      add(FetchAllProductsForCategory(event.categoryId));
      return;
    }

    emit(const AdminProductLoading());

    try {
      final products = await _firebaseService.searchProductsInCategory(
        event.categoryId,
        query,
      );

      emit(AdminProductSearchLoaded(products, query, event.categoryId));
    } catch (e) {
      emit(AdminProductError(
        'Failed to search all products in category: ${e.toString()}',
      ));
    }
  }

  // Getters
  List<ProductModel> get allProducts => List<ProductModel>.from(_allProducts);
  bool get hasMore => _hasMore;
  String? get currentCategoryId => _currentCategoryId;
}
