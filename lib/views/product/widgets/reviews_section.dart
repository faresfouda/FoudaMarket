import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fouda_market/models/review_model.dart';
import 'package:fouda_market/models/product_model.dart';
import 'package:fouda_market/components/loading_indicator.dart';
import 'package:fouda_market/components/error_view.dart';
import 'package:fouda_market/theme/appcolors.dart';
import '../add_review_screen.dart';

class ReviewsSection extends StatelessWidget {
  final ProductModel product;
  final List<ReviewModel> reviews;
  final bool isLoadingReviews;
  final double averageRating;
  final bool hasUserReviewed;
  final VoidCallback onReloadReviews;
  final VoidCallback onAddReview;

  const ReviewsSection({
    super.key,
    required this.product,
    required this.reviews,
    required this.isLoadingReviews,
    required this.averageRating,
    required this.hasUserReviewed,
    required this.onReloadReviews,
    required this.onAddReview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // زر إضافة مراجعة
        if (!hasUserReviewed)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: onAddReview,
              icon: const Icon(
                Icons.rate_review,
                color: Colors.white,
              ),
              label: const Text(
                'أضف مراجعتك',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
        if (isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: LoadingIndicator(),
            ),
          )
        else if (reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ErrorView(
                message: 'لا توجد مراجعات بعد',
                onRetry: onReloadReviews,
              ),
            ),
          )
        else
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ReviewTile(review: review),
            ),
          ),
      ],
    );
  }
}

class ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[300],
          backgroundImage: review.userAvatar != null ? NetworkImage(review.userAvatar!) : null,
          child: review.userAvatar == null
              ? Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
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
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(review.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RatingBarIndicator(
                rating: review.rating,
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 18.0,
                direction: Axis.horizontal,
              ),
              const SizedBox(height: 4),
              Text(review.reviewText, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
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
}
