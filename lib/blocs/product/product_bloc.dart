import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../favorites/favorites_notifier.dart';
import '../../models/product_model.dart';
import '../../services/firebase_service.dart';
import '../../services/cloudinary_service.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final FirebaseService _firebaseService = FirebaseService();
  final FavoritesNotifier _favoritesNotifier = FavoritesNotifier();
  List<ProductModel> _allProducts = [];
  bool _hasMore = true;
  static const int defaultLimit = 20; // حد افتراضي 20 للمنتجات
  String? _currentCategoryId;

  // Home screen data
  List<ProductModel> _specialOffers = [];
  List<ProductModel> _bestSellers = [];
  List<ProductModel> _recommendedProducts = [];

  // Favorites cache
  Set<String> _favoriteProductIds = {};
  String? _currentUserId;

  // Getter for favorites notifier
  FavoritesNotifier get favoritesNotifier => _favoritesNotifier;

  ProductBloc() : super(ProductsInitial()) {
    on<SetCurrentCategory>(_onSetCurrentCategory);
    on<FetchProducts>(_onFetchProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<SearchProducts>(_onSearchProducts);
    on<SearchProductsInCategory>(_onSearchProductsInCategory);
    on<SearchAllProductsInCategory>(_onSearchAllProductsInCategory);
    on<SearchVisibleProducts>(_onSearchVisibleProducts);
    on<SearchVisibleProductsInCategory>(_onSearchVisibleProductsInCategory);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<AddProductWithImage>(_onAddProductWithImage);
    on<UpdateProductWithImage>(_onUpdateProductWithImage);
    on<FetchBestSellers>(_onFetchBestSellers);
    on<FetchSpecialOffers>(_onFetchSpecialOffers);
    on<FetchRecommendedProducts>(_onFetchRecommendedProducts);
    on<FetchProductsByCategory>(_onFetchProductsByCategory);
    on<FetchAllProductsForCategory>(_onFetchAllProductsForCategory);
    on<LoadMoreAllProducts>(_onLoadMoreAllProducts);
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<ResetHomeProducts>((event, emit) async {
      print('ResetHomeProducts event received');
      emit(ProductsLoading());
      final specialOffers = await _firebaseService.getSpecialOffers(limit: 10);
      final bestSellers = await _firebaseService.getBestSellers(limit: 10);
      final recommended = await _firebaseService.getRecommendedProducts(limit: 10);
      print('Loaded: specialOffers=${specialOffers.length}, bestSellers=${bestSellers.length}, recommended=${recommended.length}');
      emit(HomeProductsLoaded(
        specialOffers: specialOffers,
        bestSellers: bestSellers,
        recommendedProducts: recommended,
        isLoadingSpecialOffers: false,
        isLoadingBestSellers: false,
        isLoadingRecommended: false,
      ));
      print('HomeProductsLoaded emitted');
    });
  }

  void _onSetCurrentCategory(
    SetCurrentCategory event,
    Emitter<ProductState> emit,
  ) {
    _currentCategoryId = event.categoryId;
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductsLoading) return;
    emit(ProductsLoading());
    try {
      _currentCategoryId = event.categoryId;
      final products = await _firebaseService.getProductsForCategoryPaginated(
        categoryId: event.categoryId,
        limit: event.limit,
        lastProduct: event.lastProduct,
      );
      if (products.isEmpty) {
        _allProducts = [];
        _hasMore = false;
        emit(ProductsLoaded([], hasMore: false));
      } else {
        _allProducts = products;
        _hasMore = products.length == event.limit;
        emit(
          ProductsLoaded(
            List<ProductModel>.from(_allProducts),
            hasMore: _hasMore,
          ),
        );
      }
    } catch (e) {
      emit(ProductsError('Failed to fetch products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductsLoading) return;
    try {
      final products = await _firebaseService.getProductsForCategoryPaginated(
        categoryId: event.categoryId,
        limit: event.limit,
        lastProduct: event.lastProduct,
      );
      if (products.isNotEmpty) {
        _allProducts.addAll(products);
        _hasMore = products.length == event.limit;
        emit(
          ProductsLoaded(
            List<ProductModel>.from(_allProducts),
            hasMore: _hasMore,
          ),
        );
      } else {
        _hasMore = false;
        emit(
          ProductsLoaded(List<ProductModel>.from(_allProducts), hasMore: false),
        );
      }
    } catch (e) {
      emit(ProductsError('Failed to load more products: ${e.toString()}'));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(ProductsInitial());
      return;
    }

    emit(ProductsSearching());
    try {
      final products = await _firebaseService.searchProducts(event.query);
      emit(ProductsSearchLoaded(products, event.query));
    } catch (e) {
      emit(ProductsError('Failed to search products: ${e.toString()}'));
    }
  }

  Future<void> _onSearchProductsInCategory(
    SearchProductsInCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      // إذا كان البحث فارغ، ارجع للقائمة العادية
      add(FetchProducts(event.categoryId, limit: defaultLimit));
      return;
    }

    emit(ProductsSearching());
    try {
      final products = await _firebaseService.searchProductsInCategory(
        event.categoryId,
        event.query,
      );
      emit(ProductsSearchLoaded(products, event.query));
    } catch (e) {
      emit(
        ProductsError('Failed to search products in category: ${e.toString()}'),
      );
    }
  }

  Future<void> _onSearchAllProductsInCategory(
    SearchAllProductsInCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      // إذا كان البحث فارغ، ارجع للقائمة العادية
      add(FetchProducts(event.categoryId, limit: defaultLimit));
      return;
    }

    emit(ProductsSearching());
    try {
      final products = await _firebaseService.searchProductsInCategory(
        event.categoryId,
        event.query,
      );
      emit(ProductsSearchLoaded(products, event.query));
    } catch (e) {
      emit(
        ProductsError(
          'Failed to search all products in category: ${e.toString()}',
        ),
      );
    }
  }

  // User search handlers (only visible products)
  Future<void> _onSearchVisibleProducts(
    SearchVisibleProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (event.query.trim().isEmpty && (event.categories == null || event.categories!.isEmpty) && event.minPrice == null && event.maxPrice == null) {
      emit(ProductsInitial());
      return;
    }

    emit(ProductsSearching());
    try {
      final products = await _firebaseService.searchVisibleProducts(
        event.query,
        categories: event.categories,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
      );
      emit(ProductsSearchLoaded(products, event.query));
    } catch (e) {
      emit(ProductsError('Failed to search visible products:  e.toString()}'));
    }
  }

  Future<void> _onSearchVisibleProductsInCategory(
    SearchVisibleProductsInCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      // إذا كان البحث فارغ، ارجع للقائمة العادية
      add(FetchProducts(event.categoryId, limit: defaultLimit));
      return;
    }

    emit(ProductsSearching());
    try {
      final products = await _firebaseService.searchVisibleProductsInCategory(
        event.categoryId,
        event.query,
      );
      emit(ProductsSearchLoaded(products, event.query));
    } catch (e) {
      emit(
        ProductsError(
          'Failed to search visible products in category: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductsLoading());
      await _firebaseService.addProduct(event.product);

      // تحديث القائمة المحلية وإرسال ProductsLoaded مباشرة
      if (_currentCategoryId != null) {
        // استخدام getAllProductsForCategory للأدمن ليشمل جميع المنتجات
        final updatedProducts = await _firebaseService
            .getAllProductsForCategory(_currentCategoryId!);
        _allProducts = updatedProducts;
        emit(
          ProductsLoaded(List<ProductModel>.from(_allProducts), hasMore: false),
        );
      } else {
        // إذا لم تكن هناك فئة محددة، أرسل القائمة الحالية
        emit(ProductsLoaded(_allProducts, hasMore: false));
      }
    } catch (e) {
      emit(ProductsError('Failed to add product: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductsLoading());
      await _firebaseService.updateProduct(
        event.product.id,
        event.product.toJson(),
      );

      // تحديث القائمة المحلية وإرسال ProductsLoaded مباشرة
      if (_currentCategoryId != null) {
        // استخدام getAllProductsForCategory للأدمن ليشمل جميع المنتجات
        final updatedProducts = await _firebaseService
            .getAllProductsForCategory(_currentCategoryId!);
        _allProducts = updatedProducts;
        emit(
          ProductsLoaded(List<ProductModel>.from(_allProducts), hasMore: false),
        );
      } else {
        // إذا لم تكن هناك فئة محددة، أرسل القائمة الحالية
        emit(ProductsLoaded(_allProducts, hasMore: false));
      }
    } catch (e) {
      emit(ProductsError('Failed to update product: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductsLoading());
      await _firebaseService.deleteProduct(event.productId);

      // تحديث القائمة المحلية وإرسال ProductsLoaded مباشرة
      if (_currentCategoryId != null) {
        // استخدام getAllProductsForCategory للأدمن ليشمل جميع المنتجات
        final updatedProducts = await _firebaseService
            .getAllProductsForCategory(_currentCategoryId!);
        _allProducts = updatedProducts;
        emit(
          ProductsLoaded(List<ProductModel>.from(_allProducts), hasMore: false),
        );
      } else {
        // إذا لم تكن هناك فئة محددة، أرسل القائمة الحالية
        emit(ProductsLoaded(_allProducts, hasMore: false));
      }
    } catch (e) {
      emit(ProductsError('Failed to delete product: ${e.toString()}'));
    }
  }

  Future<void> _onAddProductWithImage(
    AddProductWithImage event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductsLoading());
      final imageUrl = await CloudinaryService().uploadImage(
        event.imageFile.path,
      );
      if (imageUrl == null) {
        emit(ProductsError('Image upload failed'));
        return;
      }
      final now = DateTime.now();
      final product = event.product.copyWith(
        images: [imageUrl],
        createdAt: now,
        updatedAt: now,
      );
      await _firebaseService.addProduct(product);

      // تحديث القائمة المحلية وإرسال ProductsLoaded مباشرة
      if (_currentCategoryId != null) {
        final updatedProducts = await _firebaseService
            .getAllProductsForCategory(_currentCategoryId!);
        _allProducts = updatedProducts;
        emit(
          ProductsLoaded(List<ProductModel>.from(_allProducts), hasMore: false),
        );
      } else {
        // إذا لم تكن هناك فئة محددة، أرسل القائمة الحالية
        emit(ProductsLoaded(_allProducts, hasMore: false));
      }
    } catch (e) {
      emit(ProductsError('Failed to add product with image: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProductWithImage(
    UpdateProductWithImage event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(ProductsLoading());
      final imageUrl = await CloudinaryService().uploadImage(
        event.imageFile.path,
      );
      if (imageUrl == null) {
        emit(ProductsError('Image upload failed'));
        return;
      }
      final now = DateTime.now();
      final product = event.product.copyWith(
        images: [imageUrl],
        updatedAt: now,
      );
      await _firebaseService.updateProduct(product.id, product.toJson());

      // تحديث القائمة المحلية وإرسال ProductsLoaded مباشرة
      if (_currentCategoryId != null) {
        final updatedProducts = await _firebaseService
            .getAllProductsForCategory(_currentCategoryId!);
        _allProducts = updatedProducts;
        emit(
          ProductsLoaded(List<ProductModel>.from(_allProducts), hasMore: false),
        );
      } else {
        // إذا لم تكن هناك فئة محددة، أرسل القائمة الحالية
        emit(ProductsLoaded(_allProducts, hasMore: false));
      }
    } catch (e) {
      emit(
        ProductsError('Failed to update product with image: ${e.toString()}'),
      );
    }
  }

  // Home screen handlers
  Future<void> _onFetchBestSellers(
    FetchBestSellers event,
    Emitter<ProductState> emit,
  ) async {
    try {
      // التحقق من وجود البيانات مسبقاً لتجنب الوميض
      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        if (currentState.bestSellers.isNotEmpty && !currentState.isLoadingBestSellers) {
          // البيانات موجودة بالفعل، لا حاجة لإعادة التحميل
          return;
        }
        // تحديث حالة التحميل فقط
        emit(currentState.copyWith(isLoadingBestSellers: true));
      } else {
        emit(ProductsLoading());
      }

      final products = await _firebaseService.getBestSellers(limit: event.limit);
      _bestSellers = products;

      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(
          bestSellers: products,
          isLoadingBestSellers: false,
        ));
      } else {
        emit(HomeProductsLoaded(
          specialOffers: _specialOffers,
          bestSellers: products,
          recommendedProducts: _recommendedProducts,
          isLoadingBestSellers: false,
        ));
      }
    } catch (e) {
      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(isLoadingBestSellers: false));
      }
      emit(ProductsError('Failed to fetch best sellers: ${e.toString()}'));
    }
  }

  Future<void> _onFetchSpecialOffers(
    FetchSpecialOffers event,
    Emitter<ProductState> emit,
  ) async {
    try {
      // التحقق من وجود البيانات مسبقاً لتجنب الوميض
      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        if (currentState.specialOffers.isNotEmpty && !currentState.isLoadingSpecialOffers) {
          // البيانات موجودة بالفعل، لا حاجة لإعادة التحميل
          return;
        }
        // تحديث حالة التحميل فقط
        emit(currentState.copyWith(isLoadingSpecialOffers: true));
      } else {
        emit(ProductsLoading());
      }

      final products = await _firebaseService.getSpecialOffers(limit: event.limit);
      _specialOffers = products;

      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(
          specialOffers: products,
          isLoadingSpecialOffers: false,
        ));
      } else {
        emit(HomeProductsLoaded(
          specialOffers: products,
          bestSellers: _bestSellers,
          recommendedProducts: _recommendedProducts,
          isLoadingSpecialOffers: false,
        ));
      }
    } catch (e) {
      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(isLoadingSpecialOffers: false));
      }
      emit(ProductsError('Failed to fetch special offers: ${e.toString()}'));
    }
  }

  Future<void> _onFetchRecommendedProducts(
    FetchRecommendedProducts event,
    Emitter<ProductState> emit,
  ) async {
    try {
      // التحقق من وجود البيانات مسبقاً لتجنب الوميض
      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        if (currentState.recommendedProducts.isNotEmpty && !currentState.isLoadingRecommended) {
          // البيانات موجودة بالفعل، لا حاجة لإعادة التحميل
          return;
        }
        // تحديث حالة التحميل فقط
        emit(currentState.copyWith(isLoadingRecommended: true));
      } else {
        emit(ProductsLoading());
      }

      final products = await _firebaseService.getRecommendedProducts(limit: event.limit);
      _recommendedProducts = products;

      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(
          recommendedProducts: products,
          isLoadingRecommended: false,
        ));
      } else {
        emit(HomeProductsLoaded(
          specialOffers: _specialOffers,
          bestSellers: _bestSellers,
          recommendedProducts: products,
          isLoadingRecommended: false,
        ));
      }
    } catch (e) {
      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(isLoadingRecommended: false));
      }
      emit(ProductsError('Failed to fetch recommended products: ${e.toString()}'));
    }
  }

  Future<void> _onFetchProductsByCategory(
    FetchProductsByCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductsLoading) return;
    emit(ProductsLoading());
    try {
      final products = await _firebaseService.getProductsForCategoryPaginated(
        categoryId: event.categoryId,
        limit: event.limit,
      );
      emit(CategoryProductsLoaded(products, event.categoryId));
    } catch (e) {
      emit(ProductsError('Failed to fetch category products: ${e.toString()}'));
    }
  }

  // Helper method to check favorite status from cache
  bool isProductFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  // Helper method to get favorite product IDs
  Set<String> getFavoriteProductIds() {
    return Set<String>.from(_favoriteProductIds);
  }

  Future<void> _onFetchAllProductsForCategory(
    FetchAllProductsForCategory event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await _firebaseService
          .getAllProductsForCategoryPaginated(
            categoryId: event.categoryId,
            limit: event.limit,
          );
      emit(ProductsLoaded(products, hasMore: products.length == event.limit));
    } catch (e) {
      emit(ProductsError('Failed to fetch all products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreAllProducts(
    LoadMoreAllProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductsLoading) return;
    try {
      final products = await _firebaseService
          .getAllProductsForCategoryPaginated(
            categoryId: event.categoryId,
            limit: event.limit,
            lastProduct: event.lastProduct,
          );
      if (products.isNotEmpty) {
        final currentState = state as ProductsLoaded;
        final allProducts = [...currentState.products, ...products];
        final hasMore = products.length == event.limit;
        emit(ProductsLoaded(allProducts, hasMore: hasMore));
      } else {
        final currentState = state as ProductsLoaded;
        emit(ProductsLoaded(currentState.products, hasMore: false));
      }
    } catch (e) {
      emit(ProductsError('Failed to load more all products: ${e.toString()}'));
    }
  }

  // Favorite handlers
  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<ProductState> emit,
  ) async {
    try {
      _currentUserId = event.userId;
      final favorites = await _firebaseService.getFavoriteProducts(
        event.userId,
      );
      _favoriteProductIds = favorites.map((p) => p.id).toSet();
      _favoritesNotifier.updateFavorites(
        _favoriteProductIds,
      ); // Update notifier
      // لا نرسل state لتجنب إخفاء المنتجات
    } catch (e) {
      print('Failed to load favorites: ${e.toString()}');
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _firebaseService.addToFavorites(event.userId, event.productId);
      _favoriteProductIds.add(event.productId);
      _favoritesNotifier.addFavorite(event.productId); // Update notifier
      // لا نرسل state لتجنب إخفاء المنتجات
    } catch (e) {
      emit(FavoritesError('Failed to add to favorites: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _firebaseService.removeFromFavorites(event.userId, event.productId);
      _favoriteProductIds.remove(event.productId);
      _favoritesNotifier.removeFavorite(event.productId); // Update notifier
      // لا نرسل state لتجنب إخفاء المنتجات
    } catch (e) {
      emit(FavoritesError('Failed to remove from favorites: ${e.toString()}'));
    }
  }

  Future<void> _onCheckFavoriteStatus(
    CheckFavoriteStatus event,
    Emitter<ProductState> emit,
  ) async {
    try {
      // استخدام cache أولاً للسرعة
      bool isFavorite = _favoriteProductIds.contains(event.productId);

      // إذا لم يكن في cache، تحقق من Firebase
      if (!isFavorite && _currentUserId == event.userId) {
        isFavorite = await _firebaseService.isProductFavorite(
          event.userId,
          event.productId,
        );
        if (isFavorite) {
          _favoriteProductIds.add(event.productId);
          _favoritesNotifier.addFavorite(event.productId); // Update notifier
        }
      }

      emit(FavoriteStatusLoaded(event.productId, isFavorite));
    } catch (e) {
      emit(FavoritesError('Failed to check favorite status: ${e.toString()}'));
    }
  }
}
