import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoryState {}

class CategoriesLoading extends CategoryState {}

class CategoriesLoaded extends CategoryState {
  final List<CategoryModel> categories;
  final bool hasMore;
  const CategoriesLoaded(this.categories, {this.hasMore = true});
  @override
  List<Object?> get props => [categories, hasMore];
}

class CategoriesError extends CategoryState {
  final String message;
  const CategoriesError(this.message);
  @override
  List<Object?> get props => [message];
} 