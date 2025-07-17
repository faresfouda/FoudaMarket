import 'package:equatable/equatable.dart';
import '../../models/cart_item_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemModel> cartItems;
  final double total;
  final int itemsCount;

  const CartLoaded({
    required this.cartItems,
    required this.total,
    required this.itemsCount,
  });

  @override
  List<Object?> get props => [cartItems, total, itemsCount];

  CartLoaded copyWith({
    List<CartItemModel>? cartItems,
    double? total,
    int? itemsCount,
  }) {
    return CartLoaded(
      cartItems: cartItems ?? this.cartItems,
      total: total ?? this.total,
      itemsCount: itemsCount ?? this.itemsCount,
    );
  }
}

class CartEmpty extends CartState {}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartActionLoading extends CartState {}

class CartActionSuccess extends CartState {
  final String message;

  const CartActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CartActionError extends CartState {
  final String message;

  const CartActionError(this.message);

  @override
  List<Object?> get props => [message];
} 