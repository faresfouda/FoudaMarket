# إعدادات Firestore لنظام المراجعات

## 1. إنشاء Collection

### Collection Name: `reviews`

```javascript
// إنشاء collection جديد في Firestore
Collection ID: reviews
```

## 2. قواعد الأمان (Security Rules)

### إضافة قواعد الأمان في `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // قواعد المراجعات
    match /reviews/{reviewId} {
      // قراءة المراجعات - المديرين يمكنهم قراءة جميع المراجعات
      allow read: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'data_entry');
      
      // كتابة المراجعات - المديرين يمكنهم إنشاء وتحديث وحذف
      allow write: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'data_entry');
      
      // المستخدمين العاديين يمكنهم إنشاء مراجعات خاصة بهم فقط
      allow create: if request.auth != null && 
        request.auth.uid == resource.data.user_id;
      
      // المستخدمين العاديين يمكنهم تحديث مراجعاتهم الخاصة فقط
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.user_id;
    }
    
    // قواعد المستخدمين (إذا لم تكن موجودة)
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## 3. Indexes المطلوبة

### أ. Indexes الأساسية:

#### 1. مراجعات حسب الحالة والتاريخ:
```javascript
Collection ID: reviews
Fields:
- status (Ascending)
- created_at (Descending)
```

#### 2. مراجعات منتج معين:
```javascript
Collection ID: reviews
Fields:
- product_id (Ascending)
- status (Ascending)
- created_at (Descending)
```

#### 3. مراجعات مستخدم معين:
```javascript
Collection ID: reviews
Fields:
- user_id (Ascending)
- created_at (Descending)
```

### ب. Indexes للبحث:

#### 4. البحث في نص المراجعة:
```javascript
Collection ID: reviews
Fields:
- review_text (Ascending)
```

#### 5. البحث في اسم المنتج:
```javascript
Collection ID: reviews
Fields:
- product_name (Ascending)
```

#### 6. البحث في اسم المستخدم:
```javascript
Collection ID: reviews
Fields:
- user_name (Ascending)
```

## 4. إنشاء Indexes في Firebase Console

### الخطوات:

1. **افتح Firebase Console**
2. **انتقل إلى Firestore Database**
3. **اضغط على تبويب "Indexes"**
4. **اضغط "Create Index"**

### إنشاء كل index:

#### Index 1:
```
Collection ID: reviews
Fields:
- Field path: status, Order: Ascending
- Field path: created_at, Order: Descending
```

#### Index 2:
```
Collection ID: reviews
Fields:
- Field path: product_id, Order: Ascending
- Field path: status, Order: Ascending
- Field path: created_at, Order: Descending
```

#### Index 3:
```
Collection ID: reviews
Fields:
- Field path: user_id, Order: Ascending
- Field path: created_at, Order: Descending
```

#### Index 4:
```
Collection ID: reviews
Fields:
- Field path: review_text, Order: Ascending
```

#### Index 5:
```
Collection ID: reviews
Fields:
- Field path: product_name, Order: Ascending
```

#### Index 6:
```
Collection ID: reviews
Fields:
- Field path: user_name, Order: Ascending
```

## 5. إعدادات Firebase CLI (اختياري)

### تحديث ملف `firebase.json`:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

### إنشاء ملف `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "created_at",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "product_id",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "created_at",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "user_id",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "created_at",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "review_text",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "product_name",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "user_name",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

## 6. إعدادات الأمان الإضافية

### أ. قواعد متقدمة للأمان:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // دالة للتحقق من دور المستخدم
    function isAdmin() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isDataEntry() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'data_entry';
    }
    
    function isAdminOrDataEntry() {
      return isAdmin() || isDataEntry();
    }
    
    // قواعد المراجعات
    match /reviews/{reviewId} {
      // قراءة المراجعات
      allow read: if request.auth != null && 
        (isAdminOrDataEntry() || 
         resource.data.user_id == request.auth.uid);
      
      // إنشاء مراجعات جديدة
      allow create: if request.auth != null && 
        (isAdminOrDataEntry() || 
         request.resource.data.user_id == request.auth.uid);
      
      // تحديث المراجعات
      allow update: if request.auth != null && 
        (isAdminOrDataEntry() || 
         resource.data.user_id == request.auth.uid);
      
      // حذف المراجعات (فقط المديرين)
      allow delete: if request.auth != null && isAdminOrDataEntry();
      
      // التحقق من صحة البيانات
      allow write: if request.auth != null && 
        (isAdminOrDataEntry() || 
         request.resource.data.user_id == request.auth.uid) &&
        request.resource.data.rating >= 1.0 &&
        request.resource.data.rating <= 5.0 &&
        request.resource.data.review_text.size() > 0 &&
        request.resource.data.review_text.size() <= 1000;
    }
  }
}
```

### ب. قواعد للتحقق من صحة البيانات:

```javascript
// التحقق من صحة التقييم
function isValidRating(rating) {
  return rating >= 1.0 && rating <= 5.0;
}

// التحقق من طول نص المراجعة
function isValidReviewText(text) {
  return text.size() > 0 && text.size() <= 1000;
}

// التحقق من صحة الحالة
function isValidStatus(status) {
  return status in ['pending', 'approved', 'rejected'];
}
```

## 7. إعدادات الأداء

### أ. تحسين الاستعلامات:

```javascript
// استعلام محسن للحصول على مراجعات منتج معين
// استخدم هذا الاستعلام في الكود
const reviews = await firestore
  .collection('reviews')
  .where('product_id', '==', productId)
  .where('status', '==', 'approved')
  .orderBy('created_at', 'desc')
  .limit(20) // تحديد عدد النتائج
  .get();
```

### ب. Pagination:

```javascript
// إضافة pagination للاستعلامات الكبيرة
const reviews = await firestore
  .collection('reviews')
  .orderBy('created_at', 'desc')
  .limit(10)
  .startAfter(lastDocument) // للصفحة التالية
  .get();
```

## 8. مراقبة الأداء

### أ. إعدادات المراقبة:

```javascript
// في Firebase Console
// انتقل إلى Performance Monitoring
// أضف custom traces للمراجعات

// في الكود
import 'package:firebase_performance/firebase_performance.dart';

Future<void> loadReviews() async {
  final trace = FirebasePerformance.instance.newTrace('load_reviews');
  await trace.start();
  
  try {
    // كود تحميل المراجعات
    await _reviewService.getAllReviews();
  } finally {
    await trace.stop();
  }
}
```

## 9. النسخ الاحتياطي

### أ. إعداد النسخ الاحتياطي التلقائي:

```javascript
// في Firebase Console
// انتقل إلى Firestore Database
// اضغط على Settings
// فعّل Automated backups
// اختر التكرار (يومي/أسبوعي)
```

## 10. اختبار الإعدادات

### أ. اختبار القواعد:

```javascript
// في Firebase Console
// انتقل إلى Firestore Database
// اضغط على Rules
// اضغط "Test rules"
// اختبر السيناريوهات المختلفة
```

### ب. اختبار Indexes:

```javascript
// تأكد من أن جميع الاستعلامات تعمل
// راقب استخدام Indexes في Firebase Console
// انتقل إلى Usage > Indexes
```

## النتيجة النهائية

✅ **Collection `reviews` جاهز**
✅ **قواعد الأمان محمية**
✅ **Indexes محسنة للأداء**
✅ **مراقبة الأداء مفعلة**
✅ **نسخ احتياطي تلقائي**

الآن نظام المراجعات جاهز للعمل بكفاءة عالية! 🚀 