# دمج تعديل المنتج مع شاشة إضافة المنتج - FoudaMarket

## التغيير المطلوب

تم دمج وظيفة تعديل المنتج مع شاشة `add_product_screen.dart` بدلاً من استخدام `product_edit_bottom_sheet.dart` المنفصل.

## المميزات الجديدة

### 1. شاشة موحدة للإضافة والتعديل
- **شاشة واحدة**: `add_product_screen.dart` تدعم الآن إضافة وتعديل المنتجات
- **معامل `editing`**: يتم تمرير المنتج المراد تعديله كمعامل اختياري
- **عنوان ديناميكي**: يتغير العنوان حسب الوضع (إضافة/تعديل)

### 2. واجهة مستخدم محسنة
- **شاشة كاملة**: بدلاً من bottom sheet صغير
- **مساحة أكبر**: للمدخلات والتحكم
- **تصميم متسق**: نفس التصميم المستخدم في إضافة المنتجات

### 3. وظائف محسنة
- **تحميل البيانات**: يتم تحميل بيانات المنتج تلقائياً عند التعديل
- **حفظ الصور**: دعم تحديث الصور مع المنتج
- **التحقق من الصحة**: نفس قواعد التحقق المستخدمة في الإضافة

## التغييرات في الكود

### 1. `lib/views/admin/category_items_screen.dart`

**قبل التغيير**:
```dart
void _showEditBottomSheet({required ProductModel editing}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ProductEditBottomSheet(
      product: editing,
      parentContext: context,
    ),
  );
}
```

**بعد التغيير**:
```dart
void _navigateToEditProduct({required ProductModel editing}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BlocProvider.value(
        value: widget.productBloc,
        child: AddProductScreen(
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
          editing: editing,
        ),
      ),
    ),
  );
}
```

### 2. `lib/views/admin/add_product_screen.dart`

**المعاملات الجديدة**:
```dart
class AddProductScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final ProductModel? editing;  // جديد: المنتج المراد تعديله
  
  const AddProductScreen({
    Key? key, 
    required this.categoryId, 
    required this.categoryName,
    this.editing,  // اختياري
  }) : super(key: key);
}
```

**تحميل البيانات في `initState`**:
```dart
@override
void initState() {
  super.initState();
  
  // تعيين الفئة الحالية في ProductBloc
  context.read<ProductBloc>().add(SetCurrentCategory(widget.categoryId));
  
  if (widget.editing != null) {
    final p = widget.editing!;
    nameController.text = p.name;
    priceController.text = p.price.toString();
    offerPriceController.text = p.originalPrice?.toString() ?? '';
    descriptionController.text = p.description ?? '';
    unitController.text = p.unit;
    stockQuantityController.text = p.stockQuantity.toString();
    hasOffer = p.isSpecialOffer;
    isAvailable = p.isActive;
    imageUrl = (p.images.isNotEmpty) ? p.images.first : null;
  } else {
    unitController.text = 'قطعة';
    stockQuantityController.text = '0';
  }
}
```

**منطق الحفظ**:
```dart
Future<void> saveProduct() async {
  // ... التحقق من صحة البيانات ...
  
  if (widget.editing != null) {
    // تعديل منتج
    final updatedProduct = widget.editing!.copyWith(
      name: name,
      price: price,
      originalPrice: hasOffer ? offerPrice : null,
      unit: unit,
      description: description.isNotEmpty ? description : null,
      isSpecialOffer: hasOffer,
      isActive: isAvailable,
      stockQuantity: stockQuantity,
      updatedAt: now,
    );
    if (pickedImage != null) {
      context.read<ProductBloc>().add(UpdateProductWithImage(updatedProduct, pickedImage!));
    } else {
      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
    }
  } else {
    // إضافة منتج جديد
    // ... كود إضافة المنتج الجديد ...
  }
}
```

**العنوان الديناميكي**:
```dart
AppBar(
  title: Text(
    isEdit ? 'تعديل منتج - ${widget.categoryName}' : 'إضافة منتج - ${widget.categoryName}',
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  // ...
),
```

**زر الحفظ الديناميكي**:
```dart
Text(
  isEdit ? 'حفظ التعديلات' : 'إضافة المنتج',
  style: const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
```

## المميزات المدعومة في التعديل

### 1. تحرير البيانات الأساسية
- ✅ اسم المنتج
- ✅ السعر
- ✅ الوصف
- ✅ الوحدة
- ✅ الكمية المتوفرة

### 2. إدارة العروض
- ✅ تفعيل/إلغاء العرض الخاص
- ✅ تعديل سعر العرض
- ✅ التحقق من صحة سعر العرض

### 3. إدارة الصور
- ✅ عرض الصورة الحالية
- ✅ اختيار صورة جديدة
- ✅ رفع الصورة الجديدة

### 4. إدارة التوفر
- ✅ تفعيل/إلغاء توفر المنتج
- ✅ عرض حالة التوفر

### 5. التحقق من الصحة
- ✅ التحقق من إدخال الاسم
- ✅ التحقق من صحة السعر
- ✅ التحقق من صحة سعر العرض
- ✅ التحقق من وجود صورة (للإضافة الجديدة)

## الأحداث المدعومة في ProductBloc

### 1. `UpdateProduct`
- تحديث المنتج بدون تغيير الصورة
- يستخدم الصورة الموجودة

### 2. `UpdateProductWithImage`
- تحديث المنتج مع صورة جديدة
- رفع الصورة الجديدة إلى Cloudinary
- تحديث رابط الصورة في المنتج

## كيفية الاستخدام

### 1. إضافة منتج جديد
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AddProductScreen(
      categoryId: categoryId,
      categoryName: categoryName,
      // لا يتم تمرير editing
    ),
  ),
);
```

### 2. تعديل منتج موجود
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AddProductScreen(
      categoryId: categoryId,
      categoryName: categoryName,
      editing: productToEdit,  // تمرير المنتج المراد تعديله
    ),
  ),
);
```

## المميزات الإضافية

### 1. رسائل النجاح
- رسائل مختلفة للإضافة والتعديل
- عرض رسالة النجاح قبل العودة للخلف

### 2. إدارة الحالة
- عرض مؤشر التحميل أثناء الحفظ
- إدارة الأخطاء وعرضها للمستخدم

### 3. التنقل
- العودة التلقائية بعد الحفظ الناجح
- الحفاظ على حالة ProductBloc

## ملاحظات مهمة

1. **توحيد الواجهة**: نفس الواجهة للإضافة والتعديل
2. **تحميل البيانات**: تحميل تلقائي لبيانات المنتج عند التعديل
3. **التحقق من الصحة**: نفس قواعد التحقق لكلا الوضعين
4. **إدارة الصور**: دعم تحديث الصور مع الحفاظ على الصور الموجودة
5. **الأداء**: تحسين الأداء باستخدام شاشة واحدة بدلاً من bottom sheet

## اختبار النظام

لتأكيد أن التعديل يعمل بشكل صحيح:

1. **تحميل البيانات**:
   - تأكد من تحميل جميع بيانات المنتج
   - تأكد من عرض الصورة الحالية

2. **تعديل البيانات**:
   - جرب تعديل اسم المنتج
   - جرب تعديل السعر
   - جرب تفعيل/إلغاء العرض الخاص
   - جرب تغيير الصورة

3. **الحفظ**:
   - تأكد من حفظ التعديلات
   - تأكد من عرض رسالة النجاح
   - تأكد من العودة للشاشة السابقة

4. **التحقق من الصحة**:
   - جرب حفظ بدون اسم
   - جرب حفظ بسعر غير صحيح
   - جرب حفظ بسعر عرض أعلى من السعر الأصلي 