import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/category_model.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to check if current user is admin
  Future<bool> _isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['role'] == 'admin';
    } catch (e) {
      print('Error checking user role: $e');
      return false;
    }
  }

  // Basic category methods
  Future<List<CategoryModel>> getCategories() async {
    final querySnapshot = await _firestore.collection('categories').get();
    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return CategoryModel.fromJson(data);
        })
        .toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    // إنشاء ID تلقائي إذا كان فارغاً
    final docRef = category.id.isEmpty
        ? _firestore.collection('categories').doc()
        : _firestore.collection('categories').doc(category.id);

    // تحديث الفئة بالـ ID الجديد
    final categoryData = category.toJson();
    categoryData['id'] = docRef.id;
    categoryData['createdAt'] = FieldValue.serverTimestamp();
    categoryData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(categoryData);
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    await _firestore.collection('categories').doc(categoryId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    // التحقق من صلاحيات المدير قبل الحذف
    final isAdmin = await _isCurrentUserAdmin();
    if (!isAdmin) {
      throw Exception('غير مسموح! صلاحية حذف الفئات مقتصرة على المدير فقط');
    }

    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // Pagination methods
  Future<List<CategoryModel>> getCategoriesPaginated({int limit = 20, CategoryModel? lastCategory}) async {
    var query = _firestore.collection('categories').orderBy('created_at').limit(limit);
    if (lastCategory != null) {
      query = query.startAfter([lastCategory.createdAt.toIso8601String()]);
    }
    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return CategoryModel.fromJson(data);
    }).toList();
  }

  // Search methods
  Future<List<CategoryModel>> searchCategories(String query) async {
    if (query.trim().isEmpty) {
      return getCategories();
    }

    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThan: '${query.trim()}\uf8ff')
          .orderBy('name')
          .orderBy('created_at')
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return CategoryModel.fromJson(data);
          })
          .toList();
    } catch (e) {
      print('Error searching categories: $e');
      return [];
    }
  }

  Future<List<CategoryModel>> searchCategoriesPaginated({
    required String query,
    int limit = 10,
    CategoryModel? lastCategory,
  }) async {
    if (query.trim().isEmpty) {
      return getCategoriesPaginated(limit: limit, lastCategory: lastCategory);
    }

    try {
      var firestoreQuery = _firestore
          .collection('categories')
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThan: '${query.trim()}\uf8ff')
          .orderBy('name')
          .orderBy('created_at')
          .limit(limit);

      if (lastCategory != null) {
        firestoreQuery = firestoreQuery.startAfter([
          lastCategory.name,
          lastCategory.createdAt.toIso8601String(),
        ]);
      }

      final querySnapshot = await firestoreQuery.get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return CategoryModel.fromJson(data);
          })
          .toList();
    } catch (e) {
      print('Error searching categories with pagination: $e');
      return [];
    }
  }

  // Home screen methods
  Future<List<CategoryModel>> getHomeCategories({int limit = 8}) async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CategoryModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting home categories: $e');
      return [];
    }
  }
}
