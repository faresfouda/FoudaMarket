# نظام البحث عن الفئات - Fouda Market

## نظرة عامة

تم إعادة كتابة نظام البحث عن الفئات بالكامل ليكون أكثر كفاءة وأداءً. النظام يدعم البحث الفوري مع debouncing، التحميل التدريجي، وإدارة أفضل للحالات.

## المميزات الجديدة

### 🔍 **البحث المحسن**
- **Debouncing**: تأخير 500 مللي ثانية لتجنب الطلبات المتكررة
- **بحث فوري**: نتائج فورية مع تحديث ديناميكي
- **إلغاء الطلبات السابقة**: عند كتابة نص جديد يتم إلغاء البحث السابق

### 📱 **واجهة مستخدم محسنة**
- **مؤشرات تحميل**: عرض حالة البحث بوضوح
- **رسائل خطأ واضحة**: رسائل مخصصة للبحث والقائمة العادية
- **تصميم متجاوب**: يعمل على جميع أحجام الشاشات

### ⚡ **أداء محسن**
- **تحميل تدريجي**: دعم pagination للبحث والقائمة العادية
- **إدارة ذاكرة**: تنظيف الموارد عند إغلاق الشاشة
- **تحسين الاستعلامات**: استعلامات Firestore محسنة

## البنية التقنية

### 1. Firebase Service (`lib/services/firebase_service.dart`)

#### دالة البحث الأساسية
```dart
Future<List<CategoryModel>> searchCategories(String query) async {
  if (query.trim().isEmpty) {
    return getCategories();
  }
  
  try {
    final querySnapshot = await _firestore
        .collection('categories')
        .where('name', isGreaterThanOrEqualTo: query.trim())
        .where('name', isLessThan: query.trim() + '\uf8ff')
        .orderBy('name')
        .orderBy('created_at')
        .get();

    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return CategoryModel.fromJson(data);
        })
        .toList();
  } catch (e) {
    print('Error searching categories: $e');
    return [];
  }
}
```

#### دالة البحث مع Pagination
```dart
Future<List<CategoryModel>> searchCategoriesPaginated({
  required String query,
  int limit = 10,
  CategoryModel? lastCategory,
}) async {
  if (query.trim().isEmpty) {
    return getCategoriesPaginated(limit: limit, lastCategory: lastCategory);
  }
  
  try {
    var firestoreQuery = _firestore
        .collection('categories')
        .where('name', isGreaterThanOrEqualTo: query.trim())
        .where('name', isLessThan: query.trim() + '\uf8ff')
        .orderBy('name')
        .orderBy('created_at')
        .limit(limit);
    
    if (lastCategory != null) {
      firestoreQuery = firestoreQuery.startAfter([
        lastCategory.name,
        lastCategory.createdAt.toIso8601String(),
      ]);
    }
    
    final querySnapshot = await firestoreQuery.get();
    
    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return CategoryModel.fromJson(data);
        })
        .toList();
  } catch (e) {
    print('Error searching categories with pagination: $e');
    return [];
  }
}
```

### 2. Category BLoC (`lib/blocs/products/category_bloc.dart`)

#### الحالات الجديدة
```dart
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _searchResults = [];
  bool _hasMore = true;
  bool _hasMoreSearch = true;
  String _currentSearchQuery = '';
  static const int defaultLimit = 10;
}
```

#### أحداث البحث الجديدة
```dart
class LoadMoreSearchResults extends CategoryEvent {
  final int limit;
  final CategoryModel? lastCategory;
  const LoadMoreSearchResults({this.limit = 10, this.lastCategory});
}

class ClearSearch extends CategoryEvent {
  const ClearSearch();
}
```

#### حالات البحث الجديدة
```dart
class CategoriesSearchLoaded extends CategoryState {
  final List<CategoryModel> categories;
  final String query;
  final bool hasMore;
  const CategoriesSearchLoaded(this.categories, this.query, {this.hasMore = true});
}
```

### 3. شاشة الفئات (`lib/views/categories/categories_screen.dart`)

#### Debouncing للبحث
```dart
void _onSearchChanged(String value) {
  _debounceTimer?.cancel();
  
  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
    if (value.trim().isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      context.read<CategoryBloc>().add(SearchCategories(value.trim()));
    } else {
      setState(() {
        _isSearching = false;
      });
      context.read<CategoryBloc>().add(const ClearSearch());
    }
  });
}
```

#### التحميل التدريجي للبحث
```dart
void _onScroll() {
  if (!_scrollController.hasClients) return;
  final maxScroll = _scrollController.position.maxScrollExtent;
  final currentScroll = _scrollController.position.pixels;
  if (maxScroll - currentScroll <= 200 && !_isLoadingMore) {
    final bloc = context.read<CategoryBloc>();
    final state = bloc.state;
    
    if (_isSearching) {
      // تحميل المزيد من نتائج البحث
      if (state is CategoriesSearchLoaded && state.hasMore) {
        _isLoadingMore = true;
        bloc.add(LoadMoreSearchResults(
          limit: CategoryBloc.defaultLimit,
          lastCategory: state.categories.isNotEmpty ? state.categories.last : null,
        ));
      }
    } else {
      // تحميل المزيد من الفئات العادية
      if (state is CategoriesLoaded && state.hasMore) {
        _isLoadingMore = true;
        bloc.add(LoadMoreCategories(
          limit: CategoryBloc.defaultLimit,
          lastCategory: state.categories.isNotEmpty ? state.categories.last : null,
        ));
      }
    }
  }
}
```

### 4. شاشة إدارة الفئات (`lib/views/admin/admin_products_categories_screen.dart`)

#### نفس نظام البحث مع إدارة محسنة
- دعم إضافة وتعديل وحذف الفئات
- عرض عدد المنتجات في كل فئة
- واجهة إدارة بسيطة وفعالة

## كيفية الاستخدام

### 1. البحث في شاشة العميل
```dart
// في CategoriesScreen
context.read<CategoryBloc>().add(SearchCategories(query));
```

### 2. البحث في شاشة الإدارة
```dart
// في AdminProductsCategoriesScreen
context.read<CategoryBloc>().add(SearchCategories(query));
```

### 3. مسح البحث
```dart
context.read<CategoryBloc>().add(const ClearSearch());
```

### 4. تحميل المزيد من النتائج
```dart
context.read<CategoryBloc>().add(LoadMoreSearchResults(
  limit: 10,
  lastCategory: lastCategory,
));
```

## متطلبات Firestore

### Index المطلوب
```
Collection: categories
Fields: 
- name (Ascending)
- created_at (Ascending)
Query scope: Collection
```

### كيفية إنشاء الـ Index
1. اذهب إلى Firebase Console
2. اختر مشروعك
3. اذهب إلى Firestore Database
4. اختر Indexes
5. اضغط على "Create Index"
6. أدخل البيانات التالية:
   - Collection ID: `categories`
   - Fields: 
     - `name` (Ascending)
     - `created_at` (Ascending)
   - Query scope: Collection

## الملفات المحدثة

### 1. Firebase Service
- ✅ `searchCategories()` - دالة البحث الأساسية
- ✅ `searchCategoriesPaginated()` - دالة البحث مع pagination
- ✅ `getCategories()` - تحسين إضافة ID
- ✅ `getCategoriesPaginated()` - تحسين إضافة ID

### 2. Category BLoC
- ✅ إضافة `LoadMoreSearchResults` event
- ✅ إضافة `ClearSearch` event
- ✅ تحسين `CategoriesSearchLoaded` state
- ✅ إدارة منفصلة لنتائج البحث
- ✅ رسائل خطأ باللغة العربية

### 3. Category Events
- ✅ `LoadMoreSearchResults` - تحميل المزيد من نتائج البحث
- ✅ `ClearSearch` - مسح البحث

### 4. Category States
- ✅ `CategoriesSearchLoaded` - مع `hasMore` parameter

### 5. شاشة الفئات (العميل)
- ✅ Debouncing للبحث
- ✅ دعم التحميل التدريجي للبحث
- ✅ رسائل خطأ محسنة
- ✅ إدارة أفضل للحالات

### 6. شاشة إدارة الفئات
- ✅ نفس نظام البحث المحسن
- ✅ واجهة إدارة بسيطة
- ✅ دعم CRUD operations

## تحسينات الأداء

### 1. Debouncing
- تأخير 500 مللي ثانية لتجنب الطلبات المتكررة
- إلغاء الطلبات السابقة عند كتابة نص جديد

### 2. Pagination
- تحميل 10 فئات في كل مرة
- دعم التحميل التدريجي للبحث والقائمة العادية

### 3. Error Handling
- معالجة أخطاء Firestore
- رسائل خطأ واضحة باللغة العربية
- fallback للقائمة العادية عند حدوث خطأ

### 4. Memory Management
- تنظيف Timers عند إغلاق الشاشة
- تنظيف Controllers
- إدارة أفضل للـ State

## الاختبار

### 1. اختبار البحث
- اكتب نص في حقل البحث
- تأكد من ظهور النتائج بعد 500 مللي ثانية
- تأكد من إلغاء البحث السابق عند كتابة نص جديد

### 2. اختبار التحميل التدريجي
- ابحث عن نص ينتج عنه أكثر من 10 نتائج
- اسحب للأسفل لتأكد من تحميل المزيد
- تأكد من ظهور مؤشر التحميل

### 3. اختبار مسح البحث
- اكتب نص في البحث
- امسح النص
- تأكد من العودة للقائمة الكاملة

### 4. اختبار الأخطاء
- تأكد من ظهور رسائل خطأ واضحة
- تأكد من عدم تعطل التطبيق عند حدوث خطأ

## الخلاصة

تم إعادة كتابة نظام البحث عن الفئات بالكامل ليكون:
- **أسرع**: مع debouncing و pagination
- **أكثر استقراراً**: مع معالجة أفضل للأخطاء
- **أفضل تجربة مستخدم**: مع واجهة محسنة ورسائل واضحة
- **قابل للتوسع**: مع بنية مرنة تدعم المزيد من المميزات

النظام الآن جاهز للاستخدام في الإنتاج مع أداء محسن وتجربة مستخدم أفضل. 