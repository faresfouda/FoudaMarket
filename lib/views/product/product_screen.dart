import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fouda_market/components/Button.dart' show Button;
import 'package:fouda_market/theme/appcolors.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/models/cart_item_model.dart';
import 'package:fouda_market/models/review_model.dart';
import 'package:fouda_market/blocs/cart/index.dart';
import 'package:fouda_market/core/services/review_service.dart';
import 'add_review_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/favorites_service.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/product/product_event.dart';

// Import the new widgets
import 'widgets/product_image_section.dart';
import 'widgets/product_header.dart';
import 'widgets/unit_selection_widget.dart';
import 'widgets/quantity_selector.dart';
import 'widgets/total_price_display.dart';
import 'widgets/reviews_section.dart';
import 'widgets/similar_products_section.dart';
import 'widgets/expandable_section.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedUnitIndex = 0;
  late List<ProductUnit> units;
  bool _reviewsExpanded = false;

  // متغيرات المراجعات
  final ReviewService _reviewService = ReviewService();
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;
  bool _hasUserReviewed = false;
  bool _isFavorite = false;
  bool _favoriteLoading = false;
  bool _favoriteChanged = false;

  // ثوابت للكمية
  static const int _minQuantity = 1;
  static const int _maxQuantity = 99;

  // متغير للاهتزاز
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _initializeUnits();
    _loadReviews();
    _checkUserReview();
    _checkFavorite();
  }

  void _initializeUnits() {
    final existingUnits = widget.product.units ?? [];
    final hasPrimaryUnit = existingUnits.any((unit) => unit.isPrimary);

    if (hasPrimaryUnit) {
      units = existingUnits;
    } else {
      units = [
        ProductUnit(
          id: 'main',
          name: widget.product.unit,
          price: widget.product.price,
          originalPrice: widget.product.originalPrice,
          stockQuantity: widget.product.stockQuantity,
          isPrimary: true,
          isActive: widget.product.isVisible,
        ),
        ...existingUnits,
      ];
    }
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoadingReviews = true;
      });

      final reviews = await _reviewService.getProductReviews(widget.product.id);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;

          if (reviews.isNotEmpty) {
            final totalRating = reviews
                .map((r) => r.rating)
                .reduce((a, b) => a + b);
            _averageRating = totalRating / reviews.length;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _checkUserReview() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final hasReviewed = await _reviewService.hasUserReviewedProduct(
          user.uid,
          widget.product.id,
        );

        if (mounted) {
          setState(() {
            _hasUserReviewed = hasReviewed;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _navigateToAddReview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(product: widget.product),
      ),
    );

    if (result == true) {
      _loadReviews();
      _checkUserReview();
    }
  }

  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isFav = await FavoritesService().isProductFavorite(
        user.uid,
        widget.product.id,
      );
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _favoriteLoading = true;
      _isFavorite = !_isFavorite;
    });

    final bloc = context.read<ProductBloc>();
    if (!_isFavorite) {
      bloc.add(RemoveFromFavorites(user.uid, widget.product.id));
    } else {
      bloc.add(AddToFavorites(user.uid, widget.product.id));
    }

    if (!mounted) return;
    setState(() {
      _favoriteLoading = false;
    });
    _favoriteChanged = true;
  }

  void _shareProduct() {
    final text =
        '${widget.product.name}\n${widget.product.description ?? ''}\nالسعر: ${widget.product.price.toStringAsFixed(2)} ج.م';
    Share.share(text);
  }

  void _shakeQuantity() {
    setState(() {
      _isShaking = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isShaking = false;
        });
      }
    });
  }

  void _onQuantityChanged(int newQuantity) {
    setState(() {
      _quantity = newQuantity;
    });
  }

  void _onMaxQuantityReached() {
    _shakeQuantity();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الحد الأقصى للكمية هو 99'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onUnitSelected(int index) {
    setState(() {
      _selectedUnitIndex = index;
      _quantity = _minQuantity;
    });
  }

  void _addToCart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final selectedUnit = units[_selectedUnitIndex];

      if (!selectedUnit.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedUnit.name} غير متوفر حالياً'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      final cartItem = CartItemModel(
        id: '',
        userId: user.uid,
        productId: widget.product.id,
        productName: widget.product.name,
        productImage: widget.product.images.isNotEmpty
            ? widget.product.images.first
            : null,
        price: selectedUnit.originalPrice ?? selectedUnit.price,
        quantity: _quantity,
        unit: selectedUnit.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<CartBloc>().add(AddToCart(cartItem));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إضافة ${widget.product.name} (${selectedUnit.name}) إلى السلة',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUnit = units[_selectedUnitIndex];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context, _favoriteChanged),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            tooltip: 'مشاركة المنتج',
            onPressed: _shareProduct,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32.0),
                // صور المنتج
                ProductImageSection(product: widget.product),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج والمفضلة
                      ProductHeader(
                        product: widget.product,
                        isFavorite: _isFavorite,
                        favoriteLoading: _favoriteLoading,
                        onFavoritePressed: _toggleFavorite,
                      ),
                      const SizedBox(height: 4.0),
                      // وصف المنتج
                      if (widget.product.description != null &&
                          widget.product.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            widget.product.description!,
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16.0),
                      // اختيار الوحدة
                      if (units.length > 1)
                        ExpandableSection(
                          title: 'الأنواع/الكميات',
                          contentWidget: UnitSelectionWidget(
                            units: units,
                            selectedUnitIndex: _selectedUnitIndex,
                            onUnitSelected: _onUnitSelected,
                          ),
                          isExpanded: true,
                          onTap: () {},
                          trailingText: units[_selectedUnitIndex].name,
                        )
                      else
                        UnitSelectionWidget(
                          units: units,
                          selectedUnitIndex: _selectedUnitIndex,
                          onUnitSelected: _onUnitSelected,
                        ),
                      const SizedBox(height: 16.0),
                      // اختيار الكمية والسعر الإجمالي
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: QuantitySelector(
                              quantity: _quantity,
                              minQuantity: _minQuantity,
                              maxQuantity: _maxQuantity,
                              onQuantityChanged: _onQuantityChanged,
                              onMaxQuantityReached: _onMaxQuantityReached,
                              isShaking: _isShaking,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            flex: 1,
                            child: TotalPriceDisplay(
                              selectedUnit: selectedUnit,
                              quantity: _quantity,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      // التقييمات
                      ExpandableSection(
                        title: 'التقييمات',
                        contentWidget: ReviewsSection(
                          product: widget.product,
                          reviews: _reviews,
                          isLoadingReviews: _isLoadingReviews,
                          averageRating: _averageRating,
                          hasUserReviewed: _hasUserReviewed,
                          onReloadReviews: _loadReviews,
                          onAddReview: _navigateToAddReview,
                        ),
                        isExpanded: _reviewsExpanded,
                        onTap: () {
                          setState(() {
                            _reviewsExpanded = !_reviewsExpanded;
                          });
                        },
                        trailingWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_reviews.isNotEmpty) ...[
                              Text(
                                '${_reviews.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            RatingBarIndicator(
                              rating: _averageRating,
                              itemBuilder: (context, _) =>
                                  const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 20.0,
                              direction: Axis.horizontal,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      // قسم المنتجات المشابهة
                      SimilarProductsSection(
                        categoryId: widget.product.categoryId,
                        currentProductId: widget.product.id,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // زر إضافة للعربة
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 40.0,
                left: 16.0,
                right: 16.0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Button(
                  onPressed: _addToCart,
                  buttonContent: Text(
                    units[_selectedUnitIndex].isActive
                        ? 'اضف للعربة'
                        : 'غير متوفر',
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  buttonColor: units[_selectedUnitIndex].isActive
                      ? AppColors.orangeColor
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
