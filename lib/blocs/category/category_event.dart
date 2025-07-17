import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class FetchCategories extends CategoryEvent {
  final int limit;
  final CategoryModel? lastCategory;
  const FetchCategories({this.limit = 20, this.lastCategory});
  @override
  List<Object?> get props => [limit, lastCategory];
}

class LoadMoreCategories extends CategoryEvent {
  final int limit;
  final CategoryModel? lastCategory;
  const LoadMoreCategories({this.limit = 20, this.lastCategory});
  @override
  List<Object?> get props => [limit, lastCategory];
}

class AddCategory extends CategoryEvent {
  final CategoryModel category;
  const AddCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class UpdateCategory extends CategoryEvent {
  final CategoryModel category;
  const UpdateCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class DeleteCategory extends CategoryEvent {
  final String categoryId;
  const DeleteCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class SearchCategories extends CategoryEvent {
  final String query;
  const SearchCategories(this.query);
  @override
  List<Object?> get props => [query];
}

class LoadMoreSearchResults extends CategoryEvent {
  final int limit;
  final CategoryModel? lastCategory;
  const LoadMoreSearchResults({this.limit = 10, this.lastCategory});
  @override
  List<Object?> get props => [limit, lastCategory];
}

class ClearSearch extends CategoryEvent {
  const ClearSearch();
  @override
  List<Object?> get props => [];
}
