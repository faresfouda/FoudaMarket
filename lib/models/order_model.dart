import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double? discountAmount;
  final double total;
  final String
  status; // 'pending', 'accepted', 'preparing', 'delivering', 'delivered', 'cancelled', 'failed'
  final String? deliveryAddress;
  final String? deliveryAddressName;
  final String? deliveryPhone;
  final String? deliveryNotes;
  final DateTime? estimatedDeliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? promoCodeId;
  final String? promoCode; // كود الخصم المستخدم
  final double? promoCodeDiscountPercentage; // نسبة الخصم من كود الخصم
  final double? promoCodeMaxDiscount; // الحد الأقصى للخصم من كود الخصم
  final String? customerName; // اسم العميل
  final String? customerPhone; // رقم هاتف العميل

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    this.discountAmount,
    required this.total,
    required this.status,
    this.deliveryAddress,
    this.deliveryAddressName,
    this.deliveryPhone,
    this.deliveryNotes,
    this.estimatedDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
    this.promoCodeId,
    this.promoCode,
    this.promoCodeDiscountPercentage,
    this.promoCodeMaxDiscount,
    this.customerName,
    this.customerPhone,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : null,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      deliveryAddress: json['delivery_address'],
      deliveryAddressName: json['delivery_address_name'],
      deliveryPhone: json['delivery_phone'],
      deliveryNotes: json['delivery_notes'],
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? _parseTimestamp(json['estimated_delivery_time'])
          : null,
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(json['updated_at']) ?? DateTime.now(),
      promoCodeId: json['promo_code_id'],
      promoCode: json['promo_code'],
      promoCodeDiscountPercentage:
          json['promo_code_discount_percentage'] != null
          ? (json['promo_code_discount_percentage'] as num).toDouble()
          : null,
      promoCodeMaxDiscount: json['promo_code_max_discount'] != null
          ? (json['promo_code_max_discount'] as num).toDouble()
          : null,
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'total': total,
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_address_name': deliveryAddressName,
      'delivery_phone': deliveryPhone,
      'delivery_notes': deliveryNotes,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'promo_code_id': promoCodeId,
      'promo_code': promoCode,
      'promo_code_discount_percentage': promoCodeDiscountPercentage,
      'promo_code_max_discount': promoCodeMaxDiscount,
      'customer_name': customerName,
      'customer_phone': customerPhone,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<OrderItemModel>? items,
    double? subtotal,
    double? discountAmount,
    double? total,
    String? status,
    String? deliveryAddress,
    String? deliveryAddressName,
    String? deliveryPhone,
    String? deliveryNotes,
    DateTime? estimatedDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? promoCodeId,
    String? promoCode,
    double? promoCodeDiscountPercentage,
    double? promoCodeMaxDiscount,
    String? customerName,
    String? customerPhone,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressName: deliveryAddressName ?? this.deliveryAddressName,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      promoCode: promoCode ?? this.promoCode,
      promoCodeDiscountPercentage:
          promoCodeDiscountPercentage ?? this.promoCodeDiscountPercentage,
      promoCodeMaxDiscount: promoCodeMaxDiscount ?? this.promoCodeMaxDiscount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
}

class OrderItemModel {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double total;

  OrderItemModel({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}
