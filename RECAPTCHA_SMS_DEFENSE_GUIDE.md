# دليل تطبيق reCAPTCHA SMS Defense

## نظرة عامة
تم تطبيق نظام reCAPTCHA SMS Defense لحماية تطبيق Fouda Market من هجمات SMS fraud وSMS pumping. هذا النظام يوفر:

- **تحليل المخاطر قبل إرسال SMS** - تقييم كل رقم هاتف قبل إرسال رمز التحقق
- **حظر الأرقام عالية المخاطر** - منع إرسال SMS للأرقام المشبوهة
- **تتبع وتحليل الأنشطة** - مراقبة محاولات المصادقة وتحليلها
- **حماية من الاحتيال** - منع SMS toll fraud وSMS pumping attacks

## الملفات المضافة

### 1. خدمة reCAPTCHA SMS Defense
**المسار:** `lib/services/recaptcha_sms_defense.dart`

**الوظائف الرئيسية:**
```dart
// إنشاء تقييم للمخاطر
Future<SmsRiskAssessment> createAssessment({
  required String phoneNumber,
  required String accountId,
  String? token,
})

// تسجيل نتائج العمليات
Future<void> annotateAssessment({
  required String assessmentId,
  required String phoneNumber,
  required SmsEventType eventType,
  SmsAnnotation? annotation,
})

// تحديد مستوى المخاطر
bool shouldBlockSms(double riskScore)
```

### 2. ملف التكوين
**المسار:** `lib/config/recaptcha_config.dart`

**المعايير المهمة:**
- `highRiskThreshold = 0.7` (70%) - حظر فوري
- `mediumRiskThreshold = 0.4` (40%) - مراقبة إضافية
- `lowRiskThreshold = 0.2` (20%) - السماح بالمرور

### 3. تحديث AuthService
**المسار:** `lib/core/services/auth_service.dart`

**الميزات المضافة:**
- دمج reCAPTCHA مع عملية التحقق من الهاتف
- تحويل أرقام الهاتف لصيغة E.164 تلقائياً
- تسجيل جميع أحداث SMS (إرسال، نجاح، فشل)

### 4. تحديث واجهة المستخدم
**المسار:** `lib/views/auth/phone_login_screen.dart`

**التحسينات:**
- رسائل خطأ واضحة للأرقام عالية المخاطر
- حوارات تفاعلية مع حلول مقترحة
- معالجة شاملة لجميع أنواع الأخطاء

## خطوات الإعداد

### 1. إعداد Google Cloud Project
```bash
# 1. اذهب إلى Google Cloud Console
# https://console.cloud.google.com/

# 2. فعل reCAPTCHA Enterprise API
# APIs & Services > Library > reCAPTCHA Enterprise API > Enable

# 3. إنشاء Service Account
# IAM & Admin > Service Accounts > Create Service Account
# Role: reCAPTCHA Enterprise Agent
```

### 2. إعداد Firebase Console
```bash
# 1. اذهب إلى Firebase Console
# https://console.firebase.google.com/

# 2. Authentication > Settings > Phone numbers for testing
# أضف أرقام الاختبار:
+201234567890 → 123456
+201234567891 → 654321

# 3. Authentication > Settings > reCAPTCHA Enterprise
# فعل reCAPTCHA Enterprise وأضف site key
```

### 3. تحديث ملف التكوين
```dart
// lib/config/recaptcha_config.dart
class RecaptchaConfig {
  static const String projectId = 'your-actual-project-id';
  static const String apiKey = 'your-actual-api-key';
  static const String siteKey = 'your-actual-site-key';
}
```

### 4. تشغيل التطبيق
```bash
# 1. تحديث التبعيات
flutter pub get

# 2. تشغيل التطبيق
flutter run
```

## كيفية عمل النظام

### 1. تدفق العمل الأساسي
```
المستخدم يدخل رقم الهاتف
       ↓
تحويل الرقم لصيغة E.164
       ↓
إرسال طلب تقييم لـ reCAPTCHA
       ↓
تحليل درجة المخاطر
       ↓
إما السماح أو الحظر
       ↓
تسجيل النتيجة في reCAPTCHA
```

### 2. مستويات المخاطر
| الدرجة | المستوى | الإجراء |
|--------|---------|---------|
| 0.0-0.2 | منخفض | السماح فوراً |
| 0.2-0.4 | متوسط | السماح مع المراقبة |
| 0.4-0.7 | عالي | تحقق إضافي |
| 0.7-1.0 | خطير | حظر فوري |

### 3. أنواع التسجيل
- `INITIATED_TWO_FACTOR` - تم إرسال SMS
- `PASSED_TWO_FACTOR` - تم التحقق بنجاح
- `FAILED_TWO_FACTOR` - فشل التحقق

## الرسائل والأخطاء

### رسائل النجاح
- ✅ "تم إرسال رمز التحقق"
- ✅ "تم تسجيل الدخول بنجاح"
- ✅ "تم إرسال رمز جديد"

### رسائل الأخطاء
- 🚫 "تم رفض هذا الرقم لأسباب أمنية"
- ⚠️ "تم حظر الجهاز مؤقتاً بسبب كثرة الطلبات"
- 🔍 "رقم الهاتف يجب أن يبدأ بـ 01 ويكون 11 رقم"

## المراقبة والتحليل

### 1. سجلات النظام
```dart
print('🛡️ Checking SMS risk for: $phoneNumber');
print('📊 Risk assessment: score=$riskScore');
print('✅ Low risk - proceeding normally');
print('🚨 Very high risk detected - blocking immediately');
```

### 2. إحصائيات مفيدة
- عدد الطلبات المحظورة يومياً
- معدل نجاح التحقق
- الأرقام عالية المخاطر
- توزيع درجات المخاطر

## أفضل الممارسات

### 1. للتطوير
- استخدم أرقام الاختبار في Firebase Console
- فعل وضع التصحيح في RecaptchaConfig
- راقب السجلات باستمرار

### 2. للإنتاج
- استخدم مفاتيح منفصلة للإنتاج
- راقب معدلات الحظر
- اضبط عتبات المخاطر حسب البيانات

### 3. الأمان
- لا تخزن المفاتيح في الكود
- استخدم متغيرات البيئة
- راجع الصلاحيات بانتظام

## استكشاف الأخطاء

### مشاكل شائعة وحلولها

| المشكلة | السبب | الحل |
|---------|-------|------|
| "Assessment failed: 401" | مفتاح API خاطئ | تحقق من API key |
| "Project not found" | معرف المشروع خاطئ | تحقق من project ID |
| "reCAPTCHA not initialized" | تكوين خاطئ | راجع RecaptchaConfig |
| "High risk detected" | رقم مشبوه | استخدم رقم آخر |

### أوامر التشخيص
```bash
# فحص التبعيات
flutter pub deps

# فحص الأخطاء
flutter analyze

# تشغيل الاختبارات
flutter test
```

## التكاليف المتوقعة

### Google Cloud reCAPTCHA Enterprise
- **أول 1000 تقييم شهرياً:** مجاني
- **بعد ذلك:** $1 لكل 1000 تقييم
- **التسجيل:** مجاني

### Firebase Authentication
- **SMS:** تكلفة حسب المزود
- **التحقق:** مجاني

## الخلاصة

تم تطبيق نظام reCAPTCHA SMS Defense بنجاح في تطبيق Fouda Market مع:

✅ **حماية شاملة** من SMS fraud  
✅ **واجهة مستخدم محسنة** مع رسائل واضحة  
✅ **نظام تسجيل متقدم** لتحليل الأنشطة  
✅ **إعدادات مرنة** للبيئات المختلفة  
✅ **مقاومة الأخطاء** مع نظام fallback  

النظام جاهز للاستخدام ويوفر حماية قوية ضد محاولات الاحتيال عبر SMS!
