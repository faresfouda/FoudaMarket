import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouda_market/theme/appcolors.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/cart/index.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../components/item_container.dart';
import '../../views/product/product_screen.dart';
import 'widgets/product_favourite.dart';
import '../../services/firebase_service.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  final Set<String> selected = {};
  String? currentUserId;
  Future<List<ProductModel>>? _favoriteProductsFuture;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // التحقق من وجود المفضلة المحملة مسبقاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
        final bloc = context.read<ProductBloc>();
        final existingFavorites = bloc.favoritesNotifier.favoriteProductIds;
        
        if (existingFavorites.isNotEmpty) {
          // إذا كانت المفضلة محملة مسبقاً، استخدمها مباشرة
          _favoriteProductsFuture = _getFavoriteProducts();
        } else {
          // إذا لم تكن محملة، قم بتحميلها
      _loadFavorites();
        }
      });
    } else {
      // إذا لم يكن المستخدم مسجل دخوله، عرض رسالة بعد بناء الواجهة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تسجيل الدخول لعرض المفضلة'),
            backgroundColor: Colors.orange,
          ),
        );
    });
    }
  }

  void _loadFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      
      // التحقق من وجود المفضلة المحملة مسبقاً
      final bloc = context.read<ProductBloc>();
      final existingFavorites = bloc.favoritesNotifier.favoriteProductIds;
      
      if (existingFavorites.isNotEmpty) {
        // إذا كانت المفضلة محملة مسبقاً، استخدمها مباشرة
        _favoriteProductsFuture = _getFavoriteProducts();
      } else {
        // إذا لم تكن محملة، قم بتحميلها
      context.read<ProductBloc>().add(LoadFavorites(user.uid));
        _favoriteProductsFuture = _getFavoriteProducts();
      }
    }
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (selected.contains(productId)) {
        selected.remove(productId);
      } else {
        selected.add(productId);
      }
    });
  }

  void _refreshFavorites() {
    final bloc = context.read<ProductBloc>();
    final currentFavorites = bloc.favoritesNotifier.favoriteProductIds;
    
    // إذا لم تكن هناك منتجات مفضلة، لا تقم بإعادة التحميل
    if (currentFavorites.isNotEmpty) {
      setState(() {
        _favoriteProductsFuture = _getFavoriteProducts();
      });
    }
  }

  void _addSelectedToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isAddingToCart = true;
      });

      try {
      // نحتاج لجلب منتجات المفضلة من الخدمة
      final favoriteProducts = await FirebaseService().getFavoriteProducts(user.uid);
      
      for (String productId in selected) {
        final product = favoriteProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => ProductModel(
            id: productId,
            name: 'منتج غير معروف',
            images: [],
            price: 0,
            unit: '',
            categoryId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        // تحديد الوحدة المناسبة للإضافة
        String selectedUnit;
        double selectedPrice;
        
        if (product.units != null && product.units!.isNotEmpty) {
          // البحث عن الوحدة الأساسية أولاً
          final primaryUnit = product.units!.firstWhere(
            (unit) => unit.isPrimary,
            orElse: () => product.units!.first,
          );
          selectedUnit = primaryUnit.name;
          selectedPrice = primaryUnit.price;
        } else {
          // استخدام الوحدة الأساسية للمنتج
          selectedUnit = product.unit;
          selectedPrice = product.price;
        }
        
        final cartItem = CartItemModel(
          id: '',
          userId: user.uid,
          productId: product.id,
          productName: product.name,
          productImage: product.images.isNotEmpty ? product.images.first : null,
          price: selectedPrice,
          quantity: 1,
          unit: selectedUnit,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        context.read<CartBloc>().add(AddToCart(cartItem));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة ${selected.length} منتج إلى السلة'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        selected.clear();
      });
        _refreshFavorites();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إضافة المنتجات إلى السلة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isAddingToCart = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListenableBuilder(
        listenable: context.read<ProductBloc>().favoritesNotifier,
        builder: (context, child) {
          // استخدام cache بدلاً من state للتحقق من المفضلة
          final bloc = context.read<ProductBloc>();
          final favorites = bloc.favoritesNotifier.favoriteProductIds; // استخدام notifier
          
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منتجات في المفضلة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف منتجات إلى المفضلة لتظهر هنا',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // جلب المنتجات من cache أو Firebase
          return FutureBuilder<List<ProductModel>>(
            future: _favoriteProductsFuture ?? _getFavoriteProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.orangeColor),
                      SizedBox(height: 16),
                      Text('جاري تحميل المفضلة...'),
                    ],
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ في تحميل المفضلة',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isAddingToCart ? null : _loadFavorites,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              
              final favoriteProducts = snapshot.data ?? [];
              
              if (favoriteProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد منتجات في المفضلة',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أضف منتجات إلى المفضلة لتظهر هنا',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: favoriteProducts.length,
                      itemBuilder: (context, index) {
                        final product = favoriteProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: SizedBox(
                            height: 100,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.grey.shade200, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.orangeColor.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Selection checkbox and favorite button
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: selected.contains(product.id),
                                              onChanged: _isAddingToCart ? null : (val) {
                                                _toggleSelection(product.id);
                                              },
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              activeColor: AppColors.orangeColor,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            const SizedBox(width: 10),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(16),
                                                onTap: _isAddingToCart ? null : () {
                                                  if (currentUserId != null) {
                                                    context.read<ProductBloc>().add(
                                                      RemoveFromFavorites(currentUserId!, product.id),
                                                    );
                                                    _refreshFavorites();
                                                  }
                                                },
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.07),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Product info
                                      Expanded(
                                        child: InkWell(
                                          onTap: _isAddingToCart ? null : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProductDetailScreen(product: product),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textDirection: TextDirection.rtl,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                product.unit ?? 'وحدة',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.lightGrayColor2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  if (product.originalPrice != null && product.originalPrice! > product.price)
                                                    Text(
                                                      '${product.originalPrice!.toStringAsFixed(2)} ج.م',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  if (product.originalPrice != null && product.originalPrice! > product.price)
                                                    const SizedBox(width: 8),
                                                  Text(
                                                    '${product.price.toStringAsFixed(2)} ج.م',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.orangeColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Product image
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: product.images.isNotEmpty
                                              ? Image.network(
                                                  product.images.first,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons.image, color: Colors.grey),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, color: Colors.grey),
                                                ),
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
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Future<List<ProductModel>> _getFavoriteProducts() async {
    final bloc = context.read<ProductBloc>();
    final favoriteIds = bloc.favoritesNotifier.favoriteProductIds;
    final products = <ProductModel>[];

    // إذا لم تكن هناك منتجات مفضلة، ارجع قائمة فارغة
    if (favoriteIds.isEmpty) {
      return products;
    }

    // جلب المنتجات من كاش الـ Bloc أولاً (من HomeProductsLoaded)
    List<ProductModel> cachedProducts = [];
    final state = bloc.state;
    if (state is HomeProductsLoaded) {
      cachedProducts = [
        ...state.specialOffers,
        ...state.bestSellers,
        ...state.recommendedProducts,
      ];
    }

    for (final productId in favoriteIds) {
      // البحث في الكاش أولاً
      final cachedList = cachedProducts.where((p) => p.id == productId).toList();
      if (cachedList.isNotEmpty && cachedList.first.isVisible) {
        products.add(cachedList.first);
      } else {
        // إذا لم يكن في الكاش، جلب من Firebase
        try {
          final product = await FirebaseService().getProduct(productId);
          if (product != null && product.isVisible) {
            products.add(product);
          }
        } catch (_) {
          // تجاهل الخطأ ولا تضف المنتج
          print('Failed to load product $productId from Firebase');
        }
      }
    }
    return products;
  }

  Widget _buildBottomNavigationBar() {
    return ListenableBuilder(
      listenable: context.read<ProductBloc>().favoritesNotifier,
      builder: (context, child) {
        final bloc = context.read<ProductBloc>();
        final favorites = bloc.favoritesNotifier.favoriteProductIds;
        
        // إذا لم تكن هناك منتجات مفضلة، لا تعرض الزر
        if (favorites.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (selected.isEmpty || _isAddingToCart) ? null : () {
                  _addSelectedToCart();
                  setState(() {}); // تحديث النص
                },
                child: _isAddingToCart
                    ? Row(
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
                          const SizedBox(width: 12),
                          const Text(
                            'جاري الإضافة...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        selected.isEmpty 
                            ? 'إضافة المحدد إلى السلة' 
                            : 'إضافة ${selected.length} منتج إلى السلة',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
