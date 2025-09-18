import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

Future<void> seedFakeCategoriesAndProducts() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  // بيانات افتراضية للفئات
  final categoryNames = [
    'مشروبات',
    'حلويات',
    'مخبوزات',
    'خضروات',
    'فواكه',
    'ألبان',
    'لحوم',
    'أسماك',
    'معلبات',
    'تسالي',
    'منتجات تنظيف',
    'منتجات عناية',
    'مكسرات',
    'بهارات',
    'زيوت',
    'أرز ومكرونة',
    'منتجات أطفال',
    'معلبات عصائر',
    'منتجات مجمدة',
    'منتجات عضوية',
  ];

  for (int i = 0; i < 20; i++) {
    final catId = 'cat${i + 1}';
    final catName = categoryNames[i % categoryNames.length];
    final catColor =
        '#${random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final catImage = 'https://picsum.photos/seed/category$i/200/200';
    final now = DateTime.now();

    // إنشاء نموذج الفئة باستخدام CategoryModel
    final categoryModel = CategoryModel(
      id: catId,
      name: catName,
      imageUrl: catImage,
      color: catColor,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    // إضافة الفئة باستخدام toJson() لضمان التنسيق الصحيح
    await firestore
        .collection('categories')
        .doc(catId)
        .set(categoryModel.toJson());

    // إضافة 20 منتج لكل فئة
    for (int j = 0; j < 20; j++) {
      final prodId = 'prod_${catId}_$j';
      final prodName = '$catName منتج ${j + 1}';
      final prodImage = 'https://picsum.photos/seed/${catId}_$j/400/400';
      final price = 10 + random.nextInt(90); // من 10 إلى 100
      final stock = 10 + random.nextInt(90);
      final isOffer = random.nextBool();
      final isBestSeller = random.nextBool();
      final unit = ['قطعة', 'علبة', 'كجم', 'لتر'][random.nextInt(4)];

      // إضافة سعر أصلي للعروض
      double? originalPrice;
      if (isOffer) {
        originalPrice =
            price.toDouble() + (10 + random.nextInt(20)); // سعر أعلى من 10-30
      }

      // إنشاء نموذج المنتج باستخدام ProductModel
      final productModel = ProductModel(
        id: prodId,
        name: prodName,
        description: 'وصف افتراضي للمنتج $prodName',
        images: [prodImage],
        price: price.toDouble(),
        originalPrice: originalPrice,
        unit: unit,
        categoryId: catId,
        isSpecialOffer: isOffer,
        isBestSeller: isBestSeller,
        isVisible: true,
        stockQuantity: stock,
        createdAt: now,
        updatedAt: now,
      );

      // إضافة المنتج باستخدام toJson() لضمان التنسيق الصحيح
      await firestore
          .collection('products')
          .doc(prodId)
          .set(productModel.toJson());
    }
  }
  print('تم إضافة 20 فئة وكل فئة بها 20 منتج بنجاح!');
}

Future<void> seedRealOffersAndBestSellers() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final now = DateTime.now();

  // بيانات حقيقية للعروض الخاصة
  final specialOffers = [
    {
      'name': 'موز عضوي طازج',
      'description': 'موز عضوي طازج من أفضل المزارع، غني بالبوتاسيوم والألياف',
      'price': 25.0,
      'originalPrice': 35.0,
      'unit': '١ كجم',
      'categoryId': 'cat5', // فواكه
      'image': 'https://picsum.photos/seed/banana_organic/400/400',
    },
    {
      'name': 'تفاح أحمر مستورد',
      'description': 'تفاح أحمر مستورد من أفضل الأصناف، مقرمش وحلو المذاق',
      'price': 45.0,
      'originalPrice': 60.0,
      'unit': '٢ كجم',
      'categoryId': 'cat5', // فواكه
      'image': 'https://picsum.photos/seed/apple_red/400/400',
    },
    {
      'name': 'برتقال عصير طازج',
      'description': 'برتقال عصير طازج، غني بفيتامين سي ومثالي للعصائر',
      'price': 30.0,
      'originalPrice': 40.0,
      'unit': '١.٥ كجم',
      'categoryId': 'cat5', // فواكه
      'image': 'https://picsum.photos/seed/orange_juice/400/400',
    },
    {
      'name': 'طماطم بلدي طازجة',
      'description': 'طماطم بلدي طازجة من المزارع المحلية، طعمها طبيعي',
      'price': 20.0,
      'originalPrice': 28.0,
      'unit': '١ كجم',
      'categoryId': 'cat4', // خضروات
      'image': 'https://picsum.photos/seed/tomato_fresh/400/400',
    },
    {
      'name': 'خيار طازج عضوي',
      'description': 'خيار طازج عضوي، مقرمش ومنعش، مثالي للسلطات',
      'price': 15.0,
      'originalPrice': 22.0,
      'unit': '٥٠٠ جرام',
      'categoryId': 'cat4', // خضروات
      'image': 'https://picsum.photos/seed/cucumber_organic/400/400',
    },
  ];

  // بيانات حقيقية للأكثر مبيعاً
  final bestSellers = [
    {
      'name': 'أرز بسمتي هندي',
      'description': 'أرز بسمتي هندي عالي الجودة، حبة طويلة ورائحة مميزة',
      'price': 85.0,
      'unit': '٢ كجم',
      'categoryId': 'cat16', // أرز ومكرونة
      'image': 'https://picsum.photos/seed/rice_basmati_old/400/400',
    },
    {
      'name': 'زيت زيتون بكر ممتاز',
      'description': 'زيت زيتون بكر ممتاز من أفضل المزارع، طعمه طبيعي',
      'price': 120.0,
      'unit': 'لتر',
      'categoryId': 'cat15', // زيوت
      'image': 'https://picsum.photos/seed/olive_oil_old/400/400',
    },
    {
      'name': 'جبنة شيدر قوية',
      'description': 'جبنة شيدر قوية النكهة، مثالية للطبخ والشطائر',
      'price': 65.0,
      'unit': '٢٥٠ جرام',
      'categoryId': 'cat6', // ألبان
      'image': 'https://picsum.photos/seed/cheese_cheddar/400/400',
    },
    {
      'name': 'لحم بقري طازج',
      'description': 'لحم بقري طازج من أفضل الجزارين، عالي الجودة',
      'price': 180.0,
      'unit': 'كجم',
      'categoryId': 'cat7', // لحوم
      'image': 'https://picsum.photos/seed/beef_fresh/400/400',
    },
    {
      'name': 'سمك بلطي طازج',
      'description': 'سمك بلطي طازج من البحيرات المحلية، طعمه مميز',
      'price': 95.0,
      'unit': 'كجم',
      'categoryId': 'cat8', // أسماك
      'image': 'https://picsum.photos/seed/fish_tilapia_old/400/400',
    },
  ];

  // إضافة العروض الخاصة
  for (int i = 0; i < specialOffers.length; i++) {
    final offer = specialOffers[i];
    final prodId = 'special_offer_$i';

    final productModel = ProductModel(
      id: prodId,
      name: offer['name'] as String,
      description: offer['description'] as String,
      images: [offer['image'] as String],
      price: offer['price'] as double,
      originalPrice: offer['originalPrice'] as double,
      unit: offer['unit'] as String,
      categoryId: offer['categoryId'] as String,
      isSpecialOffer: true,
      isBestSeller: false,
      isVisible: true,
      stockQuantity: 50 + random.nextInt(100),
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  // إضافة الأكثر مبيعاً
  for (int i = 0; i < bestSellers.length; i++) {
    final seller = bestSellers[i];
    final prodId = 'best_seller_$i';

    final productModel = ProductModel(
      id: prodId,
      name: seller['name'] as String,
      description: seller['description'] as String,
      images: [seller['image'] as String],
      price: seller['price'] as double,
      unit: seller['unit'] as String,
      categoryId: seller['categoryId'] as String,
      isSpecialOffer: false,
      isBestSeller: true,
      isVisible: true,
      stockQuantity: 30 + random.nextInt(70),
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  print('تم إضافة 5 عروض خاصة و 5 منتجات من الأكثر مبيعاً بنجاح!');
}

Future<void> seedTestProductsWithPrices() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final now = DateTime.now();

  // منتجات تجريبية مع أسعار مختلفة
  final testProducts = [
    {
      'name': 'منتج بدون سعر',
      'description': 'منتج للاختبار بدون سعر',
      'price': 0.0,
      'originalPrice': null,
      'unit': 'قطعة',
      'categoryId': 'cat1',
      'image': 'https://picsum.photos/seed/test_no_price/400/400',
    },
    {
      'name': 'منتج بسعر عادي',
      'description': 'منتج بسعر عادي بدون خصم',
      'price': 50.0,
      'originalPrice': null,
      'unit': 'علبة',
      'categoryId': 'cat2',
      'image': 'https://picsum.photos/seed/test_normal_price/400/400',
    },
    {
      'name': 'منتج مع خصم',
      'description': 'منتج مع خصم واضح',
      'price': 30.0,
      'originalPrice': 50.0,
      'unit': 'كجم',
      'categoryId': 'cat3',
      'image': 'https://picsum.photos/seed/test_discount/400/400',
    },
    {
      'name': 'منتج بسعر مرتفع',
      'description': 'منتج بسعر مرتفع للاختبار',
      'price': 150.0,
      'originalPrice': null,
      'unit': 'لتر',
      'categoryId': 'cat4',
      'image': 'https://picsum.photos/seed/test_high_price/400/400',
    },
  ];

  // إضافة المنتجات التجريبية
  for (int i = 0; i < testProducts.length; i++) {
    final product = testProducts[i];
    final prodId = 'test_price_product_$i';

    final productModel = ProductModel(
      id: prodId,
      name: product['name'] as String,
      description: product['description'] as String,
      images: [product['image'] as String],
      price: product['price'] as double,
      originalPrice: product['originalPrice'] as double?,
      unit: product['unit'] as String,
      categoryId: product['categoryId'] as String,
      isSpecialOffer: product['originalPrice'] != null,
      isBestSeller: false,
      isVisible: true,
      stockQuantity: 20 + random.nextInt(50),
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  print('تم إضافة 4 منتجات تجريبية مع أسعار مختلفة بنجاح!');
}

Future<void> deleteAllProductsAndReseed() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final now = DateTime.now();

  print('بدء حذف جميع المنتجات...');

  // حذف جميع المنتجات الموجودة
  final productsSnapshot = await firestore.collection('products').get();
  final batch = firestore.batch();

  for (var doc in productsSnapshot.docs) {
    batch.delete(doc.reference);
  }

  await batch.commit();
  print('تم حذف ${productsSnapshot.docs.length} منتج');

  // إعادة إضافة فئات جديدة مع منتجات تحتوي على أسعار أصلية
  final categories = [
    {
      'name': 'فواكه طازجة',
      'color': '#FF6B6B',
      'image': 'https://picsum.photos/seed/fruits/400/400',
    },
    {
      'name': 'خضروات عضوية',
      'color': '#4ECDC4',
      'image': 'https://picsum.photos/seed/vegetables/400/400',
    },
    {
      'name': 'ألبان ومنتجات',
      'color': '#45B7D1',
      'image': 'https://picsum.photos/seed/dairy/400/400',
    },
    {
      'name': 'لحوم طازجة',
      'color': '#96CEB4',
      'image': 'https://picsum.photos/seed/meat/400/400',
    },
    {
      'name': 'أسماك طازجة',
      'color': '#FFEAA7',
      'image': 'https://picsum.photos/seed/fish/400/400',
    },
  ];

  // إضافة الفئات
  for (int i = 0; i < categories.length; i++) {
    final cat = categories[i];
    final catId = 'cat_${i + 1}';
    final catName = cat['name'] as String;
    final catColor = cat['color'] as String;
    final catImage = cat['image'] as String;

    final categoryModel = CategoryModel(
      id: catId,
      name: catName,
      imageUrl: catImage,
      color: catColor,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('categories')
        .doc(catId)
        .set(categoryModel.toJson());

    // إضافة 10 منتجات لكل فئة مع أسعار أصلية
    for (int j = 0; j < 10; j++) {
      final prodId = 'prod_${catId}_$j';
      final prodName = '$catName منتج ${j + 1}';
      final prodImage = 'https://picsum.photos/seed/${catId}_$j/400/400';
      final price = 15 + random.nextInt(85); // من 15 إلى 100
      final stock = 20 + random.nextInt(80);
      final isOffer = random.nextBool();
      final isBestSeller = random.nextBool();
      final unit = ['قطعة', 'علبة', 'كجم', 'لتر'][random.nextInt(4)];

      // إضافة سعر أصلي للعروض (أعلى من السعر الحالي)
      double? originalPrice;
      if (isOffer) {
        originalPrice =
            price.toDouble() + (15 + random.nextInt(25)); // سعر أعلى من 15-40
      } else if (random.nextBool() && random.nextBool()) {
        // إضافة أسعار أصلية لبعض المنتجات العادية أيضاً (25% من المنتجات)
        originalPrice =
            price.toDouble() + (5 + random.nextInt(15)); // سعر أعلى من 5-20
      }

      final productModel = ProductModel(
        id: prodId,
        name: prodName,
        description: 'وصف افتراضي للمنتج $prodName',
        images: [prodImage],
        price: price.toDouble(),
        originalPrice: originalPrice,
        unit: unit,
        categoryId: catId,
        isSpecialOffer: isOffer,
        isBestSeller: isBestSeller,
        isVisible: true,
        stockQuantity: stock,
        createdAt: now,
        updatedAt: now,
      );

      await firestore
          .collection('products')
          .doc(prodId)
          .set(productModel.toJson());
    }
  }

  // إضافة عروض خاصة حقيقية
  final specialOffers = [
    {
      'name': 'موز عضوي طازج',
      'description': 'موز عضوي طازج من أفضل المزارع، غني بالبوتاسيوم والألياف',
      'price': 25.0,
      'originalPrice': 35.0,
      'unit': '١ كجم',
      'categoryId': 'cat_1',
      'image':
          'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'تفاح أحمر مستورد',
      'description': 'تفاح أحمر مستورد من أفضل الأصناف، مقرمش وحلو المذاق',
      'price': 45.0,
      'originalPrice': 60.0,
      'unit': '٢ كجم',
      'categoryId': 'cat_1',
      'image':
          'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'طماطم بلدي طازجة',
      'description': 'طماطم بلدي طازجة من المزارع المحلية، طعمها طبيعي',
      'price': 20.0,
      'originalPrice': 28.0,
      'unit': '١ كجم',
      'categoryId': 'cat_2',
      'image':
          'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'خيار طازج عضوي',
      'description': 'خيار طازج عضوي، مقرمش ومنعش، مثالي للسلطات',
      'price': 15.0,
      'originalPrice': 22.0,
      'unit': '٥٠٠ جرام',
      'categoryId': 'cat_2',
      'image':
          'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?auto=format&fit=crop&w=400&q=80',
    },
  ];

  // إضافة العروض الخاصة
  for (int i = 0; i < specialOffers.length; i++) {
    final offer = specialOffers[i];
    final prodId = 'special_offer_new_$i';

    final productModel = ProductModel(
      id: prodId,
      name: offer['name'] as String,
      description: offer['description'] as String,
      images: [offer['image'] as String],
      price: offer['price'] as double,
      originalPrice: offer['originalPrice'] as double,
      unit: offer['unit'] as String,
      categoryId: offer['categoryId'] as String,
      isSpecialOffer: true,
      isBestSeller: false,
      isVisible: true,
      stockQuantity: 50 + random.nextInt(100),
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  // إضافة منتجات من الأكثر مبيعاً
  final bestSellers = [
    {
      'name': 'أرز بسمتي هندي',
      'description': 'أرز بسمتي هندي عالي الجودة، حبة طويلة ورائحة مميزة',
      'price': 85.0,
      'unit': '٢ كجم',
      'categoryId': 'cat_3',
      'image':
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'زيت زيتون بكر ممتاز',
      'description': 'زيت زيتون بكر ممتاز من أفضل المزارع، طعمه طبيعي',
      'price': 120.0,
      'unit': 'لتر',
      'categoryId': 'cat_3',
      'image':
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'جبنة شيدر قوية',
      'description': 'جبنة شيدر قوية النكهة، مثالية للطبخ والشطائر',
      'price': 65.0,
      'unit': '٢٥٠ جرام',
      'categoryId': 'cat_3',
      'image':
          'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=400&q=80',
    },
  ];

  // إضافة الأكثر مبيعاً
  for (int i = 0; i < bestSellers.length; i++) {
    final seller = bestSellers[i];
    final prodId = 'best_seller_new_$i';

    final productModel = ProductModel(
      id: prodId,
      name: seller['name'] as String,
      description: seller['description'] as String,
      images: [seller['image'] as String],
      price: seller['price'] as double,
      unit: seller['unit'] as String,
      categoryId: seller['categoryId'] as String,
      isSpecialOffer: false,
      isBestSeller: true,
      isVisible: true,
      stockQuantity: 30 + random.nextInt(70),
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  print('تم حذف وإعادة إضافة جميع المنتجات مع أسعار أصلية بنجاح!');
}

Future<void> deleteAllCategoriesAndProducts() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final now = DateTime.now();

  print('بدء حذف جميع الفئات والمنتجات...');

  // حذف جميع المنتجات الموجودة
  final productsSnapshot = await firestore.collection('products').get();
  final productsBatch = firestore.batch();

  for (var doc in productsSnapshot.docs) {
    productsBatch.delete(doc.reference);
  }

  await productsBatch.commit();
  print('تم حذف ${productsSnapshot.docs.length} منتج');

  // حذف جميع الفئات الموجودة
  final categoriesSnapshot = await firestore.collection('categories').get();
  final categoriesBatch = firestore.batch();

  for (var doc in categoriesSnapshot.docs) {
    categoriesBatch.delete(doc.reference);
  }

  await categoriesBatch.commit();
  print('تم حذف ${categoriesSnapshot.docs.length} فئة');

  // إعادة إضافة فئات جديدة مع منتجات تحتوي على أسعار أصلية
  final categories = [
    {
      'name': 'فواكه طازجة',
      'color': '#FF6B6B',
      'image': 'https://picsum.photos/seed/fruits/400/400',
    },
    {
      'name': 'خضروات عضوية',
      'color': '#4ECDC4',
      'image': 'https://picsum.photos/seed/vegetables/400/400',
    },
    {
      'name': 'ألبان ومنتجات',
      'color': '#45B7D1',
      'image': 'https://picsum.photos/seed/dairy/400/400',
    },
    {
      'name': 'لحوم طازجة',
      'color': '#96CEB4',
      'image': 'https://picsum.photos/seed/meat/400/400',
    },
    {
      'name': 'أسماك طازجة',
      'color': '#FFEAA7',
      'image': 'https://picsum.photos/seed/fish/400/400',
    },
    {
      'name': 'أرز ومكرونة',
      'color': '#DDA0DD',
      'image': 'https://picsum.photos/seed/rice/400/400',
    },
    {
      'name': 'زيوت وبهارات',
      'color': '#98D8C8',
      'image': 'https://picsum.photos/seed/oils/400/400',
    },
  ];

  // إضافة الفئات
  for (int i = 0; i < categories.length; i++) {
    final cat = categories[i];
    final catId = 'cat_${i + 1}';
    final catName = cat['name'] as String;
    final catColor = cat['color'] as String;
    final catImage = cat['image'] as String;

    final categoryModel = CategoryModel(
      id: catId,
      name: catName,
      imageUrl: catImage,
      color: catColor,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('categories')
        .doc(catId)
        .set(categoryModel.toJson());

    // إضافة 8 منتجات لكل فئة مع أسعار أصلية
    for (int j = 0; j < 8; j++) {
      final prodId = 'prod_${catId}_$j';
      final prodName = '$catName منتج ${j + 1}';
      final prodImage = 'https://picsum.photos/seed/${catId}_$j/400/400';
      final price = 15 + random.nextInt(85); // من 15 إلى 100
      final stock = 20 + random.nextInt(80);
      final isOffer = random.nextBool();
      final isBestSeller = random.nextBool();
      final unit = ['قطعة', 'علبة', 'كجم', 'لتر'][random.nextInt(4)];

      // إضافة سعر أصلي للعروض (أعلى من السعر الحالي)
      double? originalPrice;
      if (isOffer) {
        originalPrice =
            price.toDouble() + (15 + random.nextInt(25)); // سعر أعلى من 15-40
      }

      final productModel = ProductModel(
        id: prodId,
        name: prodName,
        description: 'وصف افتراضي للمنتج $prodName',
        images: [prodImage],
        price: price.toDouble(),
        originalPrice: originalPrice,
        unit: unit,
        categoryId: catId,
        isSpecialOffer: isOffer,
        isBestSeller: isBestSeller,
        isVisible: true,
        stockQuantity: stock,
        createdAt: now,
        updatedAt: now,
      );

      await firestore
          .collection('products')
          .doc(prodId)
          .set(productModel.toJson());
    }
  }

  // إضافة عروض خاصة حقيقية
  final specialOffers = [
    {
      'name': 'موز عضوي طازج',
      'description': 'موز عضوي طازج من أفضل المزارع، غني بالبوتاسيوم والألياف',
      'price': 25.0,
      'originalPrice': 35.0,
      'unit': '١ كجم',
      'categoryId': 'cat_1',
      'image': 'https://picsum.photos/seed/banana/400/400',
    },
    {
      'name': 'تفاح أحمر مستورد',
      'description': 'تفاح أحمر مستورد من أفضل الأصناف، مقرمش وحلو المذاق',
      'price': 45.0,
      'originalPrice': 60.0,
      'unit': '٢ كجم',
      'categoryId': 'cat_1',
      'image': 'https://picsum.photos/seed/apple/400/400',
    },
    {
      'name': 'طماطم بلدي طازجة',
      'description': 'طماطم بلدي طازجة من المزارع المحلية، طعمها طبيعي',
      'price': 20.0,
      'originalPrice': 28.0,
      'unit': '١ كجم',
      'categoryId': 'cat_2',
      'image': 'https://picsum.photos/seed/tomato/400/400',
    },
    {
      'name': 'خيار طازج عضوي',
      'description': 'خيار طازج عضوي، مقرمش ومنعش، مثالي للسلطات',
      'price': 15.0,
      'originalPrice': 22.0,
      'unit': '٥٠٠ جرام',
      'categoryId': 'cat_2',
      'image': 'https://picsum.photos/seed/cucumber/400/400',
    },
    {
      'name': 'جبنة شيدر قوية',
      'description': 'جبنة شيدر قوية النكهة، مثالية للطبخ والشطائر',
      'price': 55.0,
      'originalPrice': 75.0,
      'unit': '٢٥٠ جرام',
      'categoryId': 'cat_3',
      'image': 'https://picsum.photos/seed/cheese/400/400',
    },
  ];

  // إضافة العروض الخاصة
  for (int i = 0; i < specialOffers.length; i++) {
    final offer = specialOffers[i];
    final prodId = 'special_offer_clean_$i';

    final productModel = ProductModel(
      id: prodId,
      name: offer['name'] as String,
      description: offer['description'] as String,
      images: [offer['image'] as String],
      price: offer['price'] as double,
      originalPrice: offer['originalPrice'] as double,
      unit: offer['unit'] as String,
      categoryId: offer['categoryId'] as String,
      isSpecialOffer: true,
      isBestSeller: false,
      isVisible: true,
      stockQuantity: 50 + random.nextInt(100),
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  // إضافة منتجات من الأكثر مبيعاً
  final bestSellers = [
    {
      'name': 'أرز بسمتي هندي',
      'description': 'أرز بسمتي هندي عالي الجودة، حبة طويلة ورائحة مميزة',
      'price': 85.0,
      'unit': '٢ كجم',
      'categoryId': 'cat_6',
      'image': 'https://picsum.photos/seed/rice_basmati/400/400',
    },
    {
      'name': 'زيت زيتون بكر ممتاز',
      'description': 'زيت زيتون بكر ممتاز من أفضل المزارع، طعمه طبيعي',
      'price': 120.0,
      'unit': 'لتر',
      'categoryId': 'cat_7',
      'image': 'https://picsum.photos/seed/olive_oil/400/400',
    },
    {
      'name': 'لحم بقري طازج',
      'description': 'لحم بقري طازج من أفضل الجزارين، عالي الجودة',
      'price': 180.0,
      'unit': 'كجم',
      'categoryId': 'cat_4',
      'image': 'https://picsum.photos/seed/beef/400/400',
    },
    {
      'name': 'سمك بلطي طازج',
      'description': 'سمك بلطي طازج من البحيرات المحلية، طعمه مميز',
      'price': 95.0,
      'unit': 'كجم',
      'categoryId': 'cat_5',
      'image': 'https://picsum.photos/seed/fish_tilapia/400/400',
    },
  ];

  // إضافة الأكثر مبيعاً
  for (int i = 0; i < bestSellers.length; i++) {
    final seller = bestSellers[i];
    final prodId = 'best_seller_clean_$i';

    final productModel = ProductModel(
      id: prodId,
      name: seller['name'] as String,
      description: seller['description'] as String,
      images: [seller['image'] as String],
      price: seller['price'] as double,
      unit: seller['unit'] as String,
      categoryId: seller['categoryId'] as String,
      isSpecialOffer: false,
      isBestSeller: true,
      isVisible: true,
      stockQuantity: 30 + random.nextInt(70),
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  print('تم حذف وإعادة إضافة جميع الفئات والمنتجات مع أسعار أصلية بنجاح!');
}

Future<void> seedCategoriesWithLocalImages() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final now = DateTime.now();

  print('بدء إنشاء فئات مع صور محلية...');

  // فئات مع صور محلية أكثر واقعية
  final categories = [
    {
      'name': 'فواكه طازجة',
      'color': '#FF6B6B',
      'image': 'https://picsum.photos/seed/local_fruits/400/400',
      'description': 'فواكه طازجة من أفضل المزارع المحلية',
    },
    {
      'name': 'خضروات عضوية',
      'color': '#4ECDC4',
      'image': 'https://picsum.photos/seed/local_vegetables/400/400',
      'description': 'خضروات عضوية طازجة من المزارع المحلية',
    },
    {
      'name': 'ألبان ومنتجات',
      'color': '#45B7D1',
      'image': 'https://picsum.photos/seed/local_dairy/400/400',
      'description': 'ألبان ومنتجات طازجة عالية الجودة',
    },
    {
      'name': 'لحوم طازجة',
      'color': '#96CEB4',
      'image': 'https://picsum.photos/seed/local_meat/400/400',
      'description': 'لحوم طازجة من أفضل الجزارين المحليين',
    },
    {
      'name': 'أسماك طازجة',
      'color': '#FFEAA7',
      'image': 'https://picsum.photos/seed/local_fish/400/400',
      'description': 'أسماك طازجة من البحيرات والأنهار المحلية',
    },
    {
      'name': 'أرز ومكرونة',
      'color': '#DDA0DD',
      'image': 'https://picsum.photos/seed/local_grains/400/400',
      'description': 'أرز ومكرونة عالية الجودة من أفضل الموردين',
    },
    {
      'name': 'زيوت وبهارات',
      'color': '#98D8C8',
      'image': 'https://picsum.photos/seed/local_oils/400/400',
      'description': 'زيوت وبهارات طبيعية من أفضل المزارع',
    },
    {
      'name': 'مشروبات طازجة',
      'color': '#FFB6C1',
      'image': 'https://picsum.photos/seed/local_drinks/400/400',
      'description': 'مشروبات طازجة وعصائر طبيعية',
    },
  ];

  // حذف الفئات الموجودة أولاً
  final categoriesSnapshot = await firestore.collection('categories').get();
  final categoriesBatch = firestore.batch();

  for (var doc in categoriesSnapshot.docs) {
    categoriesBatch.delete(doc.reference);
  }

  await categoriesBatch.commit();
  print('تم حذف ${categoriesSnapshot.docs.length} فئة موجودة');

  // إضافة الفئات الجديدة
  for (int i = 0; i < categories.length; i++) {
    final cat = categories[i];
    final catId = 'local_cat_${i + 1}';
    final catName = cat['name'] as String;
    final catColor = cat['color'] as String;
    final catImage = cat['image'] as String;
    final catDescription = cat['description'] as String;

    final categoryModel = CategoryModel(
      id: catId,
      name: catName,
      imageUrl: catImage,
      color: catColor,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('categories')
        .doc(catId)
        .set(categoryModel.toJson());

    // إضافة 6 منتجات لكل فئة مع صور محلية
    for (int j = 0; j < 6; j++) {
      final prodId = 'local_prod_${catId}_$j';
      final prodName = '$catName منتج ${j + 1}';
      final prodImage = 'https://picsum.photos/seed/local_${catId}_$j/400/400';
      final price = 20 + random.nextInt(80); // من 20 إلى 100
      final stock = 25 + random.nextInt(75);
      final isOffer = random.nextBool();
      final isBestSeller = random.nextBool();
      final unit = ['قطعة', 'علبة', 'كجم', 'لتر', 'عبوة'][random.nextInt(5)];

      // إضافة سعر أصلي للعروض
      double? originalPrice;
      if (isOffer) {
        originalPrice =
            price.toDouble() + (15 + random.nextInt(25)); // سعر أعلى من 15-40
      }

      final productModel = ProductModel(
        id: prodId,
        name: prodName,
        description: '$catDescription - منتج طازج وعالي الجودة',
        images: [prodImage],
        price: price.toDouble(),
        originalPrice: originalPrice,
        unit: unit,
        categoryId: catId,
        isSpecialOffer: isOffer,
        isBestSeller: isBestSeller,
        isVisible: true,
        stockQuantity: stock,
        createdAt: now,
        updatedAt: now,
      );

      await firestore
          .collection('products')
          .doc(prodId)
          .set(productModel.toJson());
    }
  }

  print(
    'تم إنشاء ${categories.length} فئة مع صور محلية و ${categories.length * 6} منتج بنجاح!',
  );
}

Future<void> seedProductsWithMultipleUnits(int unitCount) async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final now = DateTime.now();

  print('بدء إنشاء منتجات ب $unitCount وحدات...');

  // فئات موجودة
  final categoriesSnapshot = await firestore
      .collection('categories')
      .limit(5)
      .get();
  if (categoriesSnapshot.docs.isEmpty) {
    throw Exception('لا توجد فئات متاحة. يرجى إنشاء فئات أولاً.');
  }

  final categories = categoriesSnapshot.docs;

  // إنشاء منتجات ب وحدات متعددة
  for (int i = 0; i < 10; i++) {
    // 10 منتجات
    final categoryDoc = categories[i % categories.length];
    final categoryId = categoryDoc.id;
    final categoryName = categoryDoc.data()['name'] as String;

    final prodId = 'multi_unit_prod_$i';
    final prodName = '$categoryName منتج متعدد الوحدات ${i + 1}';
    final prodImage = 'https://picsum.photos/seed/multi_$i/400/400';
    final basePrice = 20 + random.nextInt(80); // من 20 إلى 100

    // إنشاء وحدات متعددة
    final units = <ProductUnit>[];
    for (int j = 0; j < unitCount; j++) {
      final unitName = _getUnitName(j, unitCount);
      final unitPrice = basePrice + (j * 10) + random.nextInt(20);
      final hasDiscount = random.nextBool();
      final originalPrice = hasDiscount
          ? unitPrice + (10 + random.nextInt(20))
          : null;

      units.add(
        ProductUnit(
          id: 'unit_${prodId}_$j',
          name: unitName,
          price: unitPrice.toDouble(),
          originalPrice: originalPrice?.toDouble(),
          isSpecialOffer: hasDiscount,
          stockQuantity: 20 + random.nextInt(80),
          isActive: true,
        ),
      );
    }

    // إنشاء المنتج
    final productModel = ProductModel(
      id: prodId,
      name: prodName,
      description: 'منتج $categoryName ب $unitCount وحدات مختلفة للاختيار',
      images: [prodImage],
      price: units.first.price, // السعر الأساسي من أول وحدة
      originalPrice: units.first.originalPrice,
      unit: units.first.name,
      categoryId: categoryId,
      isSpecialOffer: units.any((u) => u.isSpecialOffer),
      isBestSeller: random.nextBool(),
      isVisible: true,
      stockQuantity: units.first.stockQuantity,
      units: units,
      createdAt: now,
      updatedAt: now,
    );

    await firestore
        .collection('products')
        .doc(prodId)
        .set(productModel.toJson());
  }

  print('تم إنشاء 10 منتجات ب $unitCount وحدات لكل منتج بنجاح!');
}

String _getUnitName(int index, int totalUnits) {
  switch (totalUnits) {
    case 2:
      return index == 0 ? 'قطعة صغيرة' : 'قطعة كبيرة';
    case 3:
      switch (index) {
        case 0:
          return 'قطعة صغيرة';
        case 1:
          return 'قطعة متوسطة';
        case 2:
          return 'قطعة كبيرة';
        default:
          return 'قطعة ${index + 1}';
      }
    case 4:
      switch (index) {
        case 0:
          return 'قطعة صغيرة';
        case 1:
          return 'قطعة متوسطة';
        case 2:
          return 'قطعة كبيرة';
        case 3:
          return 'قطعة عملاقة';
        default:
          return 'قطعة ${index + 1}';
      }
    case 5:
      switch (index) {
        case 0:
          return 'قطعة صغيرة جداً';
        case 1:
          return 'قطعة صغيرة';
        case 2:
          return 'قطعة متوسطة';
        case 3:
          return 'قطعة كبيرة';
        case 4:
          return 'قطعة عملاقة';
        default:
          return 'قطعة ${index + 1}';
      }
    default:
      return 'قطعة ${index + 1}';
  }
}

Future<void> seedFakeOrders() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  final now = DateTime.now();

  // بيانات افتراضية للعملاء
  final customerNames = [
    'أحمد محمد',
    'فاطمة علي',
    'محمد حسن',
    'سارة أحمد',
    'خالد يوسف',
    'نور الدين',
    'عائشة محمود',
    'علي أحمد',
    'مريم سعيد',
    'حسن محمد',
  ];

  // حالات الطلبات
  final orderStatuses = [
    'pending',
    'accepted',
    'preparing',
    'delivering',
    'delivered',
    'cancelled',
  ];
  final statusWeights = [0.3, 0.2, 0.2, 0.15, 0.1, 0.05]; // احتمالات الحالات

  // جلب بعض المنتجات لإنشاء طلبات واقعية
  final productsSnapshot = await firestore
      .collection('products')
      .limit(50)
      .get();
  final products = productsSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'id': doc.id,
      'name': data['name'] ?? 'منتج غير محدد',
      'price': (data['price'] ?? 0).toDouble(),
      'image': (data['images'] as List<dynamic>?)?.firstOrNull ?? '',
    };
  }).toList();

  if (products.isEmpty) {
    print('لا توجد منتجات متاحة لإنشاء الطلبات');
    return;
  }

  // إنشاء 50 طلب افتراضي
  for (int i = 0; i < 50; i++) {
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}_$i';
    final customerName = customerNames[random.nextInt(customerNames.length)];
    final orderDate = now.subtract(
      Duration(days: random.nextInt(30), hours: random.nextInt(24)),
    );

    // اختيار حالة عشوائية مع الأوزان
    final randomValue = random.nextDouble();
    double cumulativeWeight = 0;
    String selectedStatus = 'pending';
    for (int j = 0; j < orderStatuses.length; j++) {
      cumulativeWeight += statusWeights[j];
      if (randomValue <= cumulativeWeight) {
        selectedStatus = orderStatuses[j];
        break;
      }
    }

    // إنشاء عناصر الطلب (1-5 منتجات)
    final itemCount = 1 + random.nextInt(5);
    final orderItems = <OrderItemModel>[];
    double subtotal = 0;

    for (int j = 0; j < itemCount; j++) {
      final product = products[random.nextInt(products.length)];
      final quantity = 1 + random.nextInt(3);
      final itemTotal = product['price'] * quantity;
      subtotal += itemTotal;

      orderItems.add(
        OrderItemModel(
          productId: product['id'],
          productName: product['name'],
          productImage: product['image'],
          price: product['price'],
          quantity: quantity,
          total: itemTotal,
        ),
      );
    }

    // إضافة خصم عشوائي (10% من الطلبات)
    double? discountAmount;
    String? promoCodeId;
    String? promoCode;
    if (random.nextDouble() < 0.1) {
      discountAmount = subtotal * 0.1; // خصم 10%
      promoCodeId = 'promo_${random.nextInt(1000)}';
      promoCode = 'SAVE10';
    }

    final total = subtotal - (discountAmount ?? 0);

    // إنشاء نموذج الطلب
    final orderModel = OrderModel(
      id: orderId,
      userId: 'user_${random.nextInt(1000)}', // معرف مستخدم افتراضي
      items: orderItems,
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
      status: selectedStatus,
      deliveryAddress:
          'عنوان التوصيل ${random.nextInt(100)}، شارع ${random.nextInt(50)}',
      deliveryAddressName: customerName,
      deliveryPhone:
          '01${random.nextInt(90000000) + 10000000}', // رقم هاتف مصري
      deliveryNotes: random.nextBool() ? 'ملاحظات خاصة للطلب' : null,
      estimatedDeliveryTime: orderDate.add(
        Duration(hours: 2 + random.nextInt(4)),
      ),
      createdAt: orderDate,
      updatedAt: orderDate,
      promoCodeId: promoCodeId,
      promoCode: promoCode,
      promoCodeDiscountPercentage: discountAmount != null ? 10.0 : null,
      promoCodeMaxDiscount: discountAmount != null ? 50.0 : null,
    );

    // حفظ الطلب في Firestore
    await firestore.collection('orders').doc(orderId).set(orderModel.toJson());
  }

  print('تم إنشاء 50 طلب افتراضي بنجاح!');
}
