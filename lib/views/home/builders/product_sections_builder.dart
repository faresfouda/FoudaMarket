import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/product/product_state.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/components/loading_indicator.dart';
import '../../../blocs/product/product_event.dart';
import '../widgets/section_header.dart';
import '../widgets/horizontal_product_list.dart';
import '../screens/special_offers_screen.dart';
import '../screens/best_sellers_screen.dart';

/// Widget لبناء أقسام المنتجات في الشاشة الرئيسية
class ProductSectionsBuilder {
  /// بناء قسم منتجات عام
  static Widget buildProductSection(
    BuildContext context,
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

            // التحقق من حالة التحميل أولاً
            if (state is ProductsLoading) {
              return _buildLoadingIndicator(240);
            }

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
                // عرض المنتجات حتى لو كانت القائمة فارغة، بدلاً من إعادة التحميل
                return HorizontalProductList(products: products);
              }
            } else {
              // محاولة إعادة تحميل البيانات فقط في حالة عدم وجود حالة صالحة
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  _retryLoadData(context, title);
                }
              });
              return _buildLoadingIndicator(240);
            }
          },
        ),
      ],
    );
  }

  /// بناء قسم المنتجات الموصى بها
  static Widget buildRecommendedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'موصى به لك',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductsLoading) {
              return _buildLoadingIndicator(240);
            }

            if (state is HomeProductsLoaded) {
              final products = _getRecommendedProducts(state);
              if (state.isLoadingRecommended) {
                return _buildLoadingIndicator(240);
              } else {
                // عرض المنتجات حتى لو كانت القائمة فارغة، بدلاً من إعادة التحميل
                return HorizontalProductList(products: products);
              }
            } else {
              // محاولة إعادة تحميل البيانات فقط في حالة عدم وجود حالة صالحة
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  _retryLoadData(context, 'موصى به لك');
                }
              });
              return _buildLoadingIndicator(240);
            }
          },
        ),
      ],
    );
  }

  /// إعادة محاولة تحميل البيانات
  static void _retryLoadData(BuildContext context, String title) {
    try {
      if (title == 'عروض خاصة') {
        context.read<ProductBloc>().add(const FetchSpecialOffers(limit: 10));
      } else if (title == 'الأكثر مبيعاً') {
        context.read<ProductBloc>().add(const FetchBestSellers(limit: 10));
      } else if (title == 'موصى به لك') {
        context.read<ProductBloc>().add(const FetchRecommendedProducts(limit: 10));
      }
    } catch (e) {
      print('Error retrying to load data for $title: $e');
    }
  }

  /// بناء مؤشر التحميل
  static Widget _buildLoadingIndicator(double height) {
    return SizedBox(height: height, child: const LoadingIndicator());
  }

  /// الحصول على العروض الخاصة
  static List<ProductModel> getSpecialOffers(ProductState state) {
    if (state is HomeProductsLoaded) return state.specialOffers;
    if (state is SpecialOffersLoaded) return state.products;
    return [];
  }

  /// الحصول على الأكثر مبيعاً
  static List<ProductModel> getBestSellers(ProductState state) {
    if (state is HomeProductsLoaded) return state.bestSellers;
    if (state is BestSellersLoaded) return state.products;
    return [];
  }

  /// الحصول على المنتجات الموصى بها
  static List<ProductModel> _getRecommendedProducts(ProductState state) {
    if (state is HomeProductsLoaded) return state.recommendedProducts;
    if (state is RecommendedProductsLoaded) return state.products;
    return [];
  }
}
