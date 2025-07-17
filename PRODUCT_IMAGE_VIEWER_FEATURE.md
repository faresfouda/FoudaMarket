# ميزة عرض صورة المنتج

## الوصف
تم إضافة ميزة جديدة تسمح للمستخدم بعرض صورة المنتج بحجم كامل مع معلومات السعر والكمية عند الضغط على كارت المنتج في شاشة تفاصيل الطلب.

## الميزات المضافة

### 1. تفاعل الضغط على الكارت
```dart
GestureDetector(
  onTap: () => _showProductImageDialog(context, item['image'], item['name'], item),
  child: Container(
    // محتوى الكارت
  ),
)
```

### 2. نافذة عرض الصورة المنبثقة

#### أ. تصميم النافذة:
- **الحجم**: 90% من عرض الشاشة × 70% من ارتفاع الشاشة
- **الخلفية**: شفافة مع ظلال قوية
- **الحواف**: مدورة (20 بكسل)

#### ب. هيكل النافذة:
```dart
Dialog(
  backgroundColor: Colors.transparent,
  child: Container(
    width: MediaQuery.of(context).size.width * 0.9,
    height: MediaQuery.of(context).size.height * 0.8,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        // Header - العنوان
        // Image - الصورة
        // Product Details - تفاصيل المنتج
      ],
    ),
  ),
)
```

### 3. رأس النافذة (Header)
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(20),
    ),
  ),
  child: Row(
    children: [
      Icon(Icons.image, color: AppColors.primary, size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          productName ?? 'صورة المنتج',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close, color: Colors.grey),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
      ),
    ],
  ),
)
```

### 4. عرض الصورة
```dart
Expanded(
  child: Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _buildFullSizeImage(imageUrl),
    ),
  ),
)
```

### 5. تفاصيل المنتج (Product Details)
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[50],
    borderRadius: const BorderRadius.vertical(
      bottom: Radius.circular(20),
    ),
  ),
  child: Column(
    children: [
      // معلومات الكمية والسعر
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // الكمية
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_basket,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item['qty']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'الكمية',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // السعر
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item['price'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'ج.م',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // الإجمالي
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calculate,
              size: 24,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 12),
            Text(
              'الإجمالي: ${(item['itemTotal'] as double).toStringAsFixed(2)} ج.م',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // زر الإغلاق
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          label: const Text('إغلاق'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
  ),
)
```

## دالة عرض الصورة مع تفاصيل المنتج

### `_showProductImageDialog(BuildContext context, String? imageUrl, String? productName, Map<String, dynamic> item)`

#### المعاملات:
- `context`: سياق التطبيق
- `imageUrl`: رابط الصورة
- `productName`: اسم المنتج
- `item`: كائن يحتوي على تفاصيل المنتج (الكمية، السعر، الإجمالي)

## دالة عرض الصورة بحجم كامل

### `_buildFullSizeImage(String? imageUrl)`

#### أ. معالجة الصور الفارغة:
```dart
if (imageUrl == null || imageUrl.isEmpty) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'لا توجد صورة متاحة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
```

#### ب. معالجة صور الإنترنت:
```dart
if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
  return CachedNetworkImage(
    imageUrl: imageUrl,
    placeholder: (context, url) => Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    ),
    errorWidget: (context, url, error) => Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'خطأ في تحميل الصورة',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.contain,
  );
}
```

#### ج. معالجة الصور المحلية:
```dart
return Image.asset(
  imageUrl,
  width: double.infinity,
  height: double.infinity,
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) => Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red[300],
        ),
        const SizedBox(height: 16),
        Text(
          'خطأ في تحميل الصورة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.red[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
);
```

## الميزات المتقدمة

### 1. معالجة الأخطاء:
- عرض رسائل خطأ واضحة
- أيقونات مميزة لكل نوع خطأ
- تصميم متسق للأخطاء

### 2. حالات التحميل:
- مؤشر تحميل للصور من الإنترنت
- معالجة الصور المحلية
- عرض رسائل مناسبة

### 3. التصميم المتجاوب:
- حجم النافذة يتناسب مع حجم الشاشة
- عرض الصورة بـ `BoxFit.contain` للحفاظ على النسب
- تصميم متسق مع باقي التطبيق

### 4. تجربة المستخدم:
- إغلاق سهل بالنقر على زر الإغلاق
- عنوان واضح مع اسم المنتج
- أزرار واضحة ومفهومة

## الاستخدام

### كيفية الاستخدام:
1. انتقل إلى شاشة تفاصيل الطلب
2. ابحث عن قائمة المنتجات
3. اضغط على أي كارت منتج
4. ستظهر نافذة منبثقة مع صورة المنتج بحجم كامل
5. يمكنك إغلاق النافذة بالضغط على زر "إغلاق" أو "×"

### الميزات المستقبلية:
- [ ] إمكانية التكبير والتصغير
- [ ] عرض متعدد الصور للمنتج
- [ ] حفظ الصورة محلياً
- [ ] إضافة المزيد من التفاصيل (الوصف، التقييمات)

## النتيجة النهائية

✅ **عرض الصورة بحجم كامل**
✅ **عرض سعر المنتج والكمية**
✅ **عرض السعر الإجمالي**
✅ **تصميم احترافي ومتسق**
✅ **معالجة الأخطاء**
✅ **تجربة مستخدم سلسة**
✅ **توافق مع جميع أنواع الصور**

الآن يمكن للمستخدمين عرض صور المنتجات مع جميع التفاصيل المهمة عند الضغط على كارت المنتج! 🖼️💰✨ 