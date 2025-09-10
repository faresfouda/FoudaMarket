import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../devtools/seed_fake_data.dart';
import '../../core/services/review_service.dart';
import '../../core/services/onboarding_service.dart';
import 'banner_management_screen.dart';

class AdminDevToolsScreen extends StatefulWidget {
  const AdminDevToolsScreen({super.key});

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
  bool _isDeletingAllData = false;
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
        _result =
            'تم إنشاء 50 طلب افتراضي بنجاح! يمكنك الآن اختبار نظام إدارة الطلبات.';
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
        _result =
            'تم إنشاء مراجعات وهمية بنجاح! يمكنك الآن اختبار نظام إدارة المراجعات.';
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

  Future<void> _resetOnboarding() async {
    setState(() {
      _result = null;
    });
    try {
      await OnboardingService.resetOnboarding();
      setState(() {
        _result =
            'تم إعادة تعيين Onboarding بنجاح! ستظهر شاشة Onboarding في المرة القادمة.';
      });
    } catch (e) {
      setState(() {
        _result = 'حدث خطأ أثناء إعادة تعيين Onboarding: $e';
      });
    }
  }

  Future<void> _deleteAllFirebaseData() async {
    // عرض تأكيد قبل الحذف
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ تحذير خطير'),
          content: const Text(
            'هل أنت متأكد من حذف جميع البيانات من Firebase؟\n\n'
            'سيتم حذف:\n'
            '• جميع المنتجات\n'
            '• جميع الفئات\n'
            '• جميع الطلبات\n'
            '• جميع المراجعات\n'
            '• جميع المستخدمين (غير الأدمن)\n'
            '• جميع العروض والكوبونات\n\n'
            'هذا الإجراء لا يمكن التراجع عنه!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف الكل'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeletingAllData = true;
      _result = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // حذف جميع الطلبات
      final ordersQuery = await firestore.collection('orders').get();
      for (var doc in ordersQuery.docs) {
        await doc.reference.delete();
      }
      print('تم حذف ${ordersQuery.docs.length} طلب');

      // حذف جميع المراجعات
      final reviewsQuery = await firestore.collection('reviews').get();
      for (var doc in reviewsQuery.docs) {
        await doc.reference.delete();
      }
      print('تم حذف ${reviewsQuery.docs.length} مراجعة');

      // حذف جميع المنتجات
      final productsQuery = await firestore.collection('products').get();
      for (var doc in productsQuery.docs) {
        await doc.reference.delete();
      }
      print('تم حذف ${productsQuery.docs.length} منتج');

      // حذف جميع الفئات
      final categoriesQuery = await firestore.collection('categories').get();
      for (var doc in categoriesQuery.docs) {
        await doc.reference.delete();
      }
      print('تم حذف ${categoriesQuery.docs.length} فئة');

      // حذف جميع العروض (إذا كانت موجودة)
      try {
        final offersQuery = await firestore.collection('offers').get();
        for (var doc in offersQuery.docs) {
          await doc.reference.delete();
        }
        print('تم حذف ${offersQuery.docs.length} عرض');
      } catch (e) {
        print('مجموعة العروض غير موجودة أو لا توجد صلاحيات: $e');
      }

      // حذف جميع الكوبونات (إذا كانت موجودة)
      try {
        final couponsQuery = await firestore.collection('coupons').get();
        for (var doc in couponsQuery.docs) {
          await doc.reference.delete();
        }
        print('تم حذف ${couponsQuery.docs.length} كوبون');
      } catch (e) {
        print('مجموعة الكوبونات غير موجودة أو لا توجد صلاحيات: $e');
      }

      // حذف جميع المستخدمين (غير الأدمن)
      try {
        final usersQuery = await firestore.collection('users').get();
        int deletedUsers = 0;
        for (var doc in usersQuery.docs) {
          final userData = doc.data();
          if (userData['role'] != 'admin') {
            try {
              await doc.reference.delete();
              deletedUsers++;
            } catch (e) {
              print('خطأ في حذف المستخدم ${doc.id}: $e');
            }
          }
        }
        print('تم حذف $deletedUsers مستخدم (غير الأدمن)');
      } catch (e) {
        print('خطأ في الوصول إلى مجموعة المستخدمين: $e');
      }

      setState(() {
        _result =
            '✅ تم حذف جميع البيانات من Firebase بنجاح!\n\n'
            'تم حذف:\n'
            '• ${ordersQuery.docs.length} طلب\n'
            '• ${reviewsQuery.docs.length} مراجعة\n'
            '• ${productsQuery.docs.length} منتج\n'
            '• ${categoriesQuery.docs.length} فئة\n'
            '• العروض والكوبونات (إذا كانت موجودة)\n'
            '• المستخدمين غير الأدمن\n\n'
            'ملاحظة: بعض المجموعات قد تكون غير موجودة أو لا توجد صلاحيات للوصول إليها.';
      });
    } catch (e) {
      setState(() {
        _result = '❌ حدث خطأ أثناء حذف البيانات: $e';
      });
    } finally {
      setState(() {
        _isDeletingAllData = false;
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
            const SizedBox(height: 24),

            // قسم إدارة صور العروض
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'إدارة صور العروض',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إدارة صور العروض التي تظهر للمستخدمين',
                    style: TextStyle(fontSize: 14, color: Colors.orange[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BannerManagementScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('إدارة صور العروض'),
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // قسم حذف البيانات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'حذف البيانات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حذف جميع البيانات من Firebase',
                    style: TextStyle(fontSize: 14, color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isDeletingAllData
                        ? null
                        : _deleteAllFirebaseData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('حذف جميع البيانات'),
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // قسم إعادة تعيين Onboarding
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.purple[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'إعادة تعيين Onboarding',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إعادة تعيين حالة Onboarding لظهورها مرة أخرى',
                    style: TextStyle(fontSize: 14, color: Colors.purple[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _resetOnboarding,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تعيين Onboarding'),
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
                ],
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
                _isLoadingReviews ||
                _isDeletingAllData)
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
