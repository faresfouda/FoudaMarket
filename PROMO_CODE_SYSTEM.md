# نظام إدارة أكواد الخصم - Fouda Market

## نظرة عامة

تم تنفيذ نظام إدارة أكواد الخصم الكامل للمشروع مع واجهة إدارية متقدمة للمديرين وواجهة عرض للمستخدمين. النظام يدعم جميع العمليات الأساسية لإدارة أكواد الخصم مع التحقق من الصلاحية والقيود.

## التحكم في الصلاحيات

### 🔐 نظام التحكم في الصلاحيات

النظام يضمن أن **المديرين فقط** يمكنهم إدارة أكواد الخصم:

#### 1. التحقق من الصلاحيات في الخدمة
```dart
// التحقق من صلاحيات المدير
Future<bool> _isAdmin() async {
  try {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return false;
    
    final userData = userDoc.data()!;
    return userData['role'] == 'admin';
  } catch (e) {
    print('Error checking admin permissions: $e');
    return false;
  }
}
```

#### 2. حماية جميع العمليات الإدارية
- ✅ **إنشاء أكواد الخصم**: المدير فقط
- ✅ **تحديث أكواد الخصم**: المدير فقط  
- ✅ **حذف أكواد الخصم**: المدير فقط
- ✅ **تفعيل/إلغاء تفعيل**: المدير فقط
- ✅ **عرض الإحصائيات**: المدير فقط

#### 3. واجهة المستخدم المحمية
```dart
// التحقق من أن المستخدم مدير
if (authState is! Authenticated || 
    authState.userProfile == null || 
    authState.userProfile!.role != 'admin') {
  return _buildUnauthorizedScreen();
}
```

#### 4. رسائل خطأ واضحة
- "غير مصرح لك بإنشاء أكواد الخصم. يجب أن تكون مديراً."
- "غير مصرح لك بتحديث أكواد الخصم. يجب أن تكون مديراً."
- "غير مصرح لك بحذف أكواد الخصم. يجب أن تكون مديراً."

### 👥 وصول المستخدمين العاديين

المستخدمون العاديون يمكنهم:
- ✅ **عرض أكواد الخصم الصالحة فقط**
- ✅ **استخدام أكواد الخصم في الطلبات**
- ❌ **لا يمكنهم إدارة الأكواد**

## المكونات الرئيسية

### 1. نموذج البيانات (Models)

#### `PromoCodeModel`
```dart
class PromoCodeModel {
  final String id;
  final String code;
  final String description;
  final double discountPercentage;
  final double? maxDiscountAmount; // الحد الأقصى للخصم
  final double? minOrderAmount; // الحد الأدنى للطلب
  final int maxUsageCount; // عدد مرات الاستخدام الأقصى
  final int currentUsageCount; // عدد مرات الاستخدام الحالي
  final DateTime expiryDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // معرف المدير الذي أنشأ الكود

  // خصائص محسوبة
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isUsageLimitReached => currentUsageCount >= maxUsageCount;
  bool get isValid => isActive && !isExpired && !isUsageLimitReached;
}
```

### 2. الخدمات (Services)

#### `PromoCodeService`
```dart
class PromoCodeService {
  // العمليات الإدارية (المدير فقط)
  Future<void> createPromoCode(PromoCodeModel promoCode);
  Future<void> updatePromoCode(String promoCodeId, Map<String, dynamic> data);
  Future<void> deletePromoCode(String promoCodeId);
  Future<void> togglePromoCodeStatus(String promoCodeId, bool isActive);
  
  // العمليات العامة
  Future<List<PromoCodeModel>> getAllPromoCodes(); // للمديرين
  Future<List<PromoCodeModel>> getValidPromoCodes(); // للمستخدمين
  Future<PromoCodeModel?> getPromoCodeByCode(String code);
  Future<Map<String, dynamic>> validatePromoCode(String code, double orderAmount);
  Future<Map<String, dynamic>> getPromoCodeStats(); // للمديرين
}
```

### 3. إدارة الحالة (State Management)

#### Events
```dart
// الأحداث الإدارية
class CreatePromoCode extends PromoCodeEvent;
class UpdatePromoCode extends PromoCodeEvent;
class DeletePromoCode extends PromoCodeEvent;
class TogglePromoCodeStatus extends PromoCodeEvent;
class LoadPromoCodeStats extends PromoCodeEvent;

// الأحداث العامة
class LoadPromoCodes extends PromoCodeEvent; // للمديرين
class LoadValidPromoCodes extends PromoCodeEvent; // للمستخدمين
class ValidatePromoCode extends PromoCodeEvent;
```

#### States
```dart
class PromoCodeInitial extends PromoCodeState;
class PromoCodeLoading extends PromoCodeState;
class PromoCodesLoaded extends PromoCodeState;
class PromoCodeCreated extends PromoCodeState;
class PromoCodeUpdated extends PromoCodeState;
class PromoCodeDeleted extends PromoCodeState;
class PromoCodeError extends PromoCodeState;
class PromoCodeEmpty extends PromoCodeState;
```

### 4. واجهات المستخدم (UI)

#### شاشة إدارة أكواد الخصم (المديرين)
- `lib/views/admin/promo_codes_screen.dart`
- عرض جميع الأكواد مع إحصائيات
- إمكانية الإضافة والتعديل والحذف
- تفعيل/إلغاء تفعيل الأكواد

#### شاشة إضافة/تعديل كود الخصم (المديرين)
- `lib/views/admin/add_edit_promo_code_screen.dart`
- نموذج شامل لإنشاء وتعديل الأكواد
- التحقق من صحة البيانات
- خيارات متقدمة (حدود الخصم والطلب)

#### شاشة عرض أكواد الخصم (المستخدمين)
- `lib/views/profile/promo_code_screen.dart`
- عرض الأكواد الصالحة فقط
- معلومات مفصلة عن كل كود
- لا توجد إمكانية تعديل

## الميزات المتقدمة

### 1. التحقق من الصلاحية
```dart
Future<Map<String, dynamic>> validatePromoCode(String code, double orderAmount) {
  // التحقق من وجود الكود
  // التحقق من التفعيل
  // التحقق من انتهاء الصلاحية
  // التحقق من حد الاستخدام
  // التحقق من الحد الأدنى للطلب
  // حساب قيمة الخصم
}
```

### 2. الإحصائيات المتقدمة
- إجمالي عدد الأكواد
- عدد الأكواد المفعلة
- عدد الأكواد المنتهية الصلاحية
- إجمالي مرات الاستخدام
- الأكواد التي وصلت للحد الأقصى

### 3. خيارات متقدمة للأكواد
- **الحد الأقصى للخصم**: منع الخصم من تجاوز قيمة معينة
- **الحد الأدنى للطلب**: تطبيق الكود على طلبات بقيمة معينة
- **عدد مرات الاستخدام**: تحديد عدد المرات المسموح بها
- **تاريخ انتهاء الصلاحية**: تحديد مدة صلاحية الكود

## الأمان والحماية

### 1. التحقق من الصلاحيات
- كل عملية إدارية تتحقق من دور المستخدم
- رسائل خطأ واضحة للمستخدمين غير المصرح لهم
- حماية على مستوى الخدمة والواجهة

### 2. التحقق من صحة البيانات
- التحقق من عدم تكرار كود الخصم
- التحقق من صحة النسب المئوية
- التحقق من صحة التواريخ
- التحقق من صحة القيم الرقمية

### 3. تتبع العمليات
- تسجيل معرف المدير الذي أنشأ كل كود
- تسجيل تاريخ الإنشاء والتحديث
- تتبع عدد مرات الاستخدام

## الاستخدام

### للمديرين
1. تسجيل الدخول بحساب مدير
2. الانتقال إلى "إدارة أكواد الخصم"
3. إضافة أكواد خصم جديدة
4. تعديل أو حذف الأكواد الموجودة
5. مراقبة الإحصائيات

### للمستخدمين
1. الانتقال إلى "أكواد الخصم"
2. عرض الأكواد الصالحة
3. استخدام الأكواد في الطلبات
4. مراقبة حالة الأكواد

## التطوير المستقبلي

### الميزات المقترحة
- [ ] نظام أكواد الخصم المؤقتة
- [ ] أكواد خصم خاصة بفئات معينة
- [ ] نظام نقاط الولاء
- [ ] تقارير مفصلة عن استخدام الأكواد
- [ ] إشعارات للمديرين عند انتهاء صلاحية الأكواد
- [ ] نظام أكواد الخصم التلقائية

### التحسينات المقترحة
- [ ] تحسين أداء الاستعلامات
- [ ] إضافة المزيد من التحقق من الصحة
- [ ] تحسين واجهة المستخدم
- [ ] إضافة المزيد من الإحصائيات
- [ ] نظام النسخ الاحتياطي التلقائي

## الخلاصة

نظام أكواد الخصم في Fouda Market يوفر:
- ✅ **تحكم كامل للمديرين** في إدارة الأكواد
- ✅ **حماية شاملة** من الوصول غير المصرح
- ✅ **واجهة سهلة الاستخدام** للمديرين والمستخدمين
- ✅ **ميزات متقدمة** للتحكم في الأكواد
- ✅ **أمان عالي** مع التحقق من الصلاحيات
- ✅ **مرونة في التخصيص** مع الخيارات المتقدمة

النظام جاهز للاستخدام ويوفر تجربة ممتازة لإدارة أكواد الخصم مع ضمان الأمان والتحكم الكامل للمديرين. 