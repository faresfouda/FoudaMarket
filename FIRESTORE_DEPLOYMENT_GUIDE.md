# دليل نشر إعدادات Firestore

## الخطوات السريعة

### 1. نشر قواعد الأمان

```bash
# في terminal
firebase deploy --only firestore:rules
```

### 2. نشر Indexes

```bash
# في terminal
firebase deploy --only firestore:indexes
```

### 3. نشر كل شيء مرة واحدة

```bash
# في terminal
firebase deploy --only firestore
```

## التحقق من النشر

### 1. التحقق من قواعد الأمان:
1. افتح [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. انتقل إلى **Firestore Database**
4. اضغط على تبويب **Rules**
5. تأكد من وجود قواعد المراجعات

### 2. التحقق من Indexes:
1. في نفس الصفحة، اضغط على تبويب **Indexes**
2. تأكد من وجود الـ 6 indexes التالية:
   - `reviews` - `status` (Ascending), `created_at` (Descending)
   - `reviews` - `product_id` (Ascending), `status` (Ascending), `created_at` (Descending)
   - `reviews` - `user_id` (Ascending), `created_at` (Descending)
   - `reviews` - `review_text` (Ascending)
   - `reviews` - `product_name` (Ascending)
   - `reviews` - `user_name` (Ascending)

## اختبار النظام

### 1. اختبار إنشاء مراجعة:
```dart
// في التطبيق
final reviewService = ReviewService();
await reviewService.seedFakeReviews();
```

### 2. اختبار قراءة المراجعات:
```dart
// في التطبيق
final reviews = await reviewService.getAllReviews();
print('عدد المراجعات: ${reviews.length}');
```

### 3. اختبار البحث:
```dart
// في التطبيق
final searchResults = await reviewService.searchReviews('طماطم');
print('نتائج البحث: ${searchResults.length}');
```

## استكشاف الأخطاء

### 1. إذا فشل النشر:
```bash
# تحقق من الأخطاء
firebase deploy --only firestore --debug
```

### 2. إذا لم تعمل الاستعلامات:
- تحقق من وجود Indexes المطلوبة
- انتظر بضع دقائق حتى يتم إنشاء Indexes
- تحقق من قواعد الأمان

### 3. إذا لم تظهر البيانات:
- تحقق من وجود collection `reviews`
- تأكد من صحة قواعد الأمان
- تحقق من دور المستخدم (admin/data_entry)

## الملفات المحدثة

✅ `firestore.rules` - قواعد الأمان
✅ `firestore.indexes.json` - تعريف Indexes
✅ `firebase.json` - إعدادات Firebase

## النتيجة النهائية

بعد النشر، سيكون لديك:
- ✅ Collection `reviews` جاهز للاستخدام
- ✅ قواعد أمان محمية
- ✅ Indexes محسنة للأداء
- ✅ نظام مراجعات متكامل

الآن يمكنك استخدام نظام المراجعات بكامل طاقته! 🚀 