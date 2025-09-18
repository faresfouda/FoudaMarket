import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return CartItemModel(
      id: json['id'] ?? '',
      userId: json['user_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      unit: json['unit'],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get total => price * quantity;

  CartItemModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 