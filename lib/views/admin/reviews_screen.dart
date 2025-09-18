import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';
import '../../components/search_field.dart';
import '../../components/cached_image.dart';
import '../../models/review_model.dart';
import '../../core/services/review_service.dart';
import '../../core/services/auth_service.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

enum FilterStatus { all, pending, approved, rejected }

class _ReviewsScreenState extends State<ReviewsScreen> {
  FilterStatus selectedStatus = FilterStatus.all;
  final TextEditingController searchController = TextEditingController();
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();

  List<ReviewModel> _allReviews = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  ReviewModel? _lastReview;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _allReviews = [];
        _hasMore = true;
        _lastReview = null;
      });
    }
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final reviews = await _reviewService.getAllReviewsPaginated(
        limit: _pageSize,
      );
      if (mounted) {
        setState(() {
          _allReviews = reviews;
          _isLoading = false;
          _hasMore = reviews.length == _pageSize;
          _lastReview = reviews.isNotEmpty ? reviews.last : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final moreReviews = await _reviewService.getAllReviewsPaginated(
        limit: _pageSize,
        lastReview: _lastReview,
      );
      if (mounted) {
        setState(() {
          _allReviews.addAll(moreReviews);
          _hasMore = moreReviews.length == _pageSize;
          _isLoadingMore = false;
          if (moreReviews.isNotEmpty) {
            _lastReview = moreReviews.last;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreReviews();
    }
  }

  List<ReviewModel> get filteredReviews {
    String query = searchController.text.trim();
    return _allReviews.where((review) {
      bool matchesStatus =
          selectedStatus == FilterStatus.all ||
          (selectedStatus == FilterStatus.pending &&
              review.status == ReviewStatus.pending) ||
          (selectedStatus == FilterStatus.approved &&
              review.status == ReviewStatus.approved) ||
          (selectedStatus == FilterStatus.rejected &&
              review.status == ReviewStatus.rejected);

      bool matchesQuery =
          query.isEmpty ||
          review.userName.contains(query) ||
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
    }
  }

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

  Future<ReviewStatus?> showStatusBottomSheet(
    BuildContext context,
    ReviewStatus currentStatus,
  ) async {
    final List<ReviewStatus> statusOptions = [
      ReviewStatus.pending,
      ReviewStatus.approved,
      ReviewStatus.rejected,
    ];
    final Map<ReviewStatus, IconData> statusIcons = {
      ReviewStatus.pending: Icons.hourglass_top,
      ReviewStatus.approved: Icons.check_circle,
      ReviewStatus.rejected: Icons.cancel,
    };
    final Map<ReviewStatus, Color> statusColors = {
      ReviewStatus.pending: Colors.amber[700]!,
      ReviewStatus.approved: Colors.green,
      ReviewStatus.rejected: Colors.red,
    };
    return await showModalBottomSheet<ReviewStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'تغيير حالة المراجعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...statusOptions.map(
              (option) => ListTile(
                leading: Icon(statusIcons[option], color: statusColors[option]),
                title: Text(
                  statusText(option),
                  style: TextStyle(
                    color: option == currentStatus
                        ? statusColors[option]
                        : Colors.black,
                    fontWeight: option == currentStatus
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: option == currentStatus
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
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
              // Header
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
                    ...FilterStatus.values.map((status) {
                      String statusLabel;
                      Color statusColorValue;

                      switch (status) {
                        case FilterStatus.all:
                          statusLabel = 'الكل';
                          statusColorValue = AppColors.primary;
                          break;
                        case FilterStatus.pending:
                          statusLabel = 'بانتظار الموافقة';
                          statusColorValue = Colors.amber[700]!;
                          break;
                        case FilterStatus.approved:
                          statusLabel = 'مقبول';
                          statusColorValue = Colors.green;
                          break;
                        case FilterStatus.rejected:
                          statusLabel = 'مرفوض';
                          statusColorValue = Colors.red;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(statusLabel),
                          selected: selectedStatus == status,
                          onSelected: (_) =>
                              setState(() => selectedStatus = status),
                          selectedColor: statusColorValue,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selectedStatus == status
                                ? Colors.white
                                : statusColorValue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Reviews list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'خطأ في تحميل المراجعات',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadReviews(refresh: true),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : filteredReviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مراجعات',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200 &&
                              !_isLoadingMore &&
                              _hasMore) {
                            _loadMoreReviews();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          itemCount:
                              filteredReviews.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == filteredReviews.length &&
                                _isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor(
                                            review.status,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                            backgroundImage:
                                                review.userAvatar != null
                                                ? NetworkImage(
                                                    review.userAvatar!,
                                                  )
                                                : null,
                                            radius: 16,
                                            child: review.userAvatar == null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            review.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      CachedImage(
                                        imageUrl: review.productImage ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.productName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                ...List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < review.rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: AppColors.primary,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  review.rating.toString(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatDate(review.createdAt),
                                        style: TextStyle(
                                          color: AppColors.lightGrayColor2,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    review.reviewText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: statusColor(
                                              review.status,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final newStatus =
                                                await showStatusBottomSheet(
                                                  context,
                                                  review.status,
                                                );
                                            if (newStatus != null &&
                                                newStatus != review.status) {
                                              try {
                                                // الحصول على معلومات المسؤول
                                                final adminInfo =
                                                    await _authService
                                                        .getCurrentAdminInfo();
                                                if (adminInfo == null) {
                                                  throw Exception(
                                                    'غير مصرح لك بتحديث حالة المراجعة',
                                                  );
                                                }

                                                await _reviewService
                                                    .updateReviewStatus(
                                                      review.id,
                                                      newStatus,
                                                      adminId: adminInfo['id']!,
                                                      adminName:
                                                          adminInfo['name'],
                                                    );

                                                // تحديث القائمة المحلية
                                                setState(() {
                                                  final idx = _allReviews
                                                      .indexWhere(
                                                        (r) =>
                                                            r.id == review.id,
                                                      );
                                                  if (idx != -1) {
                                                    _allReviews[idx] = review
                                                        .copyWith(
                                                          status: newStatus,
                                                          updatedAt:
                                                              DateTime.now(),
                                                        );
                                                  }
                                                });

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'تم تغيير حالة المراجعة إلى ${statusText(newStatus)}',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'خطأ في تحديث الحالة: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'تغيير الحالة',
                                            style: TextStyle(
                                              color: Colors.white,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
