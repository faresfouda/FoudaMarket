# ربط الصفحة الرئيسية بالبيانات الحقيقية - Fouda Market

## نظرة عامة

تم ربط الصفحة الرئيسية بالبيانات الحقيقية من Firebase مع الحفاظ على التصميم الأصلي. الآن تعرض الصفحة البيانات الفعلية من قاعدة البيانات بدلاً من البيانات الوهمية.

## المميزات الجديدة

### 🔄 **بيانات حقيقية من Firebase**
- **الفئات**: جلب الفئات النشطة من قاعدة البيانات
- **العروض الخاصة**: عرض المنتجات المميزة كعروض خاصة
- **الأكثر مبيعاً**: عرض المنتجات المميزة كأكثر مبيعاً
- **المنتجات الموصى بها**: عرض أحدث المنتجات النشطة

### ⚡ **تحميل ذكي**
- تحميل البيانات عند بدء التطبيق
- مؤشرات تحميل واضحة
- معالجة الأخطاء بشكل أنيق
- عرض بيانات افتراضية عند عدم وجود بيانات

### 🎨 **الحفاظ على التصميم**
- نفس التصميم الأصلي بدون تغيير
- نفس الألوان والخطوط
- نفس التخطيط والمسافات
- نفس التفاعلات والحركات

## البنية التقنية

### 1. خدمات Firebase الجديدة

#### `lib/services/firebase_service.dart`
```dart
// جلب المنتجات المميزة
Future<List<ProductModel>> getBestSellers({int limit = 10})

// جلب العروض الخاصة
Future<List<ProductModel>> getSpecialOffers({int limit = 10})

// جلب المنتجات الموصى بها
Future<List<ProductModel>> getRecommendedProducts({int limit = 10})

// جلب فئات الصفحة الرئيسية
Future<List<CategoryModel>> getHomeCategories({int limit = 8})
```

### 2. أحداث BLoC الجديدة

#### `lib/blocs/products/product_event.dart`
```dart
// أحداث الصفحة الرئيسية
class FetchBestSellers extends ProductEvent
class FetchSpecialOffers extends ProductEvent
class FetchRecommendedProducts extends ProductEvent
```

### 3. حالات BLoC الجديدة

#### `lib/blocs/products/product_state.dart`
```dart
// حالات الصفحة الرئيسية
class BestSellersLoaded extends ProductState
class SpecialOffersLoaded extends ProductState
class RecommendedProductsLoaded extends ProductState
```

### 4. معالجات BLoC الجديدة

#### `lib/blocs/products/product_bloc.dart`
```dart
// معالجات الصفحة الرئيسية
Future<void> _onFetchBestSellers(FetchBestSellers event, Emitter<ProductState> emit)
Future<void> _onFetchSpecialOffers(FetchSpecialOffers event, Emitter<ProductState> emit)
Future<void> _onFetchRecommendedProducts(FetchRecommendedProducts event, Emitter<ProductState> emit)
```

## التحديثات في الصفحة الرئيسية

### 1. تحميل البيانات
```dart
@override
void initState() {
  super.initState();
  _startAutoScroll();
  
  // تحميل البيانات الحقيقية
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<CategoryBloc>().add(const FetchCategories(limit: 8));
    context.read<ProductBloc>().add(const FetchBestSellers(limit: 10));
    context.read<ProductBloc>().add(const FetchSpecialOffers(limit: 10));
    context.read<ProductBloc>().add(const FetchRecommendedProducts(limit: 10));
  });
}
```

### 2. عرض الفئات
```dart
BlocBuilder<CategoryBloc, CategoryState>(
  builder: (context, state) {
    if (state is CategoriesLoading) {
      return SizedBox(
        height: 90,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orangeColor),
        ),
      );
    } else if (state is CategoriesLoaded && state.categories.isNotEmpty) {
      return _CategoryList(categories: state.categories);
    } else {
      return _CategoryList(categories: []); // عرض فئات افتراضية
    }
  },
)
```

### 3. عرض المنتجات
```dart
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) {
    if (state is SpecialOffersLoaded && state.products.isNotEmpty) {
      return _HorizontalProductList(products: state.products);
    } else if (state is ProductsLoading) {
      return SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orangeColor),
        ),
      );
    } else {
      return _HorizontalProductList(products: []); // عرض منتجات افتراضية
    }
  },
)
```

## البيانات الافتراضية

### الفئات الافتراضية
```dart
List<CategoryModel> _getDefaultCategories() {
  return [
    CategoryModel(
      id: 'default_1',
      name: 'خضروات',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
      color: '#DCFCE7',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // ... المزيد من الفئات
  ];
}
```

### المنتجات الافتراضية
```dart
List<ProductModel> _getDefaultProducts() {
  return [
    ProductModel(
      id: 'default_1',
      name: 'موز عضوي',
      images: ['https://i.pinimg.com/736x/7a/aa/a5/7aaaa545e00e8a434850e80b8910dd94.jpg'],
      price: 45.0,
      originalPrice: 55.0,
      unit: '١ كجم',
      categoryId: 'fruits',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // ... المزيد من المنتجات
  ];
}
```

## متطلبات قاعدة البيانات

### 1. فهرس Firestore المطلوب
```javascript
// للمنتجات المميزة
collection: 'products'
fields: ['is_best_seller', 'is_active', 'created_at']
order: ['is_best_seller', 'is_active', 'created_at']

// للعروض الخاصة
collection: 'products'
fields: ['is_special_offer', 'is_active', 'created_at']
order: ['is_special_offer', 'is_active', 'created_at']

// للمنتجات الموصى بها
collection: 'products'
fields: ['is_active', 'created_at']
order: ['is_active', 'created_at']
```

### 2. حقول المنتج المطلوبة
```javascript
{
  "id": "string",
  "name": "string",
  "images": ["string"],
  "price": "number",
  "original_price": "number?",
  "unit": "string",
  "category_id": "string",
  "is_best_seller": "boolean",
  "is_special_offer": "boolean",
  "is_active": "boolean",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### 3. حقول الفئة المطلوبة
```javascript
{
  "id": "string",
  "name": "string",
  "image_url": "string?",
  "color": "string?",
  "is_active": "boolean",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## الاختبار

### 1. اختبار تحميل البيانات
- تأكد من تحميل الفئات عند بدء التطبيق
- تأكد من تحميل المنتجات المميزة
- تأكد من تحميل العروض الخاصة
- تأكد من تحميل المنتجات الموصى بها

### 2. اختبار عرض البيانات
- تأكد من عرض الفئات بشكل صحيح
- تأكد من عرض المنتجات مع الصور والأسعار
- تأكد من عرض الخصومات عند وجودها
- تأكد من عمل الروابط والتنقل

### 3. اختبار البيانات الافتراضية
- تأكد من عرض البيانات الافتراضية عند عدم وجود بيانات
- تأكد من عدم ظهور أخطاء عند فشل التحميل
- تأكد من عمل التطبيق حتى بدون اتصال بالإنترنت

### 4. اختبار الأداء
- تأكد من سرعة تحميل البيانات
- تأكد من عدم تجميد الواجهة
- تأكد من استهلاك معقول للذاكرة

## الخلاصة

تم ربط الصفحة الرئيسية بالبيانات الحقيقية بنجاح مع:

1. **الحفاظ على التصميم الأصلي** بدون أي تغييرات بصرية
2. **إضافة خدمات Firebase جديدة** لجلب البيانات المطلوبة
3. **توسيع نظام BLoC** لمعالجة البيانات الجديدة
4. **إضافة بيانات افتراضية** لضمان عمل التطبيق دائماً
5. **معالجة الأخطاء** بشكل أنيق مع مؤشرات تحميل واضحة

النتيجة: صفحة رئيسية ديناميكية تعرض البيانات الحقيقية من قاعدة البيانات مع تجربة مستخدم سلسة ومستقرة. 