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
  final bool isVisible; // للتحكم في إظهار/إخفاء المنتج للمستخدم
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductUnit>? units; // وحدات إضافية مع أسعارها

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
    this.isVisible = true, // المنتج ظاهر للمستخدم افتراضياً
    this.stockQuantity = 0,
    required this.createdAt,
    required this.updatedAt,
    this.units,
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
      isVisible: json['is_visible'] ?? true,
      stockQuantity: json['stock_quantity'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      units: json['units'] != null 
          ? List<ProductUnit>.from(
              (json['units'] as List).map((x) => ProductUnit.fromJson(x))
            )
          : null,
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
      'is_visible': isVisible,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'units': units?.map((x) => x.toJson()).toList(),
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
    bool? isVisible,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductUnit>? units,
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
      isVisible: isVisible ?? this.isVisible,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      units: units ?? this.units,
    );
  }
}

class ProductUnit {
  final String id;
  final String name; // مثل: "2 كيلو"، "500 جرام"
  final double price;
  final double? originalPrice;
  final bool isSpecialOffer;
  final int stockQuantity;
  final bool isActive;
  final bool isPrimary; // للتمييز بين الوحدة الأساسية والوحدات الإضافية

  ProductUnit({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.isSpecialOffer = false,
    this.stockQuantity = 0,
    this.isActive = true,
    this.isPrimary = false, // افتراضياً ليست وحدة أساسية
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null 
          ? (json['original_price'] as num).toDouble() 
          : null,
      isSpecialOffer: json['is_special_offer'] ?? false,
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] ?? true,
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'original_price': originalPrice,
      'is_special_offer': isSpecialOffer,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'is_primary': isPrimary,
    };
  }

  double get discountPercentage {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  ProductUnit copyWith({
    String? id,
    String? name,
    double? price,
    double? originalPrice,
    bool? isSpecialOffer,
    int? stockQuantity,
    bool? isActive,
    bool? isPrimary,
  }) {
    return ProductUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      isSpecialOffer: isSpecialOffer ?? this.isSpecialOffer,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
} 