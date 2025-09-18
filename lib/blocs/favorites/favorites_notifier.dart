import 'package:flutter/foundation.dart';

/// A ChangeNotifier that manages favorite product IDs
/// This is used to provide immediate UI updates for favorite actions
/// without interfering with the main product loading states
class FavoritesNotifier extends ChangeNotifier {
  Set<String> _favoriteProductIds = {};

  Set<String> get favoriteProductIds => Set<String>.from(_favoriteProductIds);

  bool isProductFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  void updateFavorites(Set<String> favorites) {
    _favoriteProductIds = Set<String>.from(favorites);
    notifyListeners();
  }

  void addFavorite(String productId) {
    _favoriteProductIds.add(productId);
    notifyListeners();
  }

  void removeFavorite(String productId) {
    _favoriteProductIds.remove(productId);
    notifyListeners();
  }

  void clearFavorites() {
    _favoriteProductIds.clear();
    notifyListeners();
  }
}
