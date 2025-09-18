import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase_service.dart';

// Events
abstract class ProductSearchEvent extends Equatable {
  const ProductSearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchProducts extends ProductSearchEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchProductsInCategory extends ProductSearchEvent {
  final String categoryId;
  final String query;

  const SearchProductsInCategory(this.categoryId, this.query);

  @override
  List<Object?> get props => [categoryId, query];
}

class SearchVisibleProducts extends ProductSearchEvent {
  final String query;
  final List<String>? categories;
  final double? minPrice;
  final double? maxPrice;

  const SearchVisibleProducts(
    this.query, {
    this.categories,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [query, categories, minPrice, maxPrice];
}

class SearchVisibleProductsInCategory extends ProductSearchEvent {
  final String categoryId;
  final String query;

  const SearchVisibleProductsInCategory(this.categoryId, this.query);

  @override
  List<Object?> get props => [categoryId, query];
}

class ClearSearch extends ProductSearchEvent {
  const ClearSearch();
}

// States
abstract class ProductSearchState extends Equatable {
  const ProductSearchState();
  @override
  List<Object?> get props => [];
}

class ProductSearchInitial extends ProductSearchState {
  const ProductSearchInitial();
}

class ProductSearching extends ProductSearchState {
  const ProductSearching();
}

class ProductSearchLoaded extends ProductSearchState {
  final List<ProductModel> products;
  final String query;
  final String? categoryId;

  const ProductSearchLoaded(
    this.products,
    this.query, {
    this.categoryId,
  });

  @override
  List<Object?> get props => [products, query, categoryId];
}

class ProductSearchError extends ProductSearchState {
  final String message;

  const ProductSearchError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductSearchEmpty extends ProductSearchState {
  final String query;

  const ProductSearchEmpty(this.query);

  @override
  List<Object?> get props => [query];
}

// Bloc
class ProductSearchBloc extends Bloc<ProductSearchEvent, ProductSearchState> {
  final FirebaseService _firebaseService;

  ProductSearchBloc({
    FirebaseService? firebaseService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        super(const ProductSearchInitial()) {
    on<SearchProducts>(_onSearchProducts);
    on<SearchProductsInCategory>(_onSearchProductsInCategory);
    on<SearchVisibleProducts>(_onSearchVisibleProducts);
    on<SearchVisibleProductsInCategory>(_onSearchVisibleProductsInCategory);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductSearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(const ProductSearchInitial());
      return;
    }

    emit(const ProductSearching());

    try {
      final products = await _firebaseService.searchProducts(query);

      if (products.isEmpty) {
        emit(ProductSearchEmpty(query));
      } else {
        emit(ProductSearchLoaded(products, query));
      }
    } catch (e) {
      emit(ProductSearchError('Failed to search products: ${e.toString()}'));
    }
  }

  Future<void> _onSearchProductsInCategory(
    SearchProductsInCategory event,
    Emitter<ProductSearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(const ProductSearchInitial());
      return;
    }

    emit(const ProductSearching());

    try {
      final products = await _firebaseService.searchProductsInCategory(
        event.categoryId,
        query,
      );

      if (products.isEmpty) {
        emit(ProductSearchEmpty(query));
      } else {
        emit(ProductSearchLoaded(
          products,
          query,
          categoryId: event.categoryId,
        ));
      }
    } catch (e) {
      emit(ProductSearchError(
        'Failed to search products in category: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSearchVisibleProducts(
    SearchVisibleProducts event,
    Emitter<ProductSearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty &&
        (event.categories == null || event.categories!.isEmpty) &&
        event.minPrice == null &&
        event.maxPrice == null) {
      emit(const ProductSearchInitial());
      return;
    }

    emit(const ProductSearching());

    try {
      final products = await _firebaseService.searchVisibleProducts(
        query,
        categories: event.categories,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
      );

      if (products.isEmpty) {
        emit(ProductSearchEmpty(query));
      } else {
        emit(ProductSearchLoaded(products, query));
      }
    } catch (e) {
      emit(ProductSearchError(
        'Failed to search visible products: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSearchVisibleProductsInCategory(
    SearchVisibleProductsInCategory event,
    Emitter<ProductSearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(const ProductSearchInitial());
      return;
    }

    emit(const ProductSearching());

    try {
      final products = await _firebaseService.searchVisibleProductsInCategory(
        event.categoryId,
        query,
      );

      if (products.isEmpty) {
        emit(ProductSearchEmpty(query));
      } else {
        emit(ProductSearchLoaded(
          products,
          query,
          categoryId: event.categoryId,
        ));
      }
    } catch (e) {
      emit(ProductSearchError(
        'Failed to search visible products in category: ${e.toString()}',
      ));
    }
  }

  void _onClearSearch(
    ClearSearch event,
    Emitter<ProductSearchState> emit,
  ) {
    emit(const ProductSearchInitial());
  }
}
