import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductEvent {
  final String categoryId;
  final int limit;
  final ProductModel? lastProduct;
  const FetchProducts(this.categoryId, {this.limit = 20, this.lastProduct});
  @override
  List<Object?> get props => [categoryId, limit, lastProduct];
}

class AddProduct extends ProductEvent {
  final ProductModel product;
  const AddProduct(this.product);
  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final ProductModel product;
  const UpdateProduct(this.product);
  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends ProductEvent {
  final String productId;
  const DeleteProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}
