import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCodeModel {
  final String id;
  final String code;
  final String description;
  final double discountPercentage;
  final double? maxDiscountAmount; // الحد الأقصى للخصم
  final double? minOrderAmount; // الحد الأدنى للطلب
  final int maxUsageCount; // عدد مرات الاستخدام الأقصى
  final int currentUsageCount; // عدد مرات الاستخدام الحالي
  final DateTime expiryDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // معرف المدير الذي أنشأ الكود
  final double? fixedAmount; // مبلغ خصم ثابت

  PromoCodeModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercentage,
    this.maxDiscountAmount,
    this.minOrderAmount,
    required this.maxUsageCount,
    this.currentUsageCount = 0,
    required this.expiryDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.fixedAmount,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    // معالجة Timestamp من Firestore
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        return timestamp;
      } else {
        throw FormatException('Invalid timestamp format: $timestamp');
      }
    }

    return PromoCodeModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: json['max_discount_amount'] != null 
          ? (json['max_discount_amount'] as num).toDouble() 
          : null,
      minOrderAmount: json['min_order_amount'] != null 
          ? (json['min_order_amount'] as num).toDouble() 
          : null,
      maxUsageCount: json['max_usage_count'] ?? 0,
      currentUsageCount: json['current_usage_count'] ?? 0,
      expiryDate: parseTimestamp(json['expiry_date']),
      isActive: json['is_active'] ?? true,
      createdAt: parseTimestamp(json['created_at']),
      updatedAt: parseTimestamp(json['updated_at']),
      createdBy: json['created_by'] ?? '',
      fixedAmount: json['fixed_amount'] != null ? (json['fixed_amount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_percentage': discountPercentage,
      'max_discount_amount': maxDiscountAmount,
      'min_order_amount': minOrderAmount,
      'max_usage_count': maxUsageCount,
      'current_usage_count': currentUsageCount,
      'expiry_date': expiryDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'fixed_amount': fixedAmount,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isUsageLimitReached => currentUsageCount >= maxUsageCount;
  bool get isValid => isActive && !isExpired && !isUsageLimitReached;

  PromoCodeModel copyWith({
    String? id,
    String? code,
    String? description,
    double? discountPercentage,
    double? maxDiscountAmount,
    double? minOrderAmount,
    int? maxUsageCount,
    int? currentUsageCount,
    DateTime? expiryDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    double? fixedAmount,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxUsageCount: maxUsageCount ?? this.maxUsageCount,
      currentUsageCount: currentUsageCount ?? this.currentUsageCount,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      fixedAmount: fixedAmount ?? this.fixedAmount,
    );
  }
} 