import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/address_model.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'addresses';

  Future<List<AddressModel>> getUserAddresses(String userId) async {
    try {
      if (userId.isEmpty) {
        print('AddressService: userId is empty');
        return [];
      }

      final querySnapshot = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('AddressService: Found ${querySnapshot.docs.length} addresses for user $userId');

      final addresses = <AddressModel>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final address = AddressModel.fromJson(data);
          addresses.add(address);
        } catch (e) {
          print('Error parsing address document ${doc.id}: $e');
          // Skip this document and continue with others
          continue;
        }
      }

      // Ensure only one default address exists
      await _ensureSingleDefaultAddress(userId, addresses);

      return addresses;
    } catch (e) {
      print('Error getting user addresses: $e');
      throw Exception('فشل في تحميل العناوين: ${e.toString()}');
    }
  }

  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      if (userId.isEmpty) return null;

      // First, try to get the default address
      final defaultQuery = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (defaultQuery.docs.isNotEmpty) {
        final data = defaultQuery.docs.first.data();
        data['id'] = defaultQuery.docs.first.id;
        return AddressModel.fromJson(data);
      }

      // If no default address found, try to get the first address
      final allAddresses = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (allAddresses.docs.isNotEmpty) {
        final data = allAddresses.docs.first.data();
        data['id'] = allAddresses.docs.first.id;
        final address = AddressModel.fromJson(data);

        // Set this address as default
        await setDefaultAddress(userId, address.id);

        return address.copyWith(isDefault: true);
      }

      return null;
    } catch (e) {
      print('Error getting default address: $e');
      return null;
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      if (userId.isEmpty || addressId.isEmpty) {
        throw Exception('معرف المستخدم أو العنوان غير صحيح');
      }

      final batch = _firestore.batch();

      // First: Set all addresses to non-default
      final allAddressesQuery = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in allAddressesQuery.docs) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': Timestamp.now(),
        });
      }

      // Second: Set the specified address as default
      final addressRef = _firestore.collection(collection).doc(addressId);
      batch.update(addressRef, {
        'isDefault': true,
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
      print('Default address set successfully for user $userId');
    } catch (e) {
      print('Error setting default address: $e');
      throw Exception('فشل في تعيين العنوان الافتراضي: ${e.toString()}');
    }
  }

  Future<void> addAddress(AddressModel address) async {
    try {
      // Validate address data
      if (address.userId.isEmpty) {
        throw Exception('معرف المستخدم مطلوب');
      }
      if (address.name.isEmpty) {
        throw Exception('اسم العنوان مطلوب');
      }
      if (address.address.isEmpty) {
        throw Exception('تفاصيل العنوان مطلوبة');
      }

      // If this is the first address or marked as default, handle default setting
      final existingAddresses = await getUserAddresses(address.userId);
      final isFirstAddress = existingAddresses.isEmpty;

      if (address.isDefault || isFirstAddress) {
        await _setAllAddressesNonDefault(address.userId);
      }

      final addressToAdd = address.copyWith(
        isDefault: address.isDefault || isFirstAddress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(collection)
          .add(addressToAdd.toFirestore());

      // Update with the document ID
      await docRef.update({'id': docRef.id});

      print('Address added successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding address: $e');
      throw Exception('فشل في إضافة العنوان: ${e.toString()}');
    }
  }

  Future<void> updateAddress(AddressModel address) async {
    try {
      if (address.id.isEmpty) {
        throw Exception('معرف العنوان مطلوب');
      }
      if (address.userId.isEmpty) {
        throw Exception('معرف المستخدم مطلوب');
      }

      // If setting as default, make other addresses non-default
      if (address.isDefault) {
        await _setAllAddressesNonDefault(address.userId);
      }

      final updatedAddress = address.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(collection)
          .doc(address.id)
          .update(updatedAddress.toFirestore());

      print('Address updated successfully: ${address.id}');
    } catch (e) {
      print('Error updating address: $e');
      throw Exception('فشل في تحديث العنوان: ${e.toString()}');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      if (addressId.isEmpty) {
        throw Exception('معرف العنوان مطلوب');
      }

      // Get address data before deletion
      final doc = await _firestore.collection(collection).doc(addressId).get();
      if (!doc.exists) {
        throw Exception('العنوان غير موجود');
      }

      final data = doc.data()!;
      final isDefault = data['isDefault'] ?? false;
      final userId = data['user_id'];

      // Delete the address
      await _firestore.collection(collection).doc(addressId).delete();

      // If the deleted address was default, set another address as default
      if (isDefault && userId != null) {
        await _setFirstAddressAsDefault(userId);
      }

      print('Address deleted successfully: $addressId');
    } catch (e) {
      print('Error deleting address: $e');
      throw Exception('فشل في حذف العنوان: ${e.toString()}');
    }
  }

  // Helper method to ensure only one default address exists
  Future<void> _ensureSingleDefaultAddress(String userId, List<AddressModel> addresses) async {
    try {
      final defaultAddresses = addresses.where((addr) => addr.isDefault).toList();

      if (defaultAddresses.length > 1) {
        // Multiple default addresses found, fix this
        final batch = _firestore.batch();

        // Keep the first one as default, make others non-default
        for (int i = 1; i < defaultAddresses.length; i++) {
          final addressRef = _firestore.collection(collection).doc(defaultAddresses[i].id);
          batch.update(addressRef, {
            'isDefault': false,
            'updatedAt': Timestamp.now(),
          });
        }

        await batch.commit();
        print('Fixed multiple default addresses for user $userId');
      } else if (defaultAddresses.isEmpty && addresses.isNotEmpty) {
        // No default address, set the first one as default
        await setDefaultAddress(userId, addresses.first.id);
      }
    } catch (e) {
      print('Error ensuring single default address: $e');
    }
  }

  // Helper method to set all addresses as non-default
  Future<void> _setAllAddressesNonDefault(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'isDefault': false,
            'updatedAt': Timestamp.now(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error setting all addresses non-default: $e');
    }
  }

  // Helper method to set the first address as default
  Future<void> _setFirstAddressAsDefault(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'isDefault': true,
          'updatedAt': Timestamp.now(),
        });
        print('Set first address as default for user $userId');
      }
    } catch (e) {
      print('Error setting first address as default: $e');
    }
  }

  // Method to validate user has permission to access/modify address
  Future<bool> _validateAddressOwnership(String addressId, String userId) async {
    try {
      final doc = await _firestore.collection(collection).doc(addressId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['user_id'] == userId;
    } catch (e) {
      print('Error validating address ownership: $e');
      return false;
    }
  }
}
