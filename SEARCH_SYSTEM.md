# نظام البحث في تطبيق Fouda Market

## نظرة عامة

تم تفعيل نظام بحث حقيقي ومتقدم في التطبيق يعمل مع قاعدة البيانات Firebase مباشرة. النظام يدعم البحث في المنتجات والفئات مع واجهة مستخدم سلسة.

## المميزات

### 1. البحث في المنتجات
- **البحث العام**: بحث في جميع المنتجات عبر شاشة البحث الرئيسية
- **البحث في الفئة**: بحث في منتجات فئة محددة
- **بحث فوري**: نتائج فورية مع تأخير 500 مللي ثانية لتجنب البحث المتكرر
- **فلترة متقدمة**: فلترة حسب التوفر (متوفر/غير متوفر)

### 2. البحث في الفئات
- **بحث فوري**: في شاشة إدارة الفئات وشاشة العميل
- **نتائج ديناميكية**: تحديث فوري للنتائج

### 3. واجهة المستخدم
- **مؤشرات تحميل**: عرض حالة البحث بوضوح
- **رسائل خطأ**: رسائل واضحة عند عدم وجود نتائج
- **تصميم متجاوب**: يعمل على جميع أحجام الشاشات

## البنية التقنية

### Firebase Service
```dart
// البحث في المنتجات
Future<List<ProductModel>> searchProducts(String query)

// البحث في منتجات فئة محددة
Future<List<ProductModel>> searchProductsInCategory(String categoryId, String query)

// البحث في الفئات
Future<List<CategoryModel>> searchCategories(String query)
```

### BLoC Events
```dart
// أحداث البحث في المنتجات
class SearchProducts extends ProductEvent
class SearchProductsInCategory extends ProductEvent

// حدث البحث في الفئات
class SearchCategories extends CategoryEvent
```

### BLoC States
```dart
// حالات البحث في المنتجات
class ProductsSearching extends ProductState
class ProductsSearchLoaded extends ProductState

// حالات البحث في الفئات
class CategoriesSearching extends CategoryState
class CategoriesSearchLoaded extends CategoryState
```

## كيفية الاستخدام

### 1. البحث في المنتجات (شاشة البحث العامة)
```dart
// في SearchScreen
context.read<ProductBloc>().add(SearchProducts(query));
```

### 2. البحث في منتجات فئة محددة
```dart
// في CategoryItemsScreen
context.read<ProductBloc>().add(SearchProductsInCategory(categoryId, query));
```

### 3. البحث في الفئات
```dart
// في شاشة إدارة الفئات أو شاشة العميل
context.read<CategoryBloc>().add(SearchCategories(query));
```

## الشاشات المحدثة

### 1. SearchScreen
- ✅ بحث حقيقي في قاعدة البيانات
- ✅ مؤشرات تحميل
- ✅ رسائل خطأ واضحة
- ✅ عرض عدد النتائج

### 2. CategoryItemsScreen (إدارة المنتجات)
- ✅ بحث في منتجات الفئة
- ✅ فلترة حسب التوفر
- ✅ دعم التحميل التدريجي مع البحث

### 3. AdminProductsCategoriesScreen (إدارة الفئات)
- ✅ بحث في الفئات
- ✅ عرض عدد المنتجات في كل فئة

### 4. CategoriesScreen (شاشة العميل)
- ✅ بحث في الفئات
- ✅ تصميم محسن

## تحسينات الأداء

### 1. Debouncing
- تأخير البحث لمدة 500 مللي ثانية لتجنب الطلبات المتكررة
- إلغاء الطلبات السابقة عند كتابة نص جديد

### 2. Caching
- تخزين النتائج في الذاكرة
- تجنب إعادة البحث في نفس النص

### 3. Pagination
- دعم التحميل التدريجي مع البحث
- تحسين استهلاك البيانات

## رسائل المستخدم

### عند عدم وجود نتائج
- **البحث في المنتجات**: "لا توجد نتائج لـ [نص البحث]"
- **البحث في الفئات**: "لا توجد فئات تطابق البحث"
- **نصائح**: "جرب البحث بكلمات مختلفة"

### حالات التحميل
- **البحث**: "جاري البحث..."
- **التحميل**: "جاري التحميل..."

### رسائل الخطأ
- **خطأ في البحث**: "حدث خطأ في البحث"
- **زر إعادة المحاولة**: متاح في جميع حالات الخطأ

## التطوير المستقبلي

### 1. بحث متقدم
- البحث في الوصف
- البحث بالماركة
- البحث بالسعر

### 2. اقتراحات البحث
- اقتراحات تلقائية
- البحث الأكثر شيوعاً

### 3. فلترة متقدمة
- فلترة بالسعر
- فلترة بالتصنيف
- فلترة بالتوفر

### 4. تحسينات الأداء
- فهرسة Firebase
- تحسين استعلامات البحث
- تخزين مؤقت محسن

## ملاحظات تقنية

### 1. Firebase Queries
```dart
// البحث بالاسم
.where('name', isGreaterThanOrEqualTo: query)
.where('name', isLessThan: query + '\uf8ff')
```

### 2. Error Handling
- معالجة أخطاء الشبكة
- معالجة أخطاء Firebase
- رسائل خطأ واضحة للمستخدم

### 3. State Management
- استخدام BLoC Pattern
- إدارة الحالات بشكل فعال
- فصل المنطق عن العرض

## الخلاصة

نظام البحث الجديد يوفر:
- ✅ بحث حقيقي في قاعدة البيانات
- ✅ واجهة مستخدم سلسة
- ✅ أداء محسن
- ✅ تجربة مستخدم ممتازة
- ✅ قابلية التوسع والتطوير 