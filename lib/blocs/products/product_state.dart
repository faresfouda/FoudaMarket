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