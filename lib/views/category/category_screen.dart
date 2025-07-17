import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/item_container.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../theme/appcolors.dart';
import '../../services/firebase_service.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  
  const CategoryScreen({
    super.key, 
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تحميل منتجات الفئة عند فتح الشاشة
      context.read<ProductBloc>().add(FetchProductsByCategory(
        categoryId: widget.categoryId,
        limit: 10,
      ));
      
      // تحميل حالة المفضلة للمستخدم الحالي
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<ProductBloc>().add(LoadFavorites(user.uid));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductsLoading) {
            return  Center(
              child: CircularProgressIndicator(color: AppColors.orangeColor),
            );
          } else if (state is CategoryProductsLoaded) {
            final products = state.products;
            
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد منتجات في هذه الفئة',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سيتم إضافة منتجات قريباً',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان الفئة وعدد المنتجات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orangeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${products.length} منتج',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orangeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // شبكة المنتجات
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.65, // تقليل النسبة لتجنب overflow
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListenableBuilder(
                          listenable: context.read<ProductBloc>().favoritesNotifier,
                          builder: (context, child) {
                            final bloc = context.read<ProductBloc>();
                            final isFavorite = bloc.favoritesNotifier.isProductFavorite(product.id);
                            
                            return ProductCard(
                              product: product,
                              isFavorite: isFavorite,
                              onFavoritePressed: () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  if (isFavorite) {
                                    context.read<ProductBloc>().add(RemoveFromFavorites(user.uid, product.id));
                                  } else {
                                    context.read<ProductBloc>().add(AddToFavorites(user.uid, product.id));
                                  }
                                }
                              },
                              onAddPressed: () {}, // سيتم التعامل معه داخل ProductCard
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else if (state is ProductsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ في تحميل المنتجات',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductBloc>().add(FetchProductsByCategory(
                        categoryId: widget.categoryId,
                        limit: 10,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          } else {
            return  Center(
              child: CircularProgressIndicator(color: AppColors.orangeColor),
            );
          }
        },
      ),
    );
  }
}

// شاشة الأكثر مبيعاً
class BestSellersScreen extends StatefulWidget {
  const BestSellersScreen({Key? key}) : super(key: key);

  @override
  State<BestSellersScreen> createState() => _BestSellersScreenState();
}

class _BestSellersScreenState extends State<BestSellersScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  ProductModel? _lastProduct;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBestSellers();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<ProductBloc>().add(LoadFavorites(user.uid));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBestSellers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _products = [];
        _hasMore = true;
        _lastProduct = null;
      });
    }
    setState(() { _isLoading = true; });
    final products = await _firebaseService.getBestSellers(limit: _pageSize, lastProduct: _lastProduct);
    setState(() {
      _products.addAll(products);
      _isLoading = false;
      _hasMore = products.length == _pageSize;
      if (products.isNotEmpty) _lastProduct = products.last;
    });
  }

  Future<void> _loadMoreBestSellers() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() { _isLoadingMore = true; });
    final products = await _firebaseService.getBestSellers(limit: _pageSize, lastProduct: _lastProduct);
    setState(() {
      _products.addAll(products);
      _isLoadingMore = false;
      _hasMore = products.length == _pageSize;
      if (products.isNotEmpty) _lastProduct = products.last;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
      _loadMoreBestSellers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأكثر مبيعاً'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading && _products.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.orangeColor))
          : _products.isEmpty
              ? Center(child: Text('لا توجد منتجات الأكثر مبيعاً حالياً'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
                        _loadMoreBestSellers();
                      }
                      return false;
                    },
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _products.length && _isLoadingMore) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final product = _products[index];
                        return ListenableBuilder(
                          listenable: context.read<ProductBloc>().favoritesNotifier,
                          builder: (context, child) {
                            final bloc = context.read<ProductBloc>();
                            final isFavorite = bloc.favoritesNotifier.isProductFavorite(product.id);
                            return ProductCard(
                              product: product,
                              isFavorite: isFavorite,
                              onFavoritePressed: () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  if (isFavorite) {
                                    context.read<ProductBloc>().add(RemoveFromFavorites(user.uid, product.id));
                                  } else {
                                    context.read<ProductBloc>().add(AddToFavorites(user.uid, product.id));
                                  }
                                }
                              },
                              onAddPressed: () {},
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

// شاشة العروض الخاصة
class SpecialOffersScreen extends StatefulWidget {
  const SpecialOffersScreen({Key? key}) : super(key: key);

  @override
  State<SpecialOffersScreen> createState() => _SpecialOffersScreenState();
}

class _SpecialOffersScreenState extends State<SpecialOffersScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  ProductModel? _lastProduct;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSpecialOffers();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<ProductBloc>().add(LoadFavorites(user.uid));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialOffers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _products = [];
        _hasMore = true;
        _lastProduct = null;
      });
    }
    setState(() { _isLoading = true; });
    final products = await _firebaseService.getSpecialOffers(limit: _pageSize, lastProduct: _lastProduct);
    setState(() {
      _products.addAll(products);
      _isLoading = false;
      _hasMore = products.length == _pageSize;
      if (products.isNotEmpty) _lastProduct = products.last;
    });
  }

  Future<void> _loadMoreSpecialOffers() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() { _isLoadingMore = true; });
    final products = await _firebaseService.getSpecialOffers(limit: _pageSize, lastProduct: _lastProduct);
    setState(() {
      _products.addAll(products);
      _isLoadingMore = false;
      _hasMore = products.length == _pageSize;
      if (products.isNotEmpty) _lastProduct = products.last;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
      _loadMoreSpecialOffers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كل العروض الخاصة'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading && _products.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.orangeColor))
          : _products.isEmpty
              ? Center(child: Text('لا توجد عروض خاصة حالياً'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
                        _loadMoreSpecialOffers();
                      }
                      return false;
                    },
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _products.length && _isLoadingMore) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final product = _products[index];
                        return ListenableBuilder(
                          listenable: context.read<ProductBloc>().favoritesNotifier,
                          builder: (context, child) {
                            final bloc = context.read<ProductBloc>();
                            final isFavorite = bloc.favoritesNotifier.isProductFavorite(product.id);
                            return ProductCard(
                              product: product,
                              isFavorite: isFavorite,
                              onFavoritePressed: () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  if (isFavorite) {
                                    context.read<ProductBloc>().add(RemoveFromFavorites(user.uid, product.id));
                                  } else {
                                    context.read<ProductBloc>().add(AddToFavorites(user.uid, product.id));
                                  }
                                }
                              },
                              onAddPressed: () {},
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}
