import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase_service.dart';
import '../favorites/favorites_notifier.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {
  final String userId;

  const LoadFavorites(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddToFavorites extends FavoritesEvent {
  final String userId;
  final String productId;

  const AddToFavorites(this.userId, this.productId);

  @override
  List<Object?> get props => [userId, productId];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String userId;
  final String productId;

  const RemoveFromFavorites(this.userId, this.productId);

  @override
  List<Object?> get props => [userId, productId];
}

class CheckFavoriteStatus extends FavoritesEvent {
  final String userId;
  final String productId;

  const CheckFavoriteStatus(this.userId, this.productId);

  @override
  List<Object?> get props => [userId, productId];
}

class ToggleFavorite extends FavoritesEvent {
  final String userId;
  final String productId;

  const ToggleFavorite(this.userId, this.productId);

  @override
  List<Object?> get props => [userId, productId];
}

class ClearFavorites extends FavoritesEvent {
  const ClearFavorites();
}

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final Set<String> favoriteProductIds;
  final List<ProductModel> favoriteProducts;

  const FavoritesLoaded({
    required this.favoriteProductIds,
    required this.favoriteProducts,
  });

  @override
  List<Object?> get props => [favoriteProductIds, favoriteProducts];
}

class FavoriteStatusLoaded extends FavoritesState {
  final String productId;
  final bool isFavorite;

  const FavoriteStatusLoaded(this.productId, this.isFavorite);

  @override
  List<Object?> get props => [productId, isFavorite];
}

class FavoriteToggled extends FavoritesState {
  final String productId;
  final bool isFavorite;

  const FavoriteToggled(this.productId, this.isFavorite);

  @override
  List<Object?> get props => [productId, isFavorite];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FirebaseService _firebaseService;
  final FavoritesNotifier _favoritesNotifier;

  Set<String> _favoriteProductIds = {};
  String? _currentUserId;

  FavoritesBloc({
    FirebaseService? firebaseService,
    FavoritesNotifier? favoritesNotifier,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _favoritesNotifier = favoritesNotifier ?? FavoritesNotifier(),
        super(const FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ClearFavorites>(_onClearFavorites);
  }

  // Getter for favorites notifier
  FavoritesNotifier get favoritesNotifier => _favoritesNotifier;

  // Helper methods
  bool isProductFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  Set<String> getFavoriteProductIds() {
    return Set<String>.from(_favoriteProductIds);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      emit(const FavoritesLoading());

      _currentUserId = event.userId;
      final favorites = await _firebaseService.getFavoriteProducts(event.userId);

      _favoriteProductIds = favorites.map((p) => p.id).toSet();
      _favoritesNotifier.updateFavorites(_favoriteProductIds);

      emit(FavoritesLoaded(
        favoriteProductIds: Set<String>.from(_favoriteProductIds),
        favoriteProducts: favorites,
      ));
    } catch (e) {
      emit(FavoritesError('Failed to load favorites: ${e.toString()}'));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _firebaseService.addToFavorites(event.userId, event.productId);

      _favoriteProductIds.add(event.productId);
      _favoritesNotifier.addFavorite(event.productId);

      emit(FavoriteToggled(event.productId, true));
    } catch (e) {
      emit(FavoritesError('Failed to add to favorites: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _firebaseService.removeFromFavorites(event.userId, event.productId);

      _favoriteProductIds.remove(event.productId);
      _favoritesNotifier.removeFavorite(event.productId);

      emit(FavoriteToggled(event.productId, false));
    } catch (e) {
      emit(FavoritesError('Failed to remove from favorites: ${e.toString()}'));
    }
  }

  Future<void> _onCheckFavoriteStatus(
    CheckFavoriteStatus event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Use cache first for speed
      bool isFavorite = _favoriteProductIds.contains(event.productId);

      // If not in cache and user matches, check Firebase
      if (!isFavorite && _currentUserId == event.userId) {
        isFavorite = await _firebaseService.isProductFavorite(
          event.userId,
          event.productId,
        );

        if (isFavorite) {
          _favoriteProductIds.add(event.productId);
          _favoritesNotifier.addFavorite(event.productId);
        }
      }

      emit(FavoriteStatusLoaded(event.productId, isFavorite));
    } catch (e) {
      emit(FavoritesError('Failed to check favorite status: ${e.toString()}'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final isCurrentlyFavorite = _favoriteProductIds.contains(event.productId);

      if (isCurrentlyFavorite) {
        add(RemoveFromFavorites(event.userId, event.productId));
      } else {
        add(AddToFavorites(event.userId, event.productId));
      }
    } catch (e) {
      emit(FavoritesError('Failed to toggle favorite: ${e.toString()}'));
    }
  }

  void _onClearFavorites(
    ClearFavorites event,
    Emitter<FavoritesState> emit,
  ) {
    _favoriteProductIds.clear();
    _currentUserId = null;
    _favoritesNotifier.updateFavorites({});
    emit(const FavoritesInitial());
  }
}
