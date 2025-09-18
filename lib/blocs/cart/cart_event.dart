import 'package:equatable/equatable.dart';
import '../../models/cart_item_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  final String userId;

  const LoadCart(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddToCart extends CartEvent {
  final CartItemModel cartItem;

  const AddToCart(this.cartItem);

  @override
  List<Object?> get props => [cartItem];
}

class UpdateCartItem extends CartEvent {
  final String cartItemId;
  final int quantity;
  final String userId;

  const UpdateCartItem(this.cartItemId, this.quantity, this.userId);

  @override
  List<Object?> get props => [cartItemId, quantity, userId];
}

class RemoveFromCart extends CartEvent {
  final String cartItemId;
  final String userId;

  const RemoveFromCart(this.cartItemId, this.userId);

  @override
  List<Object?> get props => [cartItemId, userId];
}

class ClearCart extends CartEvent {
  final String userId;

  const ClearCart(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshCart extends CartEvent {
  final String userId;

  const RefreshCart(this.userId);

  @override
  List<Object?> get props => [userId];
} 