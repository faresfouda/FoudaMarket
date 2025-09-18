import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/product_model.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_event.dart';
import '../../../blocs/product/product_state.dart';
import '../../../theme/appcolors.dart';
import '../../../components/item_container.dart';

class BestSellersScreen extends StatefulWidget {
  const BestSellersScreen({super.key});

  @override
  State<BestSellersScreen> createState() => _BestSellersScreenState();
}

class _BestSellersScreenState extends State<BestSellersScreen> {
  final ScrollController _scrollController = ScrollController();
  late ProductBloc _productBloc;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _productBloc = context.read<ProductBloc>();

    // Load best sellers
    _productBloc.add(const FetchBestSellers(limit: 20));

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      _loadMoreBestSellers();
    }
  }

  void _loadMoreBestSellers() {
    if (!_isLoadingMore && _productBloc.state is BestSellersLoaded) {
      final currentState = _productBloc.state as BestSellersLoaded;
      if (currentState.products.length >= 20) {
        // Load more products
        _productBloc.add(const FetchBestSellers(limit: 40));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Stack(
          children: [
            // Background image
            Image.asset(
              'assets/home/backgroundblur.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SafeArea(
              child: Column(
                children: [
                  // Custom AppBar
                  _buildAppBar(),
                  // Products Grid
                  Expanded(
                    child: BlocConsumer<ProductBloc, ProductState>(
                      listener: (context, state) {
                        if (state is ProductsError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ في تحميل الأكثر مبيعاً: ${state.message}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        if (state is BestSellersLoaded) {
                          setState(() {
                            _isLoadingMore = false;
                            _hasReachedMax = state.products.length < 20;
                          });
                        }
                      },
                      builder: (context, state) {
                        if (state is ProductsLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.orangeColor,
                              ),
                            ),
                          );
                        }

                        if (state is BestSellersLoaded) {
                          if (state.products.isEmpty) {
                            return _buildEmptyState();
                          }

                          return _buildProductsGrid(state.products);
                        }

                        if (state is ProductsError) {
                          return _buildErrorState(state.message);
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'الأكثر مبيعاً',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return RefreshIndicator(
      onRefresh: () async {
        _productBloc.add(const FetchBestSellers(limit: 20));
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.orangeColor,
                ),
              ),
            );
          }

          final product = products[index];
          return ProductCard(
            product: product,
            isFavorite: false,
            onFavoritePressed: () {
              // منطق إضافة/إزالة من المفضلة
            },
            onAddPressed: () {
              // منطق إضافة للسلة
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات مبيعاً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد منتجات في قائمة الأكثر مبيعاً حالياً',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _productBloc.add(const FetchBestSellers(limit: 20));
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
  }
}
