class ProductModel {
  final String id;
  final String name;
  final String? description;
  final List<String> images;
  final double price;
  final double? originalPrice;
  final String unit; // kg, piece, etc.
  final String categoryId;
  final String? brand;
  final bool isBestSeller;
  final bool isSpecialOffer;
  final bool isActive;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.images,
    required this.price,
    this.originalPrice,
    required this.unit,
    required this.categoryId,
    this.brand,
    this.isBestSeller = false,
    this.isSpecialOffer = false,
    this.isActive = true,
    this.stockQuantity = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null 
          ? (json['original_price'] as num).toDouble() 
          : null,
      unit: json['unit'],
      categoryId: json['category_id'],
      brand: json['brand'],
      isBestSeller: json['is_best_seller'] ?? false,
      isSpecialOffer: json['is_special_offer'] ?? false,
      isActive: json['is_active'] ?? true,
      stockQuantity: json['stock_quantity'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'images': images,
      'price': price,
      'original_price': originalPrice,
      'unit': unit,
      'category_id': categoryId,
      'brand': brand,
      'is_best_seller': isBestSeller,
      'is_special_offer': isSpecialOffer,
      'is_active': isActive,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get discountPercentage {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? images,
    double? price,
    double? originalPrice,
    String? unit,
    String? categoryId,
    String? brand,
    bool? isBestSeller,
    bool? isSpecialOffer,
    bool? isActive,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      brand: brand ?? this.brand,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isSpecialOffer: isSpecialOffer ?? this.isSpecialOffer,
      isActive: isActive ?? this.isActive,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 