import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';
import '../../components/cached_image.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../core/services/review_service.dart';
import '../../core/services/auth_service.dart';
import '../../components/connection_aware_widget.dart';

class AddReviewScreen extends StatefulWidget {
  final ProductModel product;
  
  const AddReviewScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  
  double _rating = 5.0;
  bool _isSubmitting = false;
  bool _hasUserReviewed = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkUserReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
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
      print('خطأ في التحقق من المراجعة: $e');
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة مراجعة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      // الحصول على بيانات المستخدم
      final userData = await _authService.getUserProfile(user.uid);
      
      final review = ReviewModel(
        id: '',
        userId: user.uid,
        userName: userData?['name'] ?? 'مستخدم',
        userAvatar: userData?['avatarUrl'],
        productId: widget.product.id,
        productName: widget.product.name,
        productImage: widget.product.images.isNotEmpty ? widget.product.images.first : null,
        reviewText: _reviewController.text.trim(),
        rating: _rating,
        status: ReviewStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // إضافة تسجيل للتشخيص
      print('=== Review Debug Info ===');
      print('User ID: ${user.uid}');
      print('User data: $userData');
      print('User role: ${userData?['role']}');
      print('Review data: ${review.toJson()}');
      print('========================');

      await _reviewService.createReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال مراجعتك بنجاح! ستتم مراجعتها قريباً'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // إرجاع true للإشارة إلى نجاح الإضافة
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال المراجعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionAwareWidget(
      onConnectionChanged: (offline) {
        if (_isOffline != offline) {
          setState(() {
            _isOffline = offline;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة مراجعة'),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات المنتج
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    // صورة المنتج
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: widget.product.images.isNotEmpty 
                            ? widget.product.images.first 
                            : '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // معلومات المنتج
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.product.price.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // رسالة إذا كان المستخدم قد راجع من قبل
              if (_hasUserReviewed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لقد قمت بمراجعة هذا المنتج من قبل',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // التقييم بالنجوم
              Text(
                'تقييمك للمنتج',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 40,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${_rating.toInt()} من 5 نجوم',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // نص المراجعة
              Text(
                'مراجعتك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                maxLines: 6,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'اكتب مراجعتك هنا...\n\nمثال:\n- جودة المنتج\n- سرعة التوصيل\n- السعر\n- تجربتك العامة',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                '${_reviewController.text.length}/1000 حرف',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // زر الإرسال
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isSubmitting
                    ? Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'جاري الإرسال...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Button(
                        onPressed: () => _submitReview(),
                        buttonContent: const Text(
                          'إرسال المراجعة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        buttonColor: AppColors.primary,
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // معلومات إضافية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'معلومات مهمة',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ستتم مراجعة تعليقك من قبل الإدارة قبل النشر\n'
                      '• يمكنك مراجعة المنتج مرة واحدة فقط\n'
                      '• المراجعات تساعد العملاء الآخرين في اتخاذ قرار الشراء',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (_isSubmitting || _isOffline) ? null : _submitReview,
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.send),
        ),
      ),
    );
  }
} 