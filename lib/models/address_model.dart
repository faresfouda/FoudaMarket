import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String name;
  final String address;
  final String phone;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.phone,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    try {
      return AddressModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'عنوان غير محدد',
        address: json['address']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        isDefault: json['isDefault'] == true || json['isDefault'] == 'true',
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('Error parsing AddressModel: $e');
      print('JSON data: $json');
      // Return a default address model in case of parsing error
      return AddressModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        name: 'عنوان غير محدد',
        address: 'عنوان غير صحيح',
        phone: '',
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }

    if (dateTime is String) {
      final parsed = DateTime.tryParse(dateTime);
      if (parsed != null) return parsed;
    }

    if (dateTime is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name.isNotEmpty ? name : 'عنوان غير محدد',
      'address': address,
      'phone': phone,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name.isNotEmpty ? name : 'عنوان غير محدد',
      'address': address,
      'phone': phone,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    String? phone,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AddressModel{id: $id, name: $name, address: $address, phone: $phone, isDefault: $isDefault}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        address.hashCode ^
        phone.hashCode ^
        isDefault.hashCode;
  }

  // Validation methods
  bool get isValid => name.isNotEmpty && address.isNotEmpty;
  bool get hasValidPhone => phone.isNotEmpty && phone.length >= 10;
}
