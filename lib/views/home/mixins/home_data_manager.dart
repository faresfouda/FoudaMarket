import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/blocs/category/category_bloc.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/address/address_bloc.dart';
import 'package:fouda_market/blocs/category/category_event.dart';
import 'package:fouda_market/blocs/product/product_event.dart';
import 'package:fouda_market/blocs/address/address_event.dart';

/// Mixin لإدارة تحميل البيانات في الشاشة الرئيسية
mixin HomeDataManager<T extends StatefulWidget> on State<T> {
  bool _isDataLoaded = false;
  bool _isPageVisible = true;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  bool _isPageActive = true;
  bool _isInitialLoad = true;

  // Getters
  bool get isDataLoaded => _isDataLoaded;
  bool get isPageVisible => _isPageVisible;
  bool get isRefreshing => _isRefreshing;
  DateTime? get lastRefreshTime => _lastRefreshTime;
  bool get isPageActive => _isPageActive;
  bool get isInitialLoad => _isInitialLoad;

  // Setters
  set isDataLoaded(bool value) => _isDataLoaded = value;
  set isPageVisible(bool value) => _isPageVisible = value;
  set isRefreshing(bool value) => _isRefreshing = value;
  set lastRefreshTime(DateTime? value) => _lastRefreshTime = value;
  set isPageActive(bool value) => _isPageActive = value;
  set isInitialLoad(bool value) => _isInitialLoad = value;

  /// تحميل البيانات الأولية
  void loadInitialData() {
    if (!_isDataLoaded && mounted && !_isRefreshing && _isPageActive) {
      loadAllData();
      setState(() {
        _isDataLoaded = true;
      });
    }
  }

  /// تحميل جميع البيانات
  void loadAllData() {
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

  /// تحديث البيانات
  void refreshData() {
    if (mounted && !_isRefreshing && _isPageActive) {
      setState(() {
        _isRefreshing = true;
      });

      loadAllData();

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

  /// التعامل مع تغيير رؤية الصفحة
  void handlePageVisibilityChange(bool isVisible) {
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
            refreshData();
          }
        });
      }
    }
  }

  /// التعامل مع العودة من صفحة أخرى
  void handlePopNext() {
    _isPageActive = true;

    // Only refresh data if it's been a significant amount of time since last update
    // Don't automatically reload when returning from category screens
    if (mounted && !_isRefreshing) {
      final now = DateTime.now();
      final shouldRefresh = _lastRefreshTime == null || 
          now.difference(_lastRefreshTime!).inMinutes > 5; // Increase to 5 minutes to reduce unnecessary refreshes

      if (shouldRefresh) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted && _isPageActive && !_isRefreshing) {
            // Only load favorites, don't refresh all data
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              context.read<ProductBloc>().add(LoadFavorites(user.uid));
            }
          }
        });
      }
      
      // Just rebuild the UI without triggering any bloc events
      setState(() {});
    }
  }
}