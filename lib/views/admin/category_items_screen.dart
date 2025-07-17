import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';
import '../../models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import 'add_product_screen.dart';
import 'widgets/index.dart';
import 'widgets/product_search_filters.dart';

class CategoryItemsScreen extends StatelessWidget {
  final String categoryName;
  final String categoryId;
  const CategoryItemsScreen({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final productBloc = ProductBloc();
    // تعيين الفئة الحالية ثم جلب المنتجات
    productBloc.add(SetCurrentCategory(categoryId));
    productBloc.add(
      FetchAllProductsForCategory(categoryId, limit: ProductBloc.defaultLimit),
    ); // استخدام limit للأدمن

    return BlocProvider<ProductBloc>(
      create: (_) => productBloc,
      child: _CategoryItemsScreenBody(
        categoryName: categoryName,
        categoryId: categoryId,
        productBloc: productBloc,
      ),
    );
  }
}

class _CategoryItemsScreenBody extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final ProductBloc productBloc;
  const _CategoryItemsScreenBody({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.productBloc,
  });

  @override
  State<_CategoryItemsScreenBody> createState() =>
      _CategoryItemsScreenBodyState();
}

class _CategoryItemsScreenBodyState extends State<_CategoryItemsScreenBody> {
  String searchQuery = '';
  ItemAvailabilityFilter selectedFilter = ItemAvailabilityFilter.all;
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200 && !_isLoadingMore) {
      final bloc = context.read<ProductBloc>();
      final state = bloc.state;
      if (state is ProductsLoaded && state.hasMore) {
        _isLoadingMore = true;
        bloc.add(
          LoadMoreAllProducts(
            widget.categoryId,
            limit: ProductBloc.defaultLimit,
            lastProduct: state.products.isNotEmpty ? state.products.last : null,
          ),
        );
      }
    }
  }

  void _onLoadMoreFinished() {
    _isLoadingMore = false;
  }

  void _navigateToEditProduct({required ProductModel editing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: widget.productBloc,
          child: AddProductScreen(
            categoryId: widget.categoryId,
            categoryName: widget.categoryName,
            editing: editing,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      context.read<ProductBloc>().add(DeleteProduct(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(state.message),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductsLoaded) {
                return Text(
                  '${widget.categoryName} (${state.products.length})',
                );
              }
              return Text(widget.categoryName);
            },
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Search and filters
              ProductSearchFilters(
                searchQuery: searchQuery,
                selectedFilter: selectedFilter,
                onSearchChanged: (val) => setState(() => searchQuery = val),
                onFilterChanged: (filter) =>
                    setState(() => selectedFilter = filter),
                categoryId: widget.categoryId,
              ),

              // Products grid
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (_isLoadingMore && state is ProductsLoaded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _isLoadingMore = false;
                        });
                      });
                    }
                    // إذا كان التحميل أولي (ProductsLoading) وليس لدينا منتجات معروضة
                    if (state is ProductsLoading ||
                        state is ProductsSearching) {
                      // استخدم متغير محلي أو تحقق من وجود منتجات في bloc
                      final hasProducts =
                          (context.read<ProductBloc>().state
                              is ProductsLoaded) &&
                          (context.read<ProductBloc>().state as ProductsLoaded)
                              .products
                              .isNotEmpty;
                      if (!hasProducts) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('جاري التحميل...'),
                            ],
                          ),
                        );
                      }
                      // إذا كانت القائمة غير فارغة، لا تعرض أي تحميل هنا
                    } else if (state is ProductsLoaded ||
                        state is ProductsSearchLoaded) {
                      final products = state is ProductsLoaded
                          ? state.products
                          : (state as ProductsSearchLoaded).products;
                      // فلترة حسب التوفر فقط (البحث الشامل يتم من خلال BLoC ويشمل المتوفر وغير المتوفر)
                      final filtered = products.where((product) {
                        final matchesFilter =
                            selectedFilter == ItemAvailabilityFilter.all
                            ? true
                            : selectedFilter == ItemAvailabilityFilter.available
                            ? product.isVisible
                            : !product.isVisible;
                        return matchesFilter;
                      }).toList();

                      if (filtered.isEmpty) {
                        return EmptyProductsView(searchQuery: searchQuery);
                      }

                      // مراقبة انتهاء التحميل
                      if (_isLoadingMore &&
                          !(state is ProductsLoaded ? state.hasMore : false)) {
                        _onLoadMoreFinished();
                      }
                      if (_isLoadingMore &&
                          (state is ProductsLoaded ? state.hasMore : false)) {
                        _onLoadMoreFinished();
                      }

                      return Stack(
                        children: [
                          GridView.builder(
                            controller: _scrollController,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 16.0,
                                  mainAxisSpacing: 16.0,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              return ProductGridItem(
                                key: ValueKey(product.id), // أضف هذا السطر
                                product: product,
                                onTap: () =>
                                    _navigateToEditProduct(editing: product),
                                onDelete: () =>
                                    _showDeleteConfirmation(product),
                              );
                            },
                          ),
                          if ((state is ProductsLoaded
                                  ? state.hasMore
                                  : false) &&
                              _isLoadingMore)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 8,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    } else if (state is ProductsError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: () => context.read<ProductBloc>().add(
                          FetchProducts(widget.categoryId),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: widget.productBloc,
                  child: AddProductScreen(
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryName,
                  ),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'إضافة منتج',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.orangeColor,
        ),
      ),
    );
  }
}
