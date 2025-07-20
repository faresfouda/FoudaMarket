import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fouda_market/components/Button.dart' show Button;
import 'package:fouda_market/theme/appcolors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fouda_market/components/cached_image.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/models/cart_item_model.dart';
import 'package:fouda_market/models/review_model.dart';
import 'package:fouda_market/blocs/cart/index.dart';
import 'package:fouda_market/core/services/review_service.dart';
import 'add_review_screen.dart';
import '../../core/services/product_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/favorites_service.dart';
import 'package:fouda_market/blocs/product/product_bloc.dart';
import 'package:fouda_market/blocs/product/product_event.dart';
import 'package:fouda_market/components/loading_indicator.dart';
import 'package:fouda_market/components/error_view.dart';


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
  static const int _maxQuantity = 99; // حد أقصى معقول للكمية

  // متغير للاهتزاز
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    // بناء قائمة الوحدات: الأساسية أولاً ثم الإضافية
    // التحقق من وجود الوحدة الأساسية في الوحدات الإضافية لتجنب التكرار
    final existingUnits = widget.product.units ?? [];
    final hasPrimaryUnit = existingUnits.any((unit) => unit.isPrimary);
    
    if (hasPrimaryUnit) {
      // إذا كانت الوحدة الأساسية موجودة في الوحدات الإضافية، استخدمها
      units = existingUnits;
    } else {
      // إذا لم تكن موجودة، أضفها في البداية
      units = [
        ProductUnit(
          id: 'main',
          name: widget.product.unit,
          price: widget.product.price,
          originalPrice: widget.product.originalPrice,
          stockQuantity: widget.product.stockQuantity,
          isPrimary: true, // الوحدة الأساسية
          isActive: widget.product.isVisible, // توافر الوحدة الأساسية يعتمد على isVisible
        ),
        ...existingUnits
      ];
    }
    
    // تحميل المراجعات
    _loadReviews();
    _checkUserReview();
    _checkFavorite();
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
          
          // حساب متوسط التقييم
          if (reviews.isNotEmpty) {
            final totalRating = reviews.map((r) => r.rating).reduce((a, b) => a + b);
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
    
    // إذا تم إضافة مراجعة جديدة، أعد تحميل المراجعات
    if (result == true) {
      _loadReviews();
      _checkUserReview();
    }
  }

  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isFav = await FavoritesService().isProductFavorite(user.uid, widget.product.id);
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
      _isFavorite = !_isFavorite; // غيّر الحالة مباشرة
    });
    final bloc = context.read<ProductBloc>();
    if (!_isFavorite) {
      bloc.add(RemoveFromFavorites(user.uid, widget.product.id));
    } else {
      bloc.add(AddToFavorites(user.uid, widget.product.id));
    }
    // await _checkFavorite(); // لا تعيد الفحص فورًا
    if (!mounted) return;
    setState(() { _favoriteLoading = false; });
    _favoriteChanged = true;
  }

  void _shareProduct() {
    final text = '${widget.product.name}\n${widget.product.description ?? ''}\nالسعر: ${widget.product.price.toStringAsFixed(2)} ج.م';
    Share.share(text);
  }

  // دالة للاهتزاز عند الوصول للحد الأقصى
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
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: PageView.builder(
                          itemCount: widget.product.images.length,
                          itemBuilder: (context, index) {
                            return CachedImage(
                              imageUrl: widget.product.images[index],
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      if (widget.product.images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicator(
                              controller: PageController(),
                              count: widget.product.images.length,
                            effect: ExpandingDotsEffect(
                              dotHeight: 8,
                              dotWidth: 8,
                              spacing: 10,
                              expansionFactor: 4,
                              activeDotColor: AppColors.orangeColor,
                              dotColor: AppColors.lightGrayColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.name,
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.grey,
                            ),
                            tooltip: _isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                            onPressed: _favoriteLoading ? null : _toggleFavorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      // وصف المنتج
                      if (widget.product.description != null && widget.product.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            widget.product.description!,
                            style: TextStyle(fontSize: 15.0, color: Colors.grey[700]),
                          ),
                        ),
                      // الكمية المتاحة
                      // احذف هذا السطر:
                      // Text(
                      //   'المتوفر:  {selectedUnit.stockQuantity}  {selectedUnit.name}',
                      //   style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                      // ),
                      const SizedBox(height: 16.0),
                      // اختيار الوحدة
                      if (units.length > 1)
                        _buildExpandableSection(
                          title: 'الأنواع/الكميات',
                          contentWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'اختر الوحدة المناسبة:',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: units.length,
                                  itemBuilder: (context, index) {
                                    final unit = units[index];
                                    final isSelected = index == _selectedUnitIndex;
                                    final isAvailable = unit.isActive;
                                    final isMain = unit.isPrimary;
                                    
                                    return Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: isAvailable ? () {
                                          setState(() {
                                            _selectedUnitIndex = index;
                                            _quantity = _minQuantity; // إعادة تعيين الكمية عند تغيير الوحدة
                                          });
                                        } : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.orangeColor : 
                                                   isAvailable ? Colors.grey[100] : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? AppColors.orangeColor : 
                                                     isAvailable ? Colors.grey[300]! : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    unit.name,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSelected ? Colors.white : 
                                                             isAvailable ? Colors.black : Colors.grey[600],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (isMain) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              if (unit.price != null && unit.originalPrice != null && unit.price != unit.originalPrice)
                                                Text(
                                                  '${unit.price.toStringAsFixed(0)} ج.م',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isSelected ? Colors.white70 : Colors.red,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                              Text(
                                                '${unit.originalPrice?.toStringAsFixed(0) ?? unit.price.toStringAsFixed(0)} ج.م',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? Colors.white : AppColors.orangeColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isAvailable ? Colors.green[100] : Colors.red[100],
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isAvailable ? 'متوفر للطلب' : 'غير متوفر',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAvailable ? Colors.green[700] : Colors.red[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          isExpanded: true,
                          onTap: () {},
                          trailingText: units[_selectedUnitIndex].name,
                        )
                      else
                        // عرض الوحدة الواحدة
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2, color: AppColors.orangeColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'الوحدة المتاحة',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        if (selectedUnit.isPrimary) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.star, color: Colors.amber, size: 16),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${selectedUnit.name} - ${selectedUnit.originalPrice?.toStringAsFixed(0) ?? selectedUnit.price.toStringAsFixed(0)} ج.م',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.orangeColor,
                                      ),
                                    ),
                                    if (selectedUnit.hasDiscount) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'السعر الأصلي: ${selectedUnit.originalPrice!.toStringAsFixed(0)} ج.م',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedUnit.isActive ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  selectedUnit.isActive ? 'متوفر للطلب' : 'غير متوفر',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selectedUnit.isActive ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16.0),
                      // اختيار الكمية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(color: AppColors.orangeColor.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // زر النقصان
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _quantity > _minQuantity 
                                          ? AppColors.orangeColor 
                                          : Colors.grey[100],
                                     borderRadius: const BorderRadius.all(Radius.circular(12)),
                                      boxShadow: _quantity > _minQuantity ? [
                                        BoxShadow(
                                          color: AppColors.orangeColor.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ] : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                                        onTap: _quantity > _minQuantity ? () {
                                          setState(() {
                                            _quantity--;
                                          });
                                        } : null,
                                        child: Icon(
                                          Icons.remove,
                                          color: _quantity > _minQuantity 
                                              ? Colors.white 
                                              : Colors.grey[400],
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // عرض الكمية
                                  Container(
                                    width: 60,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      transform: _isShaking 
                                          ? Matrix4.translationValues(3, 0, 0)
                                          : Matrix4.translationValues(0, 0, 0),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: Text(
                                          '$_quantity',
                                          key: ValueKey(_quantity),
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // زر الزيادة
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _quantity < _maxQuantity 
                                          ? AppColors.orangeColor 
                                          : Colors.grey[100],
                                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                                      boxShadow: _quantity < _maxQuantity ? [
                                        BoxShadow(
                                          color: AppColors.orangeColor.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ] : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                                        onTap: _quantity < _maxQuantity ? () {
                                          setState(() {
                                            _quantity++;
                                          });
                                        } : () {
                                          _shakeQuantity();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('الحد الأقصى للكمية هو 99'),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.add,
                                          color: _quantity < _maxQuantity 
                                              ? Colors.white 
                                              : Colors.grey[400],
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // السعر الإجمالي
                          Flexible(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'السعر الإجمالي',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (selectedUnit.hasDiscount) ...[
                                  Text(
                                    '${(selectedUnit.originalPrice! * _quantity).toStringAsFixed(0)} ج.م',
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    '${(selectedUnit.price * _quantity).toStringAsFixed(0)} ج.م',
                                    key: ValueKey(selectedUnit.price * _quantity),
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.orangeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      // التقييمات
                      _buildExpandableSection(
                        title: 'التقييمات',
                        contentWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // زر إضافة مراجعة
                            if (!_hasUserReviewed)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ElevatedButton.icon(
                                  onPressed: _navigateToAddReview,
                                  icon: const Icon(Icons.rate_review, color: Colors.white),
                                  label: const Text(
                                    'أضف مراجعتك',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),

                            
                            // عرض المراجعات
                            if (_isLoadingReviews)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: LoadingIndicator(),
                                ),
                              )
                            else if (_reviews.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ErrorView(
                                    message: 'لا توجد مراجعات بعد',
                                    onRetry: _loadReviews,
                                  ),
                                ),
                              )
                            else
                              ..._reviews.map((review) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildReviewTile(
                                  review.userName,
                                  review.reviewText,
                                  review.rating,
                                  review.userAvatar,
                                  review.createdAt,
                                ),
                              )).toList(),
                          ],
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
                          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
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
              padding: const EdgeInsets.only(bottom: 40.0, left: 16.0, right: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Button(
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final selectedUnit = units[_selectedUnitIndex];
                      
                      // التحقق من توافر الوحدة المحددة
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
                        productImage: widget.product.images.isNotEmpty ? widget.product.images.first : null,
                        price: selectedUnit.price,
                        quantity: _quantity,
                        unit: selectedUnit.name,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      
                      context.read<CartBloc>().add(AddToCart(cartItem));
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إضافة ${widget.product.name} (${selectedUnit.name}) إلى السلة'),
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
                  },
                  buttonContent: Text(
                    units[_selectedUnitIndex].isActive ? 'اضف للعربة' : 'غير متوفر',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  buttonColor: units[_selectedUnitIndex].isActive ? AppColors.orangeColor : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(String user, String comment, double rating, [String? userAvatar, DateTime? createdAt]) {
    String formatDate(DateTime date) {
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return 'منذ ${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[300],
          backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
          child: userAvatar == null
              ? Text(
            user.isNotEmpty ? user[0] : '?',
            style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                user,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              RatingBarIndicator(
                rating: rating,
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 18.0,
                direction: Axis.horizontal,
              ),
              const SizedBox(height: 4),
              Text(
                comment,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // Helper widget to build expandable sections (Product Detail, Nutritions, Review)
  Widget _buildExpandableSection({
    required String title,
    Widget? contentWidget,
    required bool isExpanded,
    required VoidCallback onTap,
    String? trailingText,
    Widget? trailingWidget,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isExpanded && trailingText != null)
                      Text(
                        trailingText,
                        style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                      ),
                    if (!isExpanded && trailingWidget != null) trailingWidget,
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && contentWidget != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: contentWidget,
          ),
      ],
    );
  }

}

class SimilarProductsSection extends StatefulWidget {
  final String categoryId;
  final String currentProductId;

  const SimilarProductsSection({
    Key? key,
    required this.categoryId,
    required this.currentProductId,
  }) : super(key: key);

  @override
  State<SimilarProductsSection> createState() => _SimilarProductsSectionState();
}

class _SimilarProductsSectionState extends State<SimilarProductsSection> with AutomaticKeepAliveClientMixin {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProductService().getProductsForCategory(widget.categoryId, limit: 10);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // مهم مع keepAlive
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'منتجات مشابهة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.orangeColor),
          ),
        ),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<ProductModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: ErrorView(message: 'لا توجد منتجات مشابهة'));
              }
              final similarProducts = snapshot.data!.where((p) => p.id != widget.currentProductId).toList();
              if (similarProducts.isEmpty) {
                return const Center(child: ErrorView(message: 'لا توجد منتجات مشابهة'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similarProducts.length,
                itemBuilder: (context, index) {
                  final product = similarProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images.first,
                                    width: 160,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 160,
                                    height: 110,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${product.price.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (product.hasDiscount)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                              child: Row(
                                children: [
                                  Text(
                                    '${product.originalPrice?.toStringAsFixed(2) ?? ''} ج.م',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.red,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '-${product.discountPercentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
