import 'package:flutter_bloc/flutter_bloc.dart';
import 'category_event.dart';
import 'category_state.dart';
import '../../models/category_model.dart';
import '../../services/firebase_service.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final FirebaseService _firebaseService = FirebaseService();
  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _searchResults = [];
  bool _hasMore = true;
  bool _hasMoreSearch = true;
  String _currentSearchQuery = '';
  static const int defaultLimit = 10; // حد افتراضي 10 للفئات

  CategoryBloc() : super(CategoriesInitial()) {
    on<FetchCategories>(_onFetchCategories);
    on<LoadMoreCategories>(_onLoadMoreCategories);
    on<SearchCategories>(_onSearchCategories);
    on<LoadMoreSearchResults>(_onLoadMoreSearchResults);
    on<ClearSearch>(_onClearSearch);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(
    FetchCategories event,
    Emitter<CategoryState> emit,
  ) async {
    if (state is CategoriesLoading) return;

    emit(CategoriesLoading());
    try {
      final categories = await _firebaseService.getCategoriesPaginated(
        limit: event.limit,
        lastCategory: event.lastCategory,
      );

      if (event.lastCategory == null) {
        // تحميل أولي
        _allCategories = categories;
      } else {
        // تحميل المزيد
        _allCategories.addAll(categories);
      }

      _hasMore = categories.length == event.limit;
      emit(
        CategoriesLoaded(
          List<CategoryModel>.from(_allCategories),
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      emit(CategoriesError('فشل في تحميل الفئات: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreCategories(
    LoadMoreCategories event,
    Emitter<CategoryState> emit,
  ) async {
    if (state is CategoriesLoading) return;

    try {
      final categories = await _firebaseService.getCategoriesPaginated(
        limit: event.limit,
        lastCategory: event.lastCategory,
      );

      if (categories.isNotEmpty) {
        _allCategories.addAll(categories);
        _hasMore = categories.length == event.limit;
        emit(
          CategoriesLoaded(
            List<CategoryModel>.from(_allCategories),
            hasMore: _hasMore,
          ),
        );
      } else {
        _hasMore = false;
        emit(
          CategoriesLoaded(
            List<CategoryModel>.from(_allCategories),
            hasMore: false,
          ),
        );
      }
    } catch (e) {
      emit(CategoriesError('فشل في تحميل المزيد من الفئات: ${e.toString()}'));
    }
  }

  Future<void> _onSearchCategories(
    SearchCategories event,
    Emitter<CategoryState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      _onClearSearch(const ClearSearch(), emit);
      return;
    }

    emit(CategoriesSearching());
    try {
      _currentSearchQuery = event.query.trim();
      final categories = await _firebaseService.searchCategoriesPaginated(
        query: _currentSearchQuery,
        limit: defaultLimit,
      );

      _searchResults = categories;
      _hasMoreSearch = categories.length == defaultLimit;
      emit(
        CategoriesSearchLoaded(
          List<CategoryModel>.from(_searchResults),
          _currentSearchQuery,
          hasMore: _hasMoreSearch,
        ),
      );
    } catch (e) {
      emit(CategoriesError('فشل في البحث عن الفئات: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreSearchResults(
    LoadMoreSearchResults event,
    Emitter<CategoryState> emit,
  ) async {
    if (state is CategoriesSearching) return;

    try {
      final categories = await _firebaseService.searchCategoriesPaginated(
        query: _currentSearchQuery,
        limit: event.limit,
        lastCategory: event.lastCategory,
      );

      if (categories.isNotEmpty) {
        _searchResults.addAll(categories);
        _hasMoreSearch = categories.length == event.limit;
        emit(
          CategoriesSearchLoaded(
            List<CategoryModel>.from(_searchResults),
            _currentSearchQuery,
            hasMore: _hasMoreSearch,
          ),
        );
      } else {
        _hasMoreSearch = false;
        emit(
          CategoriesSearchLoaded(
            List<CategoryModel>.from(_searchResults),
            _currentSearchQuery,
            hasMore: false,
          ),
        );
      }
    } catch (e) {
      emit(
        CategoriesError('فشل في تحميل المزيد من نتائج البحث: ${e.toString()}'),
      );
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<CategoryState> emit) {
    _currentSearchQuery = '';
    _searchResults.clear();
    _hasMoreSearch = true;

    if (_allCategories.isNotEmpty) {
      emit(
        CategoriesLoaded(
          List<CategoryModel>.from(_allCategories),
          hasMore: _hasMore,
        ),
      );
    } else {
      emit(CategoriesInitial());
    }
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(CategoriesLoading());
      await _firebaseService.addCategory(event.category);

      // تحديث القائمة المحلية
      final updatedCategories = await _firebaseService.getCategories();
      _allCategories = updatedCategories;
      emit(
        CategoriesLoaded(
          List<CategoryModel>.from(_allCategories),
          hasMore: false,
        ),
      );
    } catch (e) {
      emit(CategoriesError('فشل في إضافة الفئة: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(CategoriesLoading());
      await _firebaseService.updateCategory(
        event.category.id,
        event.category.toJson(),
      );

      // تحديث القائمة المحلية
      final updatedCategories = await _firebaseService.getCategories();
      _allCategories = updatedCategories;
      emit(
        CategoriesLoaded(
          List<CategoryModel>.from(_allCategories),
          hasMore: false,
        ),
      );
    } catch (e) {
      emit(CategoriesError('فشل في تحديث الفئة: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(CategoriesLoading());
      await _firebaseService.deleteCategory(event.categoryId);

      // تحديث القائمة المحلية
      _allCategories.removeWhere((category) => category.id == event.categoryId);
      emit(
        CategoriesLoaded(
          List<CategoryModel>.from(_allCategories),
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      emit(CategoriesError('فشل في حذف الفئة: ${e.toString()}'));
    }
  }
}
