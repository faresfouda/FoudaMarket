import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// تسجيل الدخول بالجوجل
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // التحقق من إمكانية تسجيل الدخول
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // بدء عملية تسجيل الدخول
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // المستخدم ألغى عملية تسجيل الدخول
        return null;
      }

      // الحصول على بيانات المصادقة من Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // إنشاء credential للـ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول في Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // حفظ بيانات المستخدم في Firestore
      await _saveUserToFirestore(userCredential.user!, googleUser);

      return userCredential;
    } catch (e) {
      print('خطأ في تسجيل الدخول بالجوجل: $e');
      rethrow;
    }
  }

  /// ربط حساب Google بالمستخدم الحالي
  Future<UserCredential?> linkGoogleAccount() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      // التحقق من عدم ربط Google مسبقاً
      final List<String> linkedProviders = currentUser.providerData
          .map((provider) => provider.providerId)
          .toList();

      if (linkedProviders.contains('google.com')) {
        throw Exception('حساب Google مربوط مسبقاً');
      }

      // الحصول على بيانات Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ربط الحساب
      final UserCredential userCredential =
          await currentUser.linkWithCredential(credential);

      // تحديث بيانات المستخدم
      await _updateUserWithGoogleData(userCredential.user!, googleUser);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "provider-already-linked":
          throw Exception("حساب Google مربوط مسبقاً بهذا المستخدم");
        case "invalid-credential":
          throw Exception("بيانات المصادقة غير صحيحة");
        case "credential-already-in-use":
          throw Exception("هذا الحساب مستخدم بالفعل مع مستخدم آخر");
        case "email-already-in-use":
          throw Exception("البريد الإلكتروني مستخدم بالفعل");
        default:
          throw Exception("خطأ غير معروف: ${e.message}");
      }
    } catch (e) {
      print('خطأ في ربط حساب Google: $e');
      rethrow;
    }
  }

  /// إلغاء ربط حساب Google
  Future<void> unlinkGoogleAccount() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      // التحقق من وجود أكثر من طريقة مصادقة
      if (currentUser.providerData.length <= 1) {
        throw Exception('لا يمكن إلغاء ربط آخر طريقة مصادقة');
      }

      await currentUser.unlink('google.com');
      await _googleSignIn.signOut();

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "no-such-provider":
          throw Exception("حساب Google غير مربوط بهذا المستخدم");
        default:
          throw Exception("خطأ في إلغاء الربط: ${e.message}");
      }
    } catch (e) {
      print('خطأ في إلغاء ربط Google: $e');
      rethrow;
    }
  }

  /// تسجيل الخروج من Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('خطأ في تسجيل الخروج من Google: $e');
    }
  }

  /// حفظ بيانات المستخدم الجديد
  Future<void> _saveUserToFirestore(User user, GoogleSignInAccount googleUser) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // مستخدم جديد - إنشاء ملف شخصي
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': googleUser.displayName ?? '',
          'email': googleUser.email,
          'phone': user.phoneNumber ?? '',
          'photoURL': googleUser.photoUrl ?? '',
          'role': 'user', // الدور الافتراضي
          'isEmailVerified': user.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'authProviders': ['google.com'],
          'googleData': {
            'id': googleUser.id,
            'displayName': googleUser.displayName,
            'email': googleUser.email,
            'photoUrl': googleUser.photoUrl,
          },
        });
      } else {
        // مستخدم موجود - تحديث البيانات
        await _updateUserWithGoogleData(user, googleUser);
      }
    } catch (e) {
      print('خطأ في حفظ بيانات المستخدم: $e');
    }
  }

  /// تحديث بيانات المستخدم بمعلومات Google
  Future<void> _updateUserWithGoogleData(User user, GoogleSignInAccount googleUser) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'isEmailVerified': user.emailVerified,
        'googleData': {
          'id': googleUser.id,
          'displayName': googleUser.displayName,
          'email': googleUser.email,
          'photoUrl': googleUser.photoUrl,
        },
      };

      // إضافة Google إلى قائمة مقدمي الخدمة
      updateData['authProviders'] = FieldValue.arrayUnion(['google.com']);

      // تحديث الاسم والصورة إذا لم تكن موجودة
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        if (userData['name'] == null || userData['name'].toString().isEmpty) {
          updateData['name'] = googleUser.displayName ?? '';
        }

        if (userData['photoURL'] == null || userData['photoURL'].toString().isEmpty) {
          updateData['photoURL'] = googleUser.photoUrl ?? '';
        }

        if (userData['email'] == null || userData['email'].toString().isEmpty) {
          updateData['email'] = googleUser.email;
        }
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      print('خطأ في تحديث بيانات المستخدم: $e');
    }
  }

  /// الحصول على معلومات مقدمي الخدمة المربوطين
  List<String> getLinkedProviders() {
    final User? user = _auth.currentUser;
    if (user == null) return [];

    return user.providerData.map((provider) => provider.providerId).toList();
  }

  /// التحقق من ربط Google
  bool isGoogleLinked() {
    return getLinkedProviders().contains('google.com');
  }

  /// الحصول على معلومات Google المرتبطة
  UserInfo? getGoogleProviderData() {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      return user.providerData.firstWhere(
        (provider) => provider.providerId == 'google.com'
      );
    } catch (e) {
      return null;
    }
  }
}
