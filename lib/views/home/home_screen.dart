import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/blocs/category/category_bloc.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/address/address_bloc.dart';
import 'widgets/header.dart';
import 'widgets/search_bar.dart' as custom_widgets;
import 'widgets/banner_carousel.dart';
import 'widgets/section_header.dart';
import 'widgets/category_list.dart';
import 'package:fouda_market/components/loading_indicator.dart';
import 'package:fouda_market/components/error_view.dart';
import 'package:fouda_market/blocs/category/category_event.dart';
import 'package:fouda_market/blocs/product/product_event.dart';
import 'package:fouda_market/blocs/product/product_state.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/blocs/address/address_state.dart';
import 'package:fouda_market/blocs/address/address_event.dart';
import 'widgets/horizontal_product_list.dart';
import 'screens/special_offers_screen.dart';
import 'screens/best_sellers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  bool _isDataLoaded = false;
  bool _isPageVisible = true;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  bool _isPageActive = true;
  bool _isInitialLoad = true;

  @override
  bool get wantKeepAlive => true;

  void _loadInitialData() {
    if (!_isDataLoaded && mounted && !_isRefreshing && _isPageActive) {
      _loadAllData();
      setState(() {
        _isDataLoaded = true;
      });
    }
  }

  void _loadAllData() {
    try {
      if (!mounted || !_isPageActive) return;

      // تحميل البيانات الأولية للشاشة الرئيسية
      context.read<ProductBloc>().add(const FetchSpecialOffers(limit: 10));
      context.read<CategoryBloc>().add(const FetchCategories());
      context.read<ProductBloc>().add(const FetchBestSellers(limit: 10));
      context.read<ProductBloc>().add(
        const FetchRecommendedProducts(limit: 10),
      );

      // تحميل حالة المفضلة للمستخدم الحالي
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<ProductBloc>().add(LoadFavorites(user.uid));
        // تحميل العنوان الافتراضي للمستخدم
        context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
      }
    } catch (e) {
      print('Error loading data: $e');
      // إعادة تعيين حالة التحديث في حالة الخطأ
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _refreshData() {
    if (mounted && !_isRefreshing && _isPageActive) {
      setState(() {
        _isRefreshing = true;
      });

      _loadAllData();

      // تحديث وقت آخر تحديث
      _lastRefreshTime = DateTime.now();

      // إعادة تعيين حالة التحديث بعد فترة
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    }
  }

  void _handlePageVisibilityChange(bool isVisible) {
    setState(() {
      _isPageVisible = isVisible;
    });

    if (isVisible && mounted && !_isRefreshing && _isPageActive && !_isInitialLoad) {
      // تحديث البيانات عند العودة للصفحة فقط إذا مر وقت كافٍ
      final now = DateTime.now();
      final shouldRefresh =
          _lastRefreshTime == null ||
          now.difference(_lastRefreshTime!).inMinutes > 2; // زيادة الوقت إلى دقيقتين

      if (shouldRefresh) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && _isPageVisible && !_isRefreshing && _isPageActive) {
            _refreshData();
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      setState(() {
        _isInitialLoad = false;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل البيانات فقط في التحميل الأولي
    if (_isInitialLoad && mounted && !_isRefreshing && _isPageActive) {
      if (!_isDataLoaded) {
        _loadInitialData();
      }
    }
    // إزالة استدعاء ResetHomeProducts من هنا لتجنب إعادة التحميل المفرطة
    if (mounted && _isInitialLoad) {
      context.read<CategoryBloc>().add(const FetchCategories());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _handlePageVisibilityChange(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _handlePageVisibilityChange(false);
        break;
      case AppLifecycleState.hidden:
        _handlePageVisibilityChange(false);
        break;
    }
  }

  @override
  void didPush() {
    super.didPush();
    _isPageActive = true;
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _isPageActive = true;

    // تحديث المفضلة فقط دون إعادة تحميل جميع البيانات (مثل صفحة المنتج)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<ProductBloc>().add(LoadFavorites(user.uid));
    }

    // إعادة بناء الصفحة بدون إعادة تحميل البيانات
    setState(() {});

    // إزالة جميع استدعاءات ResetHomeProducts و FetchSpecialOffers وغيرها
    // لأنها تسبب اختفاء المنتجات مؤقتاً

    // تحديث العنوان فقط
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
      }
    }
  }


  @override
  void didPop() {
    super.didPop();
    _isPageActive = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is FavoritesUpdated) {
          setState(() {}); // إعادة بناء الصفحة عند تحديث المفضلة
        }
      },
      child: BlocListener<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state is AddressOperationSuccess) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
            }
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.whiteColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                if (!_isRefreshing) {
                  _refreshData();
                  await Future.delayed(Duration(milliseconds: 800));
                }
              },
              color: AppColors.orangeColor,
              backgroundColor: Colors.white,
              strokeWidth: 3.0,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Header(),
                      const SizedBox(height: 18),
                      custom_widgets.SearchBar(),
                      const SizedBox(height: 18),
                      const BannerCarousel(),
                      const SizedBox(height: 18),
                      CategoryListWidget(),
                      const SizedBox(height: 18),
                      _buildProductSection('عروض خاصة', _getSpecialOffers),
                      const SizedBox(height: 18),
                      _buildProductSection('الأكثر مبيعاً', _getBestSellers),
                      const SizedBox(height: 18),
                      _buildRecommendedSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection(
    String title,
    List<ProductModel> Function(ProductState) getProducts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onTap: () {
            if (title == 'عروض خاصة') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpecialOffersScreen(),
                ),
              );
            } else if (title == 'الأكثر مبيعاً') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BestSellersScreen(),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            print('HomeScreen BlocBuilder state: $state');
            if (state is HomeProductsLoaded) {
              final products = getProducts(state);
              final isLoading = title == 'عروض خاصة'
                  ? state.isLoadingSpecialOffers
                  : title == 'الأكثر مبيعاً'
                  ? state.isLoadingBestSellers
                  : false;

              if (isLoading) {
                return _buildLoadingIndicator(240);
              } else {
                return HorizontalProductList(products: products);
              }
            } else if (state is ProductsLoading) {
              return _buildLoadingIndicator(240);
            } else {
              return HorizontalProductList(products: []);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'موصى به لك',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is HomeProductsLoaded) {
              final products = _getRecommendedProducts(state);
              if (state.isLoadingRecommended) {
                return _buildLoadingIndicator(240);
              } else {
                return HorizontalProductList(products: products);
              }
            } else if (state is ProductsLoading) {
              return _buildLoadingIndicator(240);
            } else {
              return HorizontalProductList(products: []);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(double height) {
    return SizedBox(height: height, child: const LoadingIndicator());
  }

  Widget _buildErrorView(String message) {
    return SizedBox(height: 90, child: ErrorView(message: message));
  }

  List<ProductModel> _getSpecialOffers(ProductState state) {
    if (state is HomeProductsLoaded) return state.specialOffers;
    if (state is SpecialOffersLoaded) return state.products;
    return [];
  }

  List<ProductModel> _getBestSellers(ProductState state) {
    if (state is HomeProductsLoaded) return state.bestSellers;
    if (state is BestSellersLoaded) return state.products;
    return [];
  }

  List<ProductModel> _getRecommendedProducts(ProductState state) {
    if (state is HomeProductsLoaded) return state.recommendedProducts;
    if (state is RecommendedProductsLoaded) return state.products;
    return [];
  }

  void _showAddressSelectionDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // أرسل حدث تحميل العناوين عند فتح الـ bottom sheet
    context.read<AddressBloc>().add(LoadAddresses(user.uid));

    await showModalBottomSheet(
      context: Navigator.of(context, rootNavigator: true).context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'اختر عنوان التوصيل',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Addresses list
            Expanded(
              child: BlocBuilder<AddressBloc, AddressState>(
                builder: (context, state) {
                  if (state is AddressesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AddressesLoaded) {
                    final addresses = state.addresses;
                    if (addresses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد عناوين',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                // تأخير قصير لتجنب مشاكل دورة حياة Widget
                                await Future.delayed(
                                  Duration(milliseconds: 100),
                                );

                                // التحقق من أن Widget لا يزال موجوداً
                                if (!mounted) return;

                                final result = await Navigator.pushNamed(
                                  context,
                                  '/delivery-address',
                                );

                                // التحقق من أن Widget لا يزال موجوداً قبل استخدام context
                                if (!mounted) return;

                                // إذا تم إرجاع true، فهذا يعني أن هناك تغييراً حدث
                                if (result == true) {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null && mounted) {
                                    // إعادة تحميل العنوان الافتراضي
                                    context.read<AddressBloc>().add(
                                      LoadDefaultAddress(user.uid),
                                    );
                                  }
                                }
                              },
                              child: const Text('إضافة عنوان جديد'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              address.isDefault
                                  ? Icons.star
                                  : Icons.location_on,
                              color: address.isDefault
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            title: Text(
                              address.name,
                              style: TextStyle(
                                fontWeight: address.isDefault
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(address.address),
                                if (address.isDefault)
                                  Text(
                                    'العنوان الافتراضي',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: address.isDefault
                                ? const Icon(Icons.check, color: Colors.orange)
                                : null,
                            onTap: () {
                              if (!address.isDefault) {
                                context.read<AddressBloc>().add(
                                  SetDefaultAddress(user.uid, address.id),
                                );
                              }
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  } else if (state is AddressesError) {
                    return Center(child: Text(state.message));
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            // Add new address button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // تأخير قصير لتجنب مشاكل دورة حياة Widget
                    await Future.delayed(Duration(milliseconds: 100));

                    // التحقق من أن Widget لا يزال موجوداً
                    if (!mounted) return;

                    try {
                      final result = await Navigator.pushNamed(
                        context,
                        '/delivery-address',
                      );

                      // التحقق من أن Widget لا يزال موجوداً قبل استخدام context
                      if (!mounted) return;

                      // إذا تم إرجاع true، فهذا يعني أن هناك تغييراً حدث
                      if (result == true) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && mounted) {
                          // إعادة تحميل العنوان الافتراضي
                          context.read<AddressBloc>().add(
                            LoadDefaultAddress(user.uid),
                          );
                        }
                      }
                    } catch (e) {
                      print('[DEBUG] Error navigating to delivery-address: $e');
                      // محاولة بديلة باستخدام Navigator.of(context, rootNavigator: true)
                      if (!mounted) return;
                      try {
                        final result = await Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed('/delivery-address');
                        if (!mounted) return;
                        if (result == true) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && mounted) {
                            context.read<AddressBloc>().add(
                              LoadDefaultAddress(user.uid),
                            );
                          }
                        }
                      } catch (e2) {
                        print(
                          '[DEBUG] Alternative navigation also failed: $e2',
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إضافة عنوان جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // بعد إغلاق الـ bottom sheet، أعد تحميل العنوان الافتراضي
    context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
  }
}
