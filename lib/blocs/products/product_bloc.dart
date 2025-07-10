import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../../models/product_model.dart';
import '../../services/firebase_service.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final FirebaseService _firebaseService = FirebaseService();
  List<ProductModel> _allProducts = [];
  bool _hasMore = true;
  static const int defaultLimit = 20;
  String? _currentCategoryId;

  ProductBloc() : super(ProductsInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onFetchProducts(FetchProducts event, Emitter<ProductState> emit) async {
    if (state is ProductsLoading) return;
    emit(ProductsLoading());
    try {
      _currentCategoryId = event.categoryId;
      final products = await _firebaseService.getProductsForCategory(event.categoryId);
      _allProducts = products;
      emit(ProductsLoaded(List<ProductModel>.from(_allProducts), hasMore: false));
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onAddProduct(AddProduct event, Emitter<ProductState> emit) async {
    try {
      await _firebaseService.addProduct(event.product);
      if (_currentCategoryId != null) {
        add(FetchProducts(_currentCategoryId!));
      }
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    try {
      await _firebaseService.updateProduct(event.product.id, event.product.toJson());
      if (_currentCategoryId != null) {
        add(FetchProducts(_currentCategoryId!));
      }
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    try {
      await _firebaseService.deleteProduct(event.productId);
      if (_currentCategoryId != null) {
        add(FetchProducts(_currentCategoryId!));
      }
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }
} 