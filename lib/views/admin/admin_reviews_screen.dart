import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';
import '../../components/search_field.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

enum ReviewStatus { all, pending, approved, rejected }

class _Review {
  final String customerName;
  final String customerAvatar;
  final String productName;
  final String productImage;
  final String reviewText;
  final double rating;
  final String date;
  final ReviewStatus status;

  const _Review({
    required this.customerName,
    required this.customerAvatar,
    required this.productName,
    required this.productImage,
    required this.reviewText,
    required this.rating,
    required this.date,
    required this.status,
  });
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  ReviewStatus selectedStatus = ReviewStatus.all;
  final TextEditingController searchController = TextEditingController();

  final List<_Review> allReviews = [
    _Review(
      customerName: 'سارة أحمد',
      customerAvatar: 'https://randomuser.me/api/portraits/women/1.jpg',
      productName: 'طماطم بلدي',
      productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
      reviewText: 'منتج ممتاز! وسعره مناسب. التسليم كان سريع والجودة رائعة. أنصح بالشراء من هذا المتجر',
      rating: 4.0,
      date: 'منذ أسبوع',
      status: ReviewStatus.pending,
    ),
    _Review(
      customerName: 'محمد علي',
      customerAvatar: 'https://randomuser.me/api/portraits/men/2.jpg',
      productName: 'خبز بلدي',
      productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
      reviewText: 'خبز بلدي ممتاز! الجودة، التغليف ممتاز والطعم رائع. سأطلب مرة أخرى بلا تردد.',
      rating: 5.0,
      date: 'منذ 3 أيام',
      status: ReviewStatus.approved,
    ),
    _Review(
      customerName: 'فاطمة حسن',
      customerAvatar: 'https://randomuser.me/api/portraits/women/3.jpg',
      productName: 'موز بلدي',
      productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
      reviewText: 'الموز لم يكن طازجًا كما هو متوقع. بعض الحبات كانت ناضجة جدًا والتسليم تأخر كثيرًا.',
      rating: 2.0,
      date: 'منذ أسبوع',
      status: ReviewStatus.rejected,
    ),
    _Review(
      customerName: 'أحمد محمود',
      customerAvatar: 'https://randomuser.me/api/portraits/men/4.jpg',
      productName: 'خبز بلدي',
      productImage: 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
      reviewText: 'خبز بلدي فريش. وصل دافئ والطعم رائع. خدمة التوصيل سريعة ومميزة.',
      rating: 5.0,
      date: 'منذ أسبوع',
      status: ReviewStatus.pending,
    ),
  ];

  List<_Review> get filteredReviews {
    String query = searchController.text.trim();
    return allReviews.where((review) {
      bool matchesStatus = selectedStatus == ReviewStatus.all || review.status == selectedStatus;
      bool matchesQuery = query.isEmpty ||
        review.customerName.contains(query) ||
        review.productName.contains(query) ||
        review.reviewText.contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  Color statusColor(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.pending:
        return Colors.amber[700]!;
      case ReviewStatus.approved:
        return Colors.green;
      case ReviewStatus.rejected:
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  String statusText(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.pending:
        return 'بانتظار الموافقة';
      case ReviewStatus.approved:
        return 'مقبول';
      case ReviewStatus.rejected:
        return 'مرفوض';
      default:
        return 'الكل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Search bar
              SearchField(
                controller: searchController,
                hintText: 'البحث في المراجعات...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // Status filter row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...ReviewStatus.values.map((status) {
                      if (status == ReviewStatus.all) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(statusText(status)),
                            selected: selectedStatus == status,
                            onSelected: (_) => setState(() => selectedStatus = status),
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: selectedStatus == status ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(statusText(status)),
                          selected: selectedStatus == status,
                          onSelected: (_) => setState(() => selectedStatus = status),
                          selectedColor: statusColor(status),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selectedStatus == status ? Colors.white : statusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Reviews list
              Expanded(
                child: ListView.separated(
                  itemCount: filteredReviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final review = filteredReviews[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor(review.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusText(review.status),
                                  style: TextStyle(
                                    color: statusColor(review.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(review.customerAvatar),
                                    radius: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  review.productImage,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(review.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) => Icon(
                                          i < review.rating ? Icons.star : Icons.star_border,
                                          color: AppColors.primary,
                                          size: 18,
                                        )),
                                        const SizedBox(width: 6),
                                        Text(review.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(review.date, style: TextStyle(color: AppColors.lightGrayColor2, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review.reviewText, style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (review.status == ReviewStatus.pending)
                                ...[
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () {},
                                      icon: const Icon(Icons.check, size: 18, color: Colors.white),
                                      label: const Text('قبول', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () {},
                                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
                                      label: const Text('رفض', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ]
                              else
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      elevation: 0,
                                    ),
                                    onPressed: null,
                                    icon: Icon(
                                      review.status == ReviewStatus.approved ? Icons.check : Icons.close,
                                      size: 18,
                                      color: review.status == ReviewStatus.approved ? Colors.green : Colors.red,
                                    ),
                                    label: Text(
                                      statusText(review.status),
                                      style: TextStyle(
                                        color: review.status == ReviewStatus.approved ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 