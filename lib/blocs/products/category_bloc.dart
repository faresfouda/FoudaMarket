import 'package:flutter_bloc/flutter_bloc.dart';
import 'category_event.dart';
import 'category_state.dart';
import '../../models/category_model.dart';
import '../../services/firebase_service.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final FirebaseService _firebaseService = FirebaseService();
  List<CategoryModel> _allCategories = [];
  bool _hasMore = true;
  static const int defaultLimit = 20;

  CategoryBloc() : super(CategoriesInitial()) {
    on<FetchCategories>(_onFetchCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(FetchCategories event, Emitter<CategoryState> emit) async {
    if (state is CategoriesLoading) return;
    emit(CategoriesLoading());
    try {
      final categories = await _firebaseService.getCategoriesPaginated(
        limit: event.limit,
        lastCategory: event.lastCategory,
      );
      if (event.lastCategory == null) {
        _allCategories = categories;
      } else {
        _allCategories.addAll(categories);
      }
      _hasMore = categories.length == event.limit;
      emit(CategoriesLoaded(List<CategoryModel>.from(_allCategories), hasMore: _hasMore));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onAddCategory(AddCategory event, Emitter<CategoryState> emit) async {
    try {
      await _firebaseService.addCategory(event.category);
      add(const FetchCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onUpdateCategory(UpdateCategory event, Emitter<CategoryState> emit) async {
    try {
      await _firebaseService.updateCategory(event.category.id, event.category.toJson());
      add(const FetchCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onDeleteCategory(DeleteCategory event, Emitter<CategoryState> emit) async {
    try {
      await _firebaseService.deleteCategory(event.categoryId);
      add(const FetchCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
} 