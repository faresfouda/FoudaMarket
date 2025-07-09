class OrderModel {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double? discountAmount;
  final double total;
  final String status; // 'pending', 'accepted', 'preparing', 'delivering', 'delivered', 'cancelled', 'failed'
  final String? deliveryAddress;
  final String? deliveryNotes;
  final DateTime? estimatedDeliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? promoCodeId;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    this.discountAmount,
    required this.total,
    required this.status,
    this.deliveryAddress,
    this.deliveryNotes,
    this.estimatedDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
    this.promoCodeId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discountAmount: json['discount_amount'] != null 
          ? (json['discount_amount'] as num).toDouble() 
          : null,
      total: (json['total'] as num).toDouble(),
      status: json['status'],
      deliveryAddress: json['delivery_address'],
      deliveryNotes: json['delivery_notes'],
      estimatedDeliveryTime: json['estimated_delivery_time'] != null 
          ? DateTime.parse(json['estimated_delivery_time']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      promoCodeId: json['promo_code_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'total': total,
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_notes': deliveryNotes,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'promo_code_id': promoCodeId,
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
    String? deliveryNotes,
    DateTime? estimatedDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? promoCodeId,
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
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      promoCodeId: promoCodeId ?? this.promoCodeId,
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
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      total: (json['total'] as num).toDouble(),
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