import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/blocs/category/category_bloc.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/address/address_bloc.dart';
import 'package:fouda_market/blocs/category/category_event.dart';
import 'package:fouda_market/blocs/product/product_state.dart';
import 'package:fouda_market/blocs/address/address_state.dart';
import 'package:fouda_market/blocs/address/address_event.dart';

// الواجهات والمكونات
import 'widgets/header.dart';
import 'widgets/search_bar.dart' as custom_widgets;
import 'widgets/banner_carousel.dart';
import 'widgets/category_list.dart';

// الملفات المنفصلة الجديدة
import 'mixins/home_data_manager.dart';
import 'builders/product_sections_builder.dart';
import 'widgets/address_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware, HomeDataManager {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInitialData();
      isInitialLoad = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل البيانات فقط في التحميل الأولي
    if (isInitialLoad && mounted && !isRefreshing && isPageActive) {
      if (!isDataLoaded) {
        loadInitialData();
      }
    }
    // تحميل الفئات في التحميل الأولي
    if (mounted && isInitialLoad) {
      context.read<CategoryBloc>().add(const FetchCategories());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        handlePageVisibilityChange(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        handlePageVisibilityChange(false);
        break;
      case AppLifecycleState.hidden:
        handlePageVisibilityChange(false);
        break;
    }
  }

  @override
  void didPush() {
    super.didPush();
    isPageActive = true;
  }

  @override
  void didPopNext() {
    super.didPopNext();
    handlePopNext();
  }

  @override
  void didPop() {
    super.didPop();
    isPageActive = false;
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
                if (!isRefreshing) {
                  refreshData();
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
                      ProductSectionsBuilder.buildProductSection(
                        context,
                        'عروض خاصة',
                        ProductSectionsBuilder.getSpecialOffers,
                      ),
                      const SizedBox(height: 18),
                      ProductSectionsBuilder.buildProductSection(
                        context,
                        'الأكثر مبيعاً',
                        ProductSectionsBuilder.getBestSellers,
                      ),
                      const SizedBox(height: 18),
                      ProductSectionsBuilder.buildRecommendedSection(context),
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

  /// عرض حوار اختيار العنوان
  void showAddressSelectionDialog() {
    AddressSelector.showAddressSelectionDialog(context);
  }
}
