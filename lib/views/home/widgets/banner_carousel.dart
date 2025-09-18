import 'package:flutter/material.dart';
import 'package:fouda_market/models/banner_image_model.dart';
import 'package:fouda_market/core/services/banner_service.dart';
import 'package:fouda_market/components/cached_image.dart';
import 'dart:async';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final BannerService _bannerService = BannerService();
  final PageController _pageController = PageController();

  List<BannerImage> _banners = [];
  bool _isLoading = true;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _startAutoScroll() {
    if (_banners.length > 1) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && _banners.isNotEmpty) {
          final nextPage = (_currentPage + 1) % _banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await _bannerService.getActiveBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
        _startAutoScroll(); // بدء الـ autoscroll
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('خطأ في تحميل صور العروض: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200, // إعادة الارتفاع الأصلي
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ), // تقليل الهوامش الجانبية
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Carousel
        Container(
          height: 170, // إعادة الارتفاع الأصلي
          margin: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ), // تقليل الهوامش الجانبية
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              // إعادة بدء الـ autoscroll عند التغيير اليدوي
              _startAutoScroll();
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 2,
                ), // تقليل المسافة بين الصور
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // الصورة
                      CachedImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error, size: 48),
                        ),
                      ),

                      // طبقة شفافة سوداء للقراءة (مخفية لإعطاء مساحة أكبر للصورة)
                      // Container(
                      //   decoration: BoxDecoration(
                      //     gradient: LinearGradient(
                      //       begin: Alignment.topCenter,
                      //       end: Alignment.bottomCenter,
                      //       colors: [
                      //         Colors.transparent,
                      //         Colors.black.withOpacity(0.3),
                      //       ],
                      //     ),
                      //   ),
                      // ),

                      // العنوان مخفي تماماً لإعطاء مساحة أكبر للصورة
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // مؤشرات الصفحات
        if (_banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.orange
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
