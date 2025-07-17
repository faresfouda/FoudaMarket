import 'package:flutter/material.dart';
import '../../devtools/seed_fake_data.dart';
import '../../core/services/review_service.dart';

class AdminDevToolsScreen extends StatefulWidget {
  const AdminDevToolsScreen({Key? key}) : super(key: key);

  @override
  State<AdminDevToolsScreen> createState() => _AdminDevToolsScreenState();
}

class _AdminDevToolsScreenState extends State<AdminDevToolsScreen> {
  bool _isLoading = false;
  bool _isLoadingOffers = false;
  bool _isLoadingTestPrices = false;
  bool _isDeletingProducts = false;
  bool _isDeletingAll = false;
  bool _isLoadingLocalImages = false;
  bool _isLoadingMultiUnits = false;
  bool _isLoadingOrders = false;
  bool _isLoadingReviews = false;
  String? _result;

  Future<void> _seedData() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });
    try {
      await seedFakeCategoriesAndProducts();
      setState(() {
        _result = 'تم إضافة البيانات التجريبية بنجاح!';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إضافة البيانات: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seedOffersAndBestSellers() async {
    setState(() {
      _isLoadingOffers = true;
      _result = null;
    });
    try {
      await seedRealOffersAndBestSellers();
      setState(() {
        _result = 'تم إضافة العروض الخاصة والأكثر مبيعاً بنجاح!';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إضافة العروض: $e';
      });
    } finally {
      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  Future<void> _seedTestPrices() async {
    setState(() {
      _isLoadingTestPrices = true;
      _result = null;
    });
    try {
      await seedTestProductsWithPrices();
      setState(() {
        _result = 'تم إضافة منتجات تجريبية مع أسعار مختلفة بنجاح!';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إضافة المنتجات التجريبية: $e';
      });
    } finally {
      setState(() {
        _isLoadingTestPrices = false;
      });
    }
  }

  Future<void> _deleteAndReseedProducts() async {
    setState(() {
      _isDeletingProducts = true;
      _result = null;
    });
    try {
      await deleteAllProductsAndReseed();
      setState(() {
        _result = 'تم حذف جميع المنتجات وإعادة إضافتها مع أسعار صحيحة بنجاح!';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء حذف وإعادة إضافة المنتجات: $e';
      });
    } finally {
      setState(() {
        _isDeletingProducts = false;
      });
    }
  }

  Future<void> _deleteAllAndReseed() async {
    setState(() {
      _isDeletingAll = true;
      _result = null;
    });
    try {
      await deleteAllCategoriesAndProducts();
      setState(() {
        _result =
            'تم حذف جميع الفئات والمنتجات وإعادة إضافتها مع أسعار صحيحة بنجاح!';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء حذف وإعادة إضافة الفئات والمنتجات: $e';
      });
    } finally {
      setState(() {
        _isDeletingAll = false;
      });
    }
  }

  Future<void> _seedCategoriesWithLocalImages() async {
    setState(() {
      _isLoadingLocalImages = true;
      _result = null;
    });
    try {
      await seedCategoriesWithLocalImages();
      setState(() {
        _result = 'تم إنشاء فئات مع صور محلية أكثر واقعية بنجاح!';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إنشاء الفئات مع الصور المحلية: $e';
      });
    } finally {
      setState(() {
        _isLoadingLocalImages = false;
      });
    }
  }

  Future<void> _seedProductsWithMultipleUnits(int unitCount) async {
    setState(() {
      _isLoadingMultiUnits = true;
      _result = null;
    });
    try {
      await seedProductsWithMultipleUnits(unitCount);
      setState(() {
        _result = 'تم إضافة منتجات ب $unitCount وحدات بنجاح!';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إضافة المنتجات ب $unitCount وحدات: $e';
      });
    } finally {
      setState(() {
        _isLoadingMultiUnits = false;
      });
    }
  }

  Future<void> _seedOrders() async {
    setState(() {
      _isLoadingOrders = true;
      _result = null;
    });
    try {
      await seedFakeOrders();
      setState(() {
        _result = 'تم إنشاء 50 طلب افتراضي بنجاح! يمكنك الآن اختبار نظام إدارة الطلبات.';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إنشاء الطلبات: $e';
      });
    } finally {
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _seedReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _result = null;
    });
    try {
      final reviewService = ReviewService();
      await reviewService.seedFakeReviews();
      setState(() {
        _result = 'تم إنشاء مراجعات وهمية بنجاح! يمكنك الآن اختبار نظام إدارة المراجعات.';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إنشاء المراجعات: $e';
      });
    } finally {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات المطور (DevTools)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _seedData,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('إضافة بيانات تجريبية (20 فئة × 20 منتج)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoadingOffers ? null : _seedOffersAndBestSellers,
              icon: const Icon(Icons.local_offer),
              label: const Text('إضافة عروض خاصة وأكثر مبيعاً'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoadingTestPrices ? null : _seedTestPrices,
              icon: const Icon(Icons.attach_money),
              label: const Text('إضافة منتجات تجريبية مع أسعار'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isDeletingProducts ? null : _deleteAndReseedProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('حذف وإعادة إضافة جميع المنتجات'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isDeletingAll ? null : _deleteAllAndReseed,
              icon: const Icon(Icons.delete_forever),
              label: const Text('حذف وإعادة إضافة الفئات والمنتجات'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoadingLocalImages
                  ? null
                  : _seedCategoriesWithLocalImages,
              icon: const Icon(Icons.image),
              label: const Text('إنشاء فئات مع صور محلية واقعية'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // قسم المنتجات متعددة الوحدات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers, color: Colors.indigo[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'منتجات متعددة الوحدات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إنشاء منتجات ب وحدات متعددة للاختبار',
                    style: TextStyle(fontSize: 14, color: Colors.indigo[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingMultiUnits
                              ? null
                              : () => _seedProductsWithMultipleUnits(2),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('2 وحدات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingMultiUnits
                              ? null
                              : () => _seedProductsWithMultipleUnits(3),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('3 وحدات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingMultiUnits
                              ? null
                              : () => _seedProductsWithMultipleUnits(4),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('4 وحدات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingMultiUnits
                              ? null
                              : () => _seedProductsWithMultipleUnits(5),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('5 وحدات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoadingOrders ? null : _seedOrders,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('إنشاء طلبات افتراضية (50 طلب)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoadingReviews ? null : _seedReviews,
              icon: const Icon(Icons.rate_review),
              label: const Text('إنشاء مراجعات وهمية'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading ||
                _isLoadingOffers ||
                _isLoadingTestPrices ||
                _isDeletingProducts ||
                _isDeletingAll ||
                _isLoadingLocalImages ||
                _isLoadingMultiUnits ||
                _isLoadingOrders ||
                _isLoadingReviews)
              const CircularProgressIndicator(),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(
                _result!,
                style: TextStyle(
                  color: _result!.contains('نجاح') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
