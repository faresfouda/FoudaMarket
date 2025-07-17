import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // إنشاء مراجعة جديدة
  Future<ReviewModel> createReview(ReviewModel review) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newReview = review.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newReview.toJson());
      return newReview;
    } catch (e) {
      throw Exception('فشل في إنشاء المراجعة: $e');
    }
  }

  // الحصول على جميع المراجعات (حد أقصى 10)
  Future<List<ReviewModel>> getAllReviews() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب المراجعات: $e');
    }
  }

  // الحصول على مراجعات حسب الحالة (حد أقصى 10)
  Future<List<ReviewModel>> getReviewsByStatus(ReviewStatus status) async {
    try {
      String statusString;
      switch (status) {
        case ReviewStatus.approved:
          statusString = 'approved';
          break;
        case ReviewStatus.rejected:
          statusString = 'rejected';
          break;
        case ReviewStatus.pending:
        default:
          statusString = 'pending';
          break;
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: statusString)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب المراجعات حسب الحالة: $e');
    }
  }

  // الحصول على مراجعات منتج معين (حد أقصى 10)
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('product_id', isEqualTo: productId)
          .where('status', isEqualTo: 'approved') // فقط المراجعات المقبولة
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      return reviews;
    } catch (e) {
      throw Exception('فشل في جلب مراجعات المنتج: $e');
    }
  }

  // الحصول على مراجعات مستخدم معين (حد أقصى 10)
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب مراجعات المستخدم: $e');
    }
  }

  // تحديث حالة المراجعة
  Future<void> updateReviewStatus(String reviewId, ReviewStatus status, {String? adminNotes}) async {
    try {
      String statusString;
      switch (status) {
        case ReviewStatus.approved:
          statusString = 'approved';
          break;
        case ReviewStatus.rejected:
          statusString = 'rejected';
          break;
        case ReviewStatus.pending:
        default:
          statusString = 'pending';
          break;
      }

      final updateData = {
        'status': statusString,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      await _firestore.collection(_collection).doc(reviewId).update(updateData);
    } catch (e) {
      throw Exception('فشل في تحديث حالة المراجعة: $e');
    }
  }

  // حذف مراجعة
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
    } catch (e) {
      throw Exception('فشل في حذف المراجعة: $e');
    }
  }

  // الحصول على إحصائيات المراجعات
  Future<Map<String, dynamic>> getReviewStats() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      int totalReviews = reviews.length;
      int pendingReviews = reviews.where((r) => r.isPending).length;
      int approvedReviews = reviews.where((r) => r.isApproved).length;
      int rejectedReviews = reviews.where((r) => r.isRejected).length;

      double averageRating = 0;
      if (approvedReviews > 0) {
        final approvedReviewRatings = reviews
            .where((r) => r.isApproved)
            .map((r) => r.rating)
            .toList();
        averageRating = approvedReviewRatings.reduce((a, b) => a + b) / approvedReviewRatings.length;
      }

      return {
        'total_reviews': totalReviews,
        'pending_reviews': pendingReviews,
        'approved_reviews': approvedReviews,
        'rejected_reviews': rejectedReviews,
        'average_rating': averageRating,
      };
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات المراجعات: $e');
    }
  }

  // البحث في المراجعات (حد أقصى 10)
  Future<List<ReviewModel>> searchReviews(String query) async {
    try {
      // البحث في النص
      final textQuerySnapshot = await _firestore
          .collection(_collection)
          .where('review_text', isGreaterThanOrEqualTo: query)
          .where('review_text', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      // البحث في اسم المنتج
      final productQuerySnapshot = await _firestore
          .collection(_collection)
          .where('product_name', isGreaterThanOrEqualTo: query)
          .where('product_name', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      // البحث في اسم المستخدم
      final userQuerySnapshot = await _firestore
          .collection(_collection)
          .where('user_name', isGreaterThanOrEqualTo: query)
          .where('user_name', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      // دمج النتائج وإزالة التكرار
      final allDocs = <String, ReviewModel>{};
      
      for (final doc in textQuerySnapshot.docs) {
        allDocs[doc.id] = ReviewModel.fromJson({...doc.data(), 'id': doc.id});
      }
      
      for (final doc in productQuerySnapshot.docs) {
        allDocs[doc.id] = ReviewModel.fromJson({...doc.data(), 'id': doc.id});
      }
      
      for (final doc in userQuerySnapshot.docs) {
        allDocs[doc.id] = ReviewModel.fromJson({...doc.data(), 'id': doc.id});
      }

      return allDocs.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw Exception('فشل في البحث في المراجعات: $e');
    }
  }

  // التحقق من وجود مراجعة للمستخدم على منتج معين
  Future<bool> hasUserReviewedProduct(String userId, String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .where('product_id', isEqualTo: productId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('فشل في التحقق من وجود مراجعة: $e');
    }
  }

  // الحصول على متوسط تقييم منتج معين
  Future<double> getProductAverageRating(String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.map((r) => r.rating).reduce((a, b) => a + b);
      return totalRating / reviews.length;
    } catch (e) {
      throw Exception('فشل في حساب متوسط تقييم المنتج: $e');
    }
  }

  // إنشاء مراجعات وهمية للاختبار
  Future<void> seedFakeReviews() async {
    try {
      final fakeReviews = [
        ReviewModel(
          id: '',
          userId: 'user1',
          userName: 'سارة أحمد',
          userAvatar: 'https://randomuser.me/api/portraits/women/1.jpg',
          productId: 'product1',
          productName: 'طماطم بلدي',
          productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
          reviewText: 'منتج ممتاز! وسعره مناسب. التسليم كان سريع والجودة رائع. أنصح بالشراء من هذا المتجر',
          rating: 4.0,
          status: ReviewStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
          orderId: 'order1',
        ),
        ReviewModel(
          id: '',
          userId: 'user2',
          userName: 'محمد علي',
          userAvatar: 'https://randomuser.me/api/portraits/men/2.jpg',
          productId: 'product2',
          productName: 'خبز بلدي',
          productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
          reviewText: 'خبز بلدي ممتاز! الجودة، التغليف ممتاز والطعم رائع. سأطلب مرة أخرى بلا تردد.',
          rating: 5.0,
          status: ReviewStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          orderId: 'order2',
        ),
        ReviewModel(
          id: '',
          userId: 'user3',
          userName: 'فاطمة حسن',
          userAvatar: 'https://randomuser.me/api/portraits/women/3.jpg',
          productId: 'product3',
          productName: 'موز بلدي',
          productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
          reviewText: 'الموز لم يكن طازجًا كما هو متوقع. بعض الحبات كانت ناضجة جدًا والتسليم تأخر كثيرًا.',
          rating: 2.0,
          status: ReviewStatus.rejected,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          orderId: 'order3',
        ),
        ReviewModel(
          id: '',
          userId: 'user4',
          userName: 'أحمد محمود',
          userAvatar: 'https://randomuser.me/api/portraits/men/4.jpg',
          productId: 'product2',
          productName: 'خبز بلدي',
          productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
          reviewText: 'خبز بلدي فريش. وصل دافئ والطعم رائع. خدمة التوصيل سريعة ومميزة.',
          rating: 5.0,
          status: ReviewStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          orderId: 'order4',
        ),
      ];

      for (final review in fakeReviews) {
        await createReview(review);
      }
    } catch (e) {
      throw Exception('فشل في إنشاء المراجعات الوهمية: $e');
    }
  }
} 