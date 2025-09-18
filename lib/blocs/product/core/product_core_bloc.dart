import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase_service.dart';

// Events
abstract class ProductCoreEvent extends Equatable {
  const ProductCoreEvent();
  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductCoreEvent {
  final String categoryId;
  final int limit;
  final ProductModel? lastProduct;

  const FetchProducts(
    this.categoryId, {
    this.limit = 20,
    this.lastProduct,
  });

  @override
  List<Object?> get props => [categoryId, limit, lastProduct];
}

class LoadMoreProducts extends ProductCoreEvent {
  final String categoryId;
  final int limit;
  final ProductModel? lastProduct;

  const LoadMoreProducts(
    this.categoryId, {
    this.limit = 20,
    this.lastProduct,
  });

  @override
  List<Object?> get props => [categoryId, limit, lastProduct];
}

class SetCurrentCategory extends ProductCoreEvent {
  final String categoryId;

  const SetCurrentCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class ResetProducts extends ProductCoreEvent {
  const ResetProducts();
}

// States
abstract class ProductCoreState extends Equatable {
  const ProductCoreState();
  @override
  List<Object?> get props => [];
}

class ProductCoreInitial extends ProductCoreState {
  const ProductCoreInitial();
}

class ProductCoreLoading extends ProductCoreState {
  const ProductCoreLoading();
}

class ProductCoreLoaded extends ProductCoreState {
  final List<ProductModel> products;
  final bool hasMore;
  final String? categoryId;

  const ProductCoreLoaded({
    required this.products,
    required this.hasMore,
    this.categoryId,
  });

  @override
  List<Object?> get props => [products, hasMore, categoryId];
}

class ProductCoreError extends ProductCoreState {
  final String message;

  const ProductCoreError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class ProductCoreBloc extends Bloc<ProductCoreEvent, ProductCoreState> {
  final FirebaseService _firebaseService;

  List<ProductModel> _allProducts = [];
  bool _hasMore = true;
  String? _currentCategoryId;
  static const int defaultLimit = 20;

  ProductCoreBloc({
    FirebaseService? firebaseService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        super(const ProductCoreInitial()) {
    on<SetCurrentCategory>(_onSetCurrentCategory);
    on<FetchProducts>(_onFetchProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<ResetProducts>(_onResetProducts);
  }

  void _onSetCurrentCategory(
    SetCurrentCategory event,
    Emitter<ProductCoreState> emit,
  ) {
    _currentCategoryId = event.categoryId;
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductCoreState> emit,
  ) async {
    // Don't prevent loading if we're switching categories
    if (state is ProductCoreLoading && _currentCategoryId == event.categoryId) {
      return;
    }

    emit(const ProductCoreLoading());

    try {
      // Reset internal state when switching categories
      if (_currentCategoryId != event.categoryId) {
        _allProducts = [];
        _hasMore = true;
      }

      _currentCategoryId = event.categoryId;

      final products = await _firebaseService.getProductsForCategoryPaginated(
        categoryId: event.categoryId,
        limit: event.limit,
        lastProduct: event.lastProduct,
      );

      if (products.isEmpty) {
        _allProducts = [];
        _hasMore = false;
        emit(ProductCoreLoaded(
          products: const [],
          hasMore: false,
          categoryId: event.categoryId,
        ));
      } else {
        _allProducts = products;
        _hasMore = products.length == event.limit;
        emit(ProductCoreLoaded(
          products: List<ProductModel>.from(_allProducts),
          hasMore: _hasMore,
          categoryId: event.categoryId,
        ));
      }
    } catch (e) {
      emit(ProductCoreError('Failed to fetch products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductCoreState> emit,
  ) async {
    if (state is ProductCoreLoading) return;

    try {
      final products = await _firebaseService.getProductsForCategoryPaginated(
        categoryId: event.categoryId,
        limit: event.limit,
        lastProduct: event.lastProduct,
      );

      if (products.isNotEmpty) {
        _allProducts.addAll(products);
        _hasMore = products.length == event.limit;
        emit(ProductCoreLoaded(
          products: List<ProductModel>.from(_allProducts),
          hasMore: _hasMore,
          categoryId: event.categoryId,
        ));
      } else {
        _hasMore = false;
        emit(ProductCoreLoaded(
          products: List<ProductModel>.from(_allProducts),
          hasMore: false,
          categoryId: event.categoryId,
        ));
      }
    } catch (e) {
      emit(ProductCoreError('Failed to load more products: ${e.toString()}'));
    }
  }

  void _onResetProducts(
    ResetProducts event,
    Emitter<ProductCoreState> emit,
  ) {
    _allProducts = [];
    _hasMore = true;
    _currentCategoryId = null;
    emit(const ProductCoreInitial());
  }

  // Getters
  List<ProductModel> get allProducts => List<ProductModel>.from(_allProducts);
  bool get hasMore => _hasMore;
  String? get currentCategoryId => _currentCategoryId;
}
