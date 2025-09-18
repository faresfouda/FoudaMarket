import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'id': credential.user!.uid,
            'email': email,
            'name': name,
            'phone': phone,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'authProvider': 'email', // إضافة مصدر المصادقة
          });

          await credential.user!.updateDisplayName(name);
        } catch (firestoreError) {
          print('Firestore error during signup: $firestoreError');
        }
      }

      return credential;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User profile methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        // تأكد أن البيانات من نوع Map
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          print('❌ User profile data is not a Map: $data');
          print('❌ Data type: ${data.runtimeType}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // دالة لإصلاح بيانات المستخدم إذا كانت تالفة
  Future<void> repairUserProfile(String userId, User user) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        // إنشاء وثيقة جديدة إذا لم تكن موجودة
        await _firestore.collection('users').doc(userId).set({
          'id': userId,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Created new user profile for: $userId');
      } else {
        final data = doc.data();
        // إذا كانت البيانات ليست Map، أعد إنشاءها
        if (data == null) {
          await _firestore.collection('users').doc(userId).set({
            'id': userId,
            'name': user.displayName ?? data?['name'] ?? 'User',
            'email': user.email ?? data?['email'] ?? '',
            'phone': user.phoneNumber ?? data?['phone'] ?? '',
            'role': data?['role'] ?? 'user',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'fcmToken': data?['fcmToken'], // احتفظ بالـ token إذا كان موجودًا
          });
          print('✅ Repaired user profile for: $userId');
        }
      }
    } catch (e) {
      print('❌ Error repairing user profile: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current admin info - يشمل المدير ومدخل البيانات
  Future<Map<String, String>?> getCurrentAdminInfo() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    // السماح للمدير ومدخل البيانات
    if (data['role'] != 'admin' && data['role'] != 'data_entry') return null;

    return {
      'id': user.uid,
      'name': data['name'] ?? user.displayName ?? user.email ?? user.uid,
    };
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
