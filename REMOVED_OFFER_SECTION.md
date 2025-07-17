# حذف قسم العرض الخاص - FoudaMarket

## نظرة عامة
تم حذف قسم "عرض خاص" المنفصل من شاشة إضافة/تعديل المنتجات. أصبحت العروض مدرجة في النظام الموحد للوحدات، مما يوفر إدارة أكثر مرونة ووضوحاً للعروض الخاصة.

## التغييرات المطبقة

### 1. حذف قسم العرض الخاص من الواجهة
- **قبل التحديث**: قسم منفصل يحتوي على:
  - مفتاح تفعيل/إلغاء العرض
  - حقل سعر العرض (offerPriceController)
  - رسائل خطأ للعرض (offerError)
- **بعد التحديث**: العروض مدرجة في "إدارة الوحدات" فقط

### 2. تنظيف الكود
- **حذف Controllers**: تم حذف `offerPriceController`
- **حذف المتغيرات**: تم حذف `hasOffer` و `offerError`
- **تنظيف dispose**: تم حذف dispose للـ controller المحذوف

### 3. تحديث منطق الحفظ
- **استخدام النظام الموحد**: يتم الآن استخدام `unitsData.baseHasOffer` و `unitsData.baseOfferPrice`
- **قيم افتراضية**: تم تعيين قيم افتراضية آمنة للعروض

## الملفات المحدثة

### `lib/views/admin/add_product_screen.dart`
- حذف قسم "عرض خاص" من الواجهة
- حذف `offerPriceController`
- حذف المتغيرات `hasOffer` و `offerError`
- تحديث منطق التهيئة والحفظ
- تنظيف دالة `dispose`

## الفوائد

### 1. تنظيم أفضل
- **واجهة أبسط**: تقليل عدد الأقسام في الشاشة
- **تنظيم منطقي**: تجميع جميع بيانات العروض في مكان واحد
- **وضوح أكبر**: فصل واضح بين معلومات المنتج والعروض

### 2. مرونة أكبر
- **عروض متعددة**: إمكانية إضافة عروض مختلفة للوحدات المختلفة
- **عروض مرنة**: عروض خاصة لكل وحدة على حدة
- **إدارة شاملة**: إدارة كاملة للعروض والأسعار

### 3. صيانة أسهل
- **كود أقل**: تقليل عدد الأسطر والـ controllers
- **منطق موحد**: إدارة واحدة للعروض
- **أخطاء أقل**: تقليل احتمالية الأخطاء

## هيكل الشاشة الجديد

### الأقسام المتبقية:
1. **معلومات المنتج** - الاسم والوصف
2. **صورة المنتج** - رفع وإدارة الصور
3. **حالة التوفر** - تفعيل/إلغاء المنتج
4. **إدارة الوحدات** - النظام الموحد للوحدات والعروض

### الأقسام المحذوفة:
- ~~عرض خاص~~ (تم دمجها في إدارة الوحدات)

## مثال على التغيير

### قبل التحديث:
```dart
// عرض خاص
ProductFormSection(
  title: 'عرض خاص',
  icon: Icons.local_offer,
  children: [
    OfferSwitch(
      hasOffer: hasOffer,
      onChanged: (val) {
        setState(() {
          hasOffer = val;
          if (!hasOffer) {
            offerPriceController.clear();
            offerError = null;
          }
        });
      },
      offerPriceField: hasOffer ? ProductTextField(
        controller: offerPriceController,
        labelText: 'سعر العرض *',
        prefixIcon: Icons.local_offer,
        suffixText: 'ج.م',
        errorText: offerError,
        keyboardType: TextInputType.number,
        onChanged: () {
          if (offerError != null) {
            setState(() {
              offerError = null;
            });
          }
        },
      ) : null,
    ),
  ],
),
```

### بعد التحديث:
```dart
// إدارة الوحدات الموحدة (تتضمن العروض)
ProductFormSection(
  title: 'إدارة الوحدات',
  icon: Icons.layers,
  children: [
    UnifiedUnitsManager(
      initialBaseUnit: unitsData?.baseUnit,
      initialBasePrice: unitsData?.basePrice,
      initialBaseOfferPrice: unitsData?.baseOfferPrice,
      initialBaseStock: unitsData?.baseStock,
      initialBaseHasOffer: unitsData?.baseHasOffer,
      initialAdditionalUnits: unitsData?.additionalUnits,
      onUnitsChanged: (data) {
        setState(() {
          unitsData = data;
        });
      },
    ),
  ],
),
```

## منطق الحفظ الجديد

### إضافة منتج جديد:
```dart
final product = ProductModel(
  id: productId,
  name: name,
  description: description.isNotEmpty ? description : null,
  images: [],
  price: unitsData?.basePrice ?? 0,
  originalPrice: unitsData?.baseHasOffer == true ? unitsData?.baseOfferPrice : null,
  unit: unitsData?.baseUnit ?? 'قطعة',
  categoryId: widget.categoryId,
  isSpecialOffer: unitsData?.baseHasOffer ?? false,  // من النظام الموحد
  isActive: unitsData?.baseIsActive ?? isAvailable,
  stockQuantity: unitsData?.baseStock ?? 0,
  units: unitsData?.additionalUnits.isNotEmpty == true ? unitsData?.additionalUnits : null,
  createdAt: now,
  updatedAt: now,
);
```

### تحرير منتج موجود:
```dart
final updatedProduct = widget.editing!.copyWith(
  name: name,
  price: unitsData?.basePrice ?? 0,
  originalPrice: unitsData?.baseHasOffer == true ? unitsData?.baseOfferPrice : null,
  unit: unitsData?.baseUnit ?? 'قطعة',
  description: description.isNotEmpty ? description : null,
  isSpecialOffer: unitsData?.baseHasOffer ?? false,  // من النظام الموحد
  isActive: unitsData?.baseIsActive ?? isAvailable,
  stockQuantity: unitsData?.baseStock ?? 0,
  units: unitsData?.additionalUnits.isNotEmpty == true ? unitsData?.additionalUnits : null,
  updatedAt: now,
);
```

## ملاحظات مهمة

### 1. التوافق
- **توافق كامل**: لا يؤثر على المنتجات الموجودة
- **ترقية سلسة**: جميع البيانات محفوظة
- **دعم كامل**: دعم كامل للتحرير والإضافة

### 2. البيانات
- **حفظ العروض**: العروض محفوظة في النظام الموحد
- **استرجاع العروض**: يمكن استرجاع العروض عند التحرير
- **قيم افتراضية**: قيم افتراضية آمنة للمنتجات الجديدة

### 3. التحقق من الصحة
- **تحقق من العروض**: التحقق من صحة أسعار العروض
- **تحقق من الوحدات**: التحقق من صحة أسعار الوحدات الإضافية
- **تحقق شامل**: تحقق شامل من جميع البيانات

## التطوير المستقبلي

### 1. تحسينات إضافية
- **عروض ديناميكية**: عروض تتغير حسب الوقت
- **عروض متقدمة**: عروض أكثر تعقيداً
- **تقارير العروض**: تقارير مفصلة للعروض

### 2. ميزات جديدة
- **عروض موسمية**: عروض خاصة للمواسم
- **عروض جغرافية**: عروض مختلفة حسب المنطقة
- **عروض للعملاء**: عروض خاصة لفئات معينة من العملاء 