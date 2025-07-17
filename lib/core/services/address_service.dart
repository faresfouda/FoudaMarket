import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/address_model.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'addresses';

  Future<List<AddressModel>> getUserAddresses(String userId) async {
    final querySnapshot = await _firestore
        .collection(collection)
        .where('user_id', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return AddressModel.fromJson(data);
    }).toList();
  }

  // دالة جديدة لجلب العنوان الافتراضي للمستخدم
  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      print('[DEBUG] getDefaultAddress: found default count =  [33m${querySnapshot.docs.length} [0m');
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['id'] = querySnapshot.docs.first.id;
        print('[DEBUG] getDefaultAddress: default =  [32m${data} [0m');
        return AddressModel.fromJson(data);
      }
      // إذا لم يوجد عنوان افتراضي، جرب إرجاع أول عنوان موجود كـ fallback
      final allAddresses = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (allAddresses.docs.isNotEmpty) {
        final data = allAddresses.docs.first.data();
        data['id'] = allAddresses.docs.first.id;
        print('[DEBUG] getDefaultAddress: fallback to first address =  [35m${data} [0m');
        return AddressModel.fromJson(data);
      }
      print('[DEBUG] getDefaultAddress: no address found');
      return null;
    } catch (e) {
      print('Error getting default address: $e');
      return null;
    }
  }

  // دالة جديدة لتعيين عنوان كافتراضي
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      // أولاً: جعل جميع العناوين غير افتراضية
      final allAddressesQuery = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in allAddressesQuery.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      
      // ثانياً: جعل العنوان المحدد افتراضي
      batch.update(
        _firestore.collection(collection).doc(addressId),
        {'isDefault': true}
      );
      
      await batch.commit();
    } catch (e) {
      print('Error setting default address: $e');
      rethrow;
    }
  }

  Future<void> addAddress(AddressModel address) async {
    try {
      // إذا كان العنوان الجديد افتراضي، جعل جميع العناوين الأخرى غير افتراضية
      if (address.isDefault) {
        await _setAllAddressesNonDefault(address.userId);
      }
      
      final docRef = await _firestore.collection(collection).add(address.toJson());
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('Error adding address: $e');
      rethrow;
    }
  }

  Future<void> updateAddress(AddressModel address) async {
    try {
      // إذا كان العنوان المحدث افتراضي، جعل جميع العناوين الأخرى غير افتراضية
      if (address.isDefault) {
        await _setAllAddressesNonDefault(address.userId);
      }
      
      await _firestore.collection(collection).doc(address.id).update(address.toJson());
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      // قبل الحذف، تحقق إذا كان العنوان المحذوف هو الافتراضي
      final doc = await _firestore.collection(collection).doc(addressId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final isDefault = data['isDefault'] ?? false;
        final userId = data['user_id'];
        
        await _firestore.collection(collection).doc(addressId).delete();
        
        // إذا كان العنوان المحذوف هو الافتراضي، اجعل أول عنوان آخر افتراضي
        if (isDefault) {
          await _setFirstAddressAsDefault(userId);
        }
      }
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  // دالة مساعدة لجعل جميع العناوين غير افتراضية
  Future<void> _setAllAddressesNonDefault(String userId) async {
    final querySnapshot = await _firestore
        .collection(collection)
        .where('user_id', isEqualTo: userId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }

  // دالة مساعدة لجعل أول عنوان افتراضي
  Future<void> _setFirstAddressAsDefault(String userId) async {
    final querySnapshot = await _firestore
        .collection(collection)
        .where('user_id', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({'isDefault': true});
    }
  }
} 