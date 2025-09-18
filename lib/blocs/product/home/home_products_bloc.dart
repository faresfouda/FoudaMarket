import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase_service.dart';

// Events
abstract class HomeProductsEvent extends Equatable {
  const HomeProductsEvent();
  @override
  List<Object?> get props => [];
}

class FetchBestSellers extends HomeProductsEvent {
  final int limit;

  const FetchBestSellers({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class FetchSpecialOffers extends HomeProductsEvent {
  final int limit;

  const FetchSpecialOffers({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class FetchRecommendedProducts extends HomeProductsEvent {
  final int limit;

  const FetchRecommendedProducts({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadAllHomeData extends HomeProductsEvent {
  final int limit;

  const LoadAllHomeData({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class RefreshHomeData extends HomeProductsEvent {
  final int limit;

  const RefreshHomeData({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class ResetHomeProducts extends HomeProductsEvent {
  const ResetHomeProducts();
}

// States
abstract class HomeProductsState extends Equatable {
  const HomeProductsState();
  @override
  List<Object?> get props => [];
}

class HomeProductsInitial extends HomeProductsState {
  const HomeProductsInitial();
}

class HomeProductsLoading extends HomeProductsState {
  const HomeProductsLoading();
}

class HomeProductsLoaded extends HomeProductsState {
  final List<ProductModel> specialOffers;
  final List<ProductModel> bestSellers;
  final List<ProductModel> recommendedProducts;
  final bool isLoadingSpecialOffers;
  final bool isLoadingBestSellers;
  final bool isLoadingRecommended;

  const HomeProductsLoaded({
    required this.specialOffers,
    required this.bestSellers,
    required this.recommendedProducts,
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
      isLoadingSpecialOffers: isLoadingSpecialOffers ?? this.isLoadingSpecialOffers,
      isLoadingBestSellers: isLoadingBestSellers ?? this.isLoadingBestSellers,
      isLoadingRecommended: isLoadingRecommended ?? this.isLoadingRecommended,
    );
  }
}

class SpecialOffersLoaded extends HomeProductsState {
  final List<ProductModel> products;

  const SpecialOffersLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class BestSellersLoaded extends HomeProductsState {
  final List<ProductModel> products;

  const BestSellersLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class HomeProductsError extends HomeProductsState {
  final String message;

  const HomeProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class HomeProductsBloc extends Bloc<HomeProductsEvent, HomeProductsState> {
  final FirebaseService _firebaseService;

  List<ProductModel> _specialOffers = [];
  List<ProductModel> _bestSellers = [];
  List<ProductModel> _recommendedProducts = [];

  HomeProductsBloc({
    FirebaseService? firebaseService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        super(const HomeProductsInitial()) {
    on<FetchBestSellers>(_onFetchBestSellers);
    on<FetchSpecialOffers>(_onFetchSpecialOffers);
    on<FetchRecommendedProducts>(_onFetchRecommendedProducts);
    on<LoadAllHomeData>(_onLoadAllHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<ResetHomeProducts>(_onResetHomeProducts);
  }

  Future<void> _onFetchBestSellers(
    FetchBestSellers event,
    Emitter<HomeProductsState> emit,
  ) async {
    try {
      // Check if data already exists to avoid flashing for home page
      if (state is HomeProductsLoaded && event.limit == 10) {
        final currentState = state as HomeProductsLoaded;
        if (currentState.bestSellers.isNotEmpty && !currentState.isLoadingBestSellers) {
          return; // Data already exists, no need to reload
        }
        // Update loading state only
        emit(currentState.copyWith(isLoadingBestSellers: true));
      } else {
        emit(const HomeProductsLoading());
      }

      final products = await _firebaseService.getBestSellers(limit: event.limit);
      _bestSellers = products;

      // If this is a request from home page (limit = 10), send HomeProductsLoaded
      if (state is HomeProductsLoaded && event.limit == 10) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(
          bestSellers: products,
          isLoadingBestSellers: false,
        ));
      }
      // If this is a request from best sellers page (limit > 10), send BestSellersLoaded
      else if (event.limit > 10) {
        emit(BestSellersLoaded(products));
      }
      // For other cases
      else {
        emit(HomeProductsLoaded(
          specialOffers: _specialOffers,
          bestSellers: products,
          recommendedProducts: _recommendedProducts,
          isLoadingBestSellers: false,
        ));
      }
    } catch (e) {
      if (state is HomeProductsLoaded && event.limit == 10) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(isLoadingBestSellers: false));
      }
      emit(HomeProductsError('Failed to fetch best sellers: ${e.toString()}'));
    }
  }

  Future<void> _onFetchSpecialOffers(
    FetchSpecialOffers event,
    Emitter<HomeProductsState> emit,
  ) async {
    try {
      // Check if data already exists to avoid flashing
      if (state is HomeProductsLoaded && event.limit == 10) {
        final currentState = state as HomeProductsLoaded;
        if (currentState.specialOffers.isNotEmpty && !currentState.isLoadingSpecialOffers) {
          return; // Data already exists, no need to reload
        }
        // Update loading state only
        emit(currentState.copyWith(isLoadingSpecialOffers: true));
      } else {
        emit(const HomeProductsLoading());
      }

      final products = await _firebaseService.getSpecialOffers(limit: event.limit);
      _specialOffers = products;

      // If this is a request from home page (limit = 10), send HomeProductsLoaded
      if (state is HomeProductsLoaded && event.limit == 10) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(
          specialOffers: products,
          isLoadingSpecialOffers: false,
        ));
      }
      // If this is a request from special offers page (limit > 10), send SpecialOffersLoaded
      else if (event.limit > 10) {
        emit(SpecialOffersLoaded(products));
      }
      // For other cases
      else {
        emit(HomeProductsLoaded(
          specialOffers: products,
          bestSellers: _bestSellers,
          recommendedProducts: _recommendedProducts,
          isLoadingSpecialOffers: false,
        ));
      }
    } catch (e) {
      if (state is HomeProductsLoaded && event.limit == 10) {
        final currentState = state as HomeProductsLoaded;
        emit(currentState.copyWith(isLoadingSpecialOffers: false));
      }
      emit(HomeProductsError('Failed to fetch special offers: ${e.toString()}'));
    }
  }

  Future<void> _onFetchRecommendedProducts(
    FetchRecommendedProducts event,
    Emitter<HomeProductsState> emit,
  ) async {
    try {
      // Check if data already exists to avoid flashing
      if (state is HomeProductsLoaded) {
        final currentState = state as HomeProductsLoaded;
        if (currentState.recommendedProducts.isNotEmpty && !currentState.isLoadingRecommended) {
          return; // Data already exists, no need to reload
        }
        // Update loading state only
        emit(currentState.copyWith(isLoadingRecommended: true));
      } else {
        emit(const HomeProductsLoading());
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
      emit(HomeProductsError('Failed to fetch recommended products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAllHomeData(
    LoadAllHomeData event,
    Emitter<HomeProductsState> emit,
  ) async {
    emit(const HomeProductsLoading());

    try {
      final results = await Future.wait([
        _firebaseService.getSpecialOffers(limit: event.limit),
        _firebaseService.getBestSellers(limit: event.limit),
        _firebaseService.getRecommendedProducts(limit: event.limit),
      ]);

      _specialOffers = results[0];
      _bestSellers = results[1];
      _recommendedProducts = results[2];

      emit(HomeProductsLoaded(
        specialOffers: _specialOffers,
        bestSellers: _bestSellers,
        recommendedProducts: _recommendedProducts,
      ));
    } catch (e) {
      emit(HomeProductsError('Failed to load home data: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeProductsState> emit,
  ) async {
    // Force refresh by clearing cache and reloading
    _specialOffers.clear();
    _bestSellers.clear();
    _recommendedProducts.clear();

    add(LoadAllHomeData(limit: event.limit));
  }

  Future<void> _onResetHomeProducts(
    ResetHomeProducts event,
    Emitter<HomeProductsState> emit,
  ) async {
    emit(const HomeProductsLoading());

    try {
      final specialOffers = await _firebaseService.getSpecialOffers(limit: 10);
      final bestSellers = await _firebaseService.getBestSellers(limit: 10);
      final recommended = await _firebaseService.getRecommendedProducts(limit: 10);

      _specialOffers = specialOffers;
      _bestSellers = bestSellers;
      _recommendedProducts = recommended;

      emit(HomeProductsLoaded(
        specialOffers: specialOffers,
        bestSellers: bestSellers,
        recommendedProducts: recommended,
        isLoadingSpecialOffers: false,
        isLoadingBestSellers: false,
        isLoadingRecommended: false,
      ));
    } catch (e) {
      emit(HomeProductsError('Failed to reset home products: ${e.toString()}'));
    }
  }

  // Getters
  List<ProductModel> get specialOffers => List<ProductModel>.from(_specialOffers);
  List<ProductModel> get bestSellers => List<ProductModel>.from(_bestSellers);
  List<ProductModel> get recommendedProducts => List<ProductModel>.from(_recommendedProducts);
}
