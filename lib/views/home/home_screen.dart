import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/components/category_card.dart';
import 'package:fouda_market/components/item_container.dart';
import 'package:fouda_market/views/category/category_screen.dart';
import 'package:fouda_market/views/profile/notifications_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/blocs/category/category_bloc.dart';
import 'package:fouda_market/blocs/category/category_event.dart';
import 'package:fouda_market/blocs/category/category_state.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/product/product_event.dart';
import 'package:fouda_market/blocs/product/product_state.dart';
import 'package:fouda_market/models/category_model.dart';
import 'package:fouda_market/models/product_model.dart';
import 'widgets/my_searchbutton.dart';
import 'search_screen.dart';
import 'package:fouda_market/blocs/address/address_bloc.dart';
import 'package:fouda_market/blocs/address/address_event.dart';
import 'package:fouda_market/blocs/address/address_state.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  final PageController _pageController = PageController();
  final List<String> _banners = [
    'assets/home/offerbanner1.jpg',
    'assets/home/offerbanner1.jpg',
    'assets/home/offerbanner1.jpg',
  ];
  Timer? _autoScrollTimer;
  bool _isDataLoaded = false;
  bool _isPageVisible = true;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  bool _isPageActive = true;

  @override
  bool get wantKeepAlive => true;

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _isPageVisible && mounted && _isPageActive) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _banners.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

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
      context.read<ProductBloc>().add(const FetchRecommendedProducts(limit: 10));
      
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
        _isDataLoaded = false;
        _isRefreshing = true;
      });
      
      _loadAllData();
      // إعادة تشغيل التمرير التلقائي
      _autoScrollTimer?.cancel();
      _startAutoScroll();
      
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
    
    if (isVisible && mounted && !_isRefreshing && _isPageActive) {
      // تحديث البيانات عند العودة للصفحة
      // تقليل الوقت المطلوب للتحديث عند العودة من صفحات أخرى
      final now = DateTime.now();
      final shouldRefresh = _lastRefreshTime == null || 
          now.difference(_lastRefreshTime!).inSeconds > 10; // تقليل الوقت إلى 10 ثوان
      
      if (shouldRefresh) {
        Future.delayed(Duration(milliseconds: 200), () {
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
      _startAutoScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل البيانات عند تغيير التبعيات (مثل العودة للصفحة)
    // إعادة تحميل البيانات عند العودة من صفحات أخرى
    if (mounted && !_isRefreshing && _isPageActive) {
      // تحقق من أن البيانات محملة بالفعل
      if (_isDataLoaded) {
        // إعادة تحميل البيانات عند العودة من صفحة أخرى
        // تأخير قليل لتجنب التحديث المتكرر
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted && !_isRefreshing && _isPageActive) {
            _refreshData();
          }
        });
      } else {
        // تحميل البيانات لأول مرة
        _loadInitialData();
      }
    }
    if (mounted) {
      context.read<ProductBloc>().add(const ResetHomeProducts());
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
    // إعادة تحميل البيانات عند العودة للصفحة
    if (mounted && !_isRefreshing) {
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted && _isPageActive && !_isRefreshing) {
          _refreshData();
        }
      });
    }
    if (mounted) {
      context.read<ProductBloc>().add(const ResetHomeProducts());
      context.read<CategoryBloc>().add(const FetchCategories());
      // تحميل العنوان الافتراضي عند العودة للصفحة
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
      }
    }
  }

  @override
  void didPushNext() {
    super.didPushNext();
    _isPageActive = false;
  }

  @override
  void didPop() {
    super.didPop();
    _isPageActive = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    
    return BlocListener<AddressBloc, AddressState>(
      listener: (context, state) {
        if (state is AddressOperationSuccess) {
          // إعادة تحميل العنوان الافتراضي بعد نجاح أي عملية
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
              // انتظار قليل لضمان تحديث البيانات
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildSearchBar(),
                  const SizedBox(height: 18),
                  _BannerCarousel(controller: _pageController, banners: _banners),
                  const SizedBox(height: 18),
                  _buildCategories(),
                  const SizedBox(height: 18),
                  _buildProductSection('عروض خاصة', _getSpecialOffers),
                  const SizedBox(height: 18),
                  _buildProductSection('الأكثر مبيعاً', _getBestSellers),
                  const SizedBox(height: 18),
                  _buildRecommendedSection(),
                  // مساحة إضافية للـ RefreshIndicator
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ); // <-- إغلاق BlocListener هنا
}

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.orangeColor.withValues(alpha: 0.1),
                radius: 20,
                child: Image.asset('assets/home/logo.jpg', height: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فودة ماركت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    BlocBuilder<AddressBloc, AddressState>(
                      builder: (context, state) {
                        print('[DEBUG] BlocBuilder AddressState: ' + state.toString());
                        if (state is DefaultAddressLoaded && state.defaultAddress != null) {
                          print('[DEBUG] BlocBuilder: DefaultAddressLoaded with address: ' + state.defaultAddress!.toString());
                          return GestureDetector(
                            onTap: () => _showAddressSelectionDialog(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: AppColors.orangeColor, size: 16),
                                Flexible(
                                  child: Text(
                                    state.defaultAddress!.name,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[700]),
                              ],
                            ),
                          );
                        } else {
                          print('[DEBUG] BlocBuilder: No default address, state is: ' + state.toString());
                          // إذا لم يكن هناك عنوان افتراضي، اعرض زر لإضافة عنوان
                          return GestureDetector(
                            onTap: () => _showAddressSelectionDialog(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: AppColors.orangeColor, size: 16),
                                Text('إضافة عنوان التوصيل', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[700]),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // مؤشر التحديث
            if (_isRefreshing)
              Container(
                margin: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orangeColor,
                  ),
                ),
              ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: AppColors.orangeColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(child: SearchButton()),
        const SizedBox(width: 10),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.orangeColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: Icon(Icons.tune, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen(openFilterOnStart: true)),
              );
              // إعادة الصفحة الرئيسية لوضعها الطبيعي بعد البحث
              context.read<ProductBloc>().add(const ResetHomeProducts());
              context.read<CategoryBloc>().add(const FetchCategories());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الأقسام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              _buildLoadingIndicator(90),
            ],
          );
        } else if (state is CategoriesLoaded && state.categories.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الأقسام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              _CategoryList(categories: state.categories),
            ],
          );
        } else if (state is CategoriesError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الأقسام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              _buildErrorView('فشل في تحميل الفئات'),
            ],
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildProductSection(String title, List<ProductModel> Function(ProductState) getProducts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, onTap: () {}),
        const SizedBox(height: 10),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            print('HomeScreen BlocBuilder state: ' + state.toString());
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
                return _HorizontalProductList(products: products);
              }
            } else if (state is ProductsLoading) {
              return _buildLoadingIndicator(240);
            } else {
              return _HorizontalProductList(products: []);
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
        Text('موصى به لك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is HomeProductsLoaded) {
              final products = _getRecommendedProducts(state);
              if (state.isLoadingRecommended) {
                return _buildLoadingIndicator(240);
              } else {
                return _HorizontalProductList(products: products);
              }
            } else if (state is ProductsLoading) {
              return _buildLoadingIndicator(240);
            } else {
              return _HorizontalProductList(products: []);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(double height) {
    return SizedBox(
      height: height,
      child: Center(child: CircularProgressIndicator(color: AppColors.orangeColor)),
    );
  }

  Widget _buildErrorView(String message) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                            Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('لا توجد عناوين', style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                                          onPressed: () async {
                              Navigator.pop(context);
                              // تأخير قصير لتجنب مشاكل دورة حياة Widget
                              await Future.delayed(Duration(milliseconds: 100));
                              
                              // التحقق من أن Widget لا يزال موجوداً
                              if (!mounted) return;
                              
                              final result = await Navigator.pushNamed(context, '/delivery-address');
                              
                              // التحقق من أن Widget لا يزال موجوداً قبل استخدام context
                              if (!mounted) return;
                              
                              // إذا تم إرجاع true، فهذا يعني أن هناك تغييراً حدث
                              if (result == true) {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null && mounted) {
                                  // إعادة تحميل العنوان الافتراضي
                                  context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
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
                              address.isDefault ? Icons.star : Icons.location_on,
                              color: address.isDefault ? Colors.orange : Colors.grey,
                            ),
                            title: Text(
                              address.name,
                              style: TextStyle(
                                fontWeight: address.isDefault ? FontWeight.bold : FontWeight.normal,
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
                                context.read<AddressBloc>().add(SetDefaultAddress(user.uid, address.id));
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
                      final result = await Navigator.pushNamed(context, '/delivery-address');
                      
                      // التحقق من أن Widget لا يزال موجوداً قبل استخدام context
                      if (!mounted) return;
                      
                      // إذا تم إرجاع true، فهذا يعني أن هناك تغييراً حدث
                      if (result == true) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && mounted) {
                          // إعادة تحميل العنوان الافتراضي
                          context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
                        }
                      }
                    } catch (e) {
                      print('[DEBUG] Error navigating to delivery-address: $e');
                      // محاولة بديلة باستخدام Navigator.of(context, rootNavigator: true)
                      if (!mounted) return;
                      try {
                        final result = await Navigator.of(context, rootNavigator: true).pushNamed('/delivery-address');
                        if (!mounted) return;
                        if (result == true) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && mounted) {
                            context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
                          }
                        }
                      } catch (e2) {
                        print('[DEBUG] Alternative navigation also failed: $e2');
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
    if (user != null) {
      context.read<AddressBloc>().add(LoadDefaultAddress(user.uid));
    }
  }
}

class _BannerCarousel extends StatelessWidget {
  final PageController controller;
  final List<String> banners;

  const _BannerCarousel({required this.controller, required this.banners});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: PageView.builder(
              controller: controller,
              itemCount: banners.length,
              itemBuilder: (context, index) => Image.asset(banners[index], fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: SmoothPageIndicator(
              controller: controller,
              count: banners.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 4,
                spacing: 10,
                activeDotColor: AppColors.orangeColor,
                dotColor: AppColors.lightGrayColor.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.blackColor)),
        GestureDetector(
          onTap: onTap,
          child: Text('عرض الكل', style: TextStyle(fontSize: 16, color: AppColors.orangeColor)),
        ),
      ],
    );
  }
}

class _HorizontalProductList extends StatelessWidget {
  final List<ProductModel> products;

  const _HorizontalProductList({this.products = const []});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('لا توجد منتجات', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
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
    );
  }

  List<ProductModel> _getDefaultProducts() {
    return [];
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;

  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return SizedBox.shrink();
    }
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          Color bgColor = Colors.white;
          
          if (category.color != null && category.color!.startsWith('#')) {
            try {
              bgColor = Color(int.parse(category.color!.replaceFirst('#', '0xff')));
            } catch (e) {
              bgColor = AppColors.lightGrayColor3;
            }
          }
          
          return CategoryCard(
            imageUrl: category.imageUrl ?? '',
            categoryName: category.name,
            bgColor: bgColor,
            onTap: () async {
              await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => CategoryScreen(
                  categoryName: category.name,
                  categoryId: category.id,
                )),
              );
              // بعد العودة من القسم، أرسل أحداث Bloc لإعادة تحميل المنتجات
              context.read<ProductBloc>().add(const FetchSpecialOffers(limit: 10));
              context.read<ProductBloc>().add(const FetchBestSellers(limit: 10));
              context.read<ProductBloc>().add(const FetchRecommendedProducts(limit: 10));
              // يمكنك أيضاً إعادة تحميل الفئات إذا أردت:
              // context.read<CategoryBloc>().add(const FetchCategories());
            },
          );
        },
      ),
    );
  }

  List<CategoryModel> _getDefaultCategories() {
    return [];
  }
}
