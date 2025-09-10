import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../components/item_container.dart';
import '../../theme/appcolors.dart';
import 'search_filter_sheet.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  final bool openFilterOnStart;
  const SearchScreen({super.key, this.openFilterOnStart = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openFilterOnStart) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SearchFilterSheet(
            selectedCategory: null,
            selectedBrand: null,
            onApply:
                (List<String> categories, double minPrice, double maxPrice) {
                  setState(() {
                    _selectedCategories = categories;
                    _minPrice = minPrice;
                    _maxPrice = maxPrice;
                  });
                  context.read<ProductBloc>().add(
                    SearchVisibleProducts(
                      _searchQuery,
                      categories: categories,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                    ),
                  );
                },
          ),
        );
      }

      // تحميل حالة المفضلة للمستخدم الحالي
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<ProductBloc>().add(LoadFavorites(user.uid));
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    // لا تستخدم context هنا لتفادي الخطأ
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    // إلغاء البحث السابق
    _debounceTimer?.cancel();

    // تأخير البحث لمدة 300 مللي ثانية لتجنب البحث المتكرر
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (value.trim().isNotEmpty ||
          _selectedCategories.isNotEmpty ||
          _minPrice != 0 ||
          _maxPrice != 1000) {
        context.read<ProductBloc>().add(
          SearchVisibleProducts(
            value.trim(),
            categories: _selectedCategories,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
          ),
        );
      } else {
        context.read<ProductBloc>().add(const SearchVisibleProducts(''));
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _searchQuery = '';
    });
    context.read<ProductBloc>().add(const SearchVisibleProducts(''));
  }

  void _clearSearchAndPop() {
    _clearSearch();
    // إزالة إعادة تحميل المنتجات لتجنب اختفائها مؤقتاً
    // البيانات محفوظة بالفعل في HomeScreen
    Navigator.pop(context);
  }

  void _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterSheet(
        selectedCategory: null,
        selectedBrand: null,
        onApply: (List<String> categories, double minPrice, double maxPrice) {
          setState(() {
            _selectedCategories = categories;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
          });
          context.read<ProductBloc>().add(
            SearchVisibleProducts(
              _searchQuery,
              categories: categories,
              minPrice: minPrice,
              maxPrice: maxPrice,
            ),
          );
        },
      ),
    );
  }

  List<String> _selectedCategories = [];
  double _minPrice = 0;
  double _maxPrice = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _clearSearchAndPop,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          SvgPicture.asset(
                            'assets/home/search.svg',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onChanged: _onSearchChanged,
                              textDirection: TextDirection.rtl,
                              decoration: InputDecoration(
                                hintText: 'ابحث عن منتج...',
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.black),
                      onPressed: _openFilterSheet,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductsSearching) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.orangeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              color: AppColors.orangeColor,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'جاري البحث...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'البحث عن "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (state is ProductsSearchLoaded) {
                    final products = state.products;

                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'لا توجد نتائج لـ "${state.query}"',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'جرب البحث بكلمات مختلفة أو تصفح الأقسام',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.refresh),
                              label: const Text('مسح البحث'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orangeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'نتائج البحث لـ "${state.query}"',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.orangeColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${products.length} منتج',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.orangeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ListenableBuilder(
                                  listenable: context
                                      .read<ProductBloc>()
                                      .favoritesNotifier,
                                  builder: (context, child) {
                                    final bloc = context.read<ProductBloc>();
                                    final isFavorite = bloc.favoritesNotifier
                                        .isProductFavorite(product.id);

                                    return ProductCard(
                                      product: product,
                                      isFavorite: isFavorite,
                                      onFavoritePressed: () {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          if (isFavorite) {
                                            context.read<ProductBloc>().add(
                                              RemoveFromFavorites(
                                                user.uid,
                                                product.id,
                                              ),
                                            );
                                          } else {
                                            context.read<ProductBloc>().add(
                                              AddToFavorites(
                                                user.uid,
                                                product.id,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      onAddPressed:
                                          () {}, // سيتم التعامل معه داخل ProductCard
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
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ في البحث',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_searchQuery.trim().isNotEmpty) {
                                // استخدام البحث للمنتجات المتوفرة فقط للمستخدمين
                                context.read<ProductBloc>().add(
                                  SearchVisibleProducts(_searchQuery.trim()),
                                );
                              }
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  // الحالة الافتراضية - عرض رسالة ترحيب
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.orangeColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search,
                            size: 48,
                            color: AppColors.orangeColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ابحث عن المنتجات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'اكتب اسم المنتج للبدء في البحث\nأو استخدم الفلاتر للبحث المتقدم',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Container(
                        //   padding: const EdgeInsets.all(16),
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey[50],
                        //     borderRadius: BorderRadius.circular(12),
                        //     border: Border.all(color: Colors.grey[200]!),
                        //   ),
                        //   // child: Column(
                        //   //   children: [
                        //   //     const Text(
                        //   //       'نصائح للبحث:',
                        //   //       style: TextStyle(
                        //   //         fontSize: 14,
                        //   //         fontWeight: FontWeight.bold,
                        //   //         color: Colors.grey,
                        //   //       ),
                        //   //     ),
                        //   //     const SizedBox(height: 8),
                        //   //     const Text(
                        //   //       '• اكتب اسم المنتج بالكامل أو جزء منه\n• جرب البحث باللغة العربية أو الإنجليزية\n• استخدم الفلاتر للبحث في فئة محددة',
                        //   //       style: TextStyle(
                        //   //         fontSize: 12,
                        //   //         color: Colors.grey,
                        //   //       ),
                        //   //       textAlign: TextAlign.center,
                        //   //     ),
                        //   //   ],
                        //   // ),
                        // ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
