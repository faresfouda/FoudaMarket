# نظام سلة التسوق - Fouda Market

## نظرة عامة

تم تنفيذ نظام سلة التسوق الكامل للمشروع مع ربطه بجميع الصفحات المطلوبة. النظام يدعم جميع العمليات الأساسية لسلة التسوق.

## المكونات الرئيسية

### 1. نموذج البيانات (Models)

#### `CartItemModel`
```dart
class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 2. الخدمات (Services)

#### `CartService`
- `getCartItems(String userId)` - جلب عناصر سلة التسوق للمستخدم
- `addToCart(CartItemModel cartItem)` - إضافة منتج إلى السلة
- `updateCartItem(String cartItemId, Map<String, dynamic> data)` - تحديث عنصر في السلة
- `removeFromCart(String cartItemId)` - إزالة منتج من السلة
- `clearCart(String userId)` - تفريغ السلة
- `getCartItemsCount(String userId)` - عدد العناصر في السلة
- `getCartTotal(String userId)` - إجمالي السلة

### 3. إدارة الحالة (State Management)

#### `CartBloc`
- `LoadCart` - تحميل سلة التسوق
- `AddToCart` - إضافة منتج إلى السلة
- `UpdateCartItem` - تحديث كمية منتج
- `RemoveFromCart` - إزالة منتج من السلة
- `ClearCart` - تفريغ السلة
- `RefreshCart` - تحديث السلة

#### حالات الـ Bloc
- `CartInitial` - الحالة الأولية
- `CartLoading` - جاري التحميل
- `CartLoaded` - تم تحميل السلة
- `CartEmpty` - السلة فارغة
- `CartError` - خطأ في التحميل
- `CartActionLoading` - جاري تنفيذ عملية
- `CartActionSuccess` - نجح تنفيذ العملية
- `CartActionError` - فشل تنفيذ العملية

### 4. واجهات المستخدم (UI)

#### `CartScreen`
- عرض عناصر سلة التسوق
- إمكانية تعديل الكميات
- إزالة المنتجات
- عرض الإجمالي
- تفريغ السلة

#### `CartProductWidget`
- عرض منتج واحد في السلة
- أزرار زيادة/تقليل الكمية
- زر الإزالة
- عرض السعر والإجمالي

## الربط مع الصفحات

### 1. الصفحة الرئيسية (Home Screen)
- زر إضافة إلى السلة في كل `ProductCard`
- رسائل تأكيد عند الإضافة

### 2. صفحة البحث (Search Screen)
- زر إضافة إلى السلة في نتائج البحث
- نفس الوظائف الموجودة في الصفحة الرئيسية

### 3. صفحة الفئات (Category Screen)
- زر إضافة إلى السلة في منتجات الفئة
- دعم جميع أنواع الوحدات

### 4. صفحة المنتج (Product Screen)
- زر إضافة إلى السلة مع اختيار الكمية والوحدة
- دعم الوحدات المتعددة للمنتج

### 5. صفحة المفضلة (Favorites Screen)
- إضافة المنتجات المحددة إلى السلة
- دعم التحديد المتعدد

## الميزات

### 1. إدارة الكميات
- زيادة/تقليل الكمية
- التحقق من الحد الأدنى (1)
- التحقق من المخزون المتاح

### 2. إدارة الوحدات
- دعم الوحدات المتعددة للمنتج
- اختيار الوحدة المناسبة
- عرض الأسعار حسب الوحدة

### 3. التكامل مع Firebase
- حفظ البيانات في Firestore
- مزامنة فورية
- دعم المستخدمين المتعددين

### 4. واجهة مستخدم محسنة
- تصميم متجاوب
- رسائل تأكيد
- حالات التحميل
- معالجة الأخطاء

## كيفية الاستخدام

### إضافة منتج إلى السلة
```dart
final cartItem = CartItemModel(
  id: '',
  userId: user.uid,
  productId: product.id,
  productName: product.name,
  productImage: product.images.first,
  price: product.price,
  quantity: 1,
  unit: product.unit,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

context.read<CartBloc>().add(AddToCart(cartItem));
```

### تحميل سلة التسوق
```dart
context.read<CartBloc>().add(LoadCart(userId));
```

### تحديث كمية منتج
```dart
context.read<CartBloc>().add(UpdateCartItem(cartItemId, newQuantity));
```

### إزالة منتج من السلة
```dart
context.read<CartBloc>().add(RemoveFromCart(cartItemId));
```

## هيكل قاعدة البيانات

### مجموعة `carts`
```json
{
  "id": "auto-generated",
  "user_id": "user123",
  "product_id": "product456",
  "product_name": "موز عضوي",
  "product_image": "https://example.com/image.jpg",
  "price": 49.0,
  "quantity": 2,
  "unit": "٧ قطع",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

## الأمان والتحقق

1. **التحقق من المستخدم**: جميع العمليات تتطلب مستخدم مسجل دخول
2. **التحقق من المخزون**: لا يمكن إضافة كمية أكبر من المتاح
3. **التحقق من البيانات**: جميع البيانات يتم التحقق من صحتها قبل الحفظ
4. **معالجة الأخطاء**: جميع العمليات محمية من الأخطاء مع رسائل مناسبة

## التطوير المستقبلي

1. **كوبونات الخصم**: دعم كوبونات الخصم
2. **الشحن**: حساب تكلفة الشحن
3. **الدفع**: ربط أنظمة الدفع
4. **التذكيرات**: تذكيرات للمنتجات في السلة
5. **المقارنة**: مقارنة المنتجات
6. **التوصيات**: توصيات بناءً على السلة

## الاستنتاج

تم تنفيذ نظام سلة التسوق الكامل بنجاح مع:
- ✅ جميع العمليات الأساسية
- ✅ ربط مع جميع الصفحات
- ✅ واجهة مستخدم محسنة
- ✅ إدارة حالة قوية
- ✅ تكامل مع Firebase
- ✅ معالجة الأخطاء
- ✅ الأمان والتحقق

النظام جاهز للاستخدام في الإنتاج ويمكن تطويره بسهولة لإضافة ميزات جديدة. 