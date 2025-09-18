import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewStatus { pending, approved, rejected }

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String productId;
  final String productName;
  final String? productImage;
  final String reviewText;
  final double rating; // من 1 إلى 5
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes; // ملاحظات المدير عند الرفض أو التعديل
  final String? orderId; // معرف الطلب المرتبط بالمراجعة

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.reviewText,
    required this.rating,
    this.status = ReviewStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
    this.orderId,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // معالجة Timestamp من Firestore
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        return timestamp;
      } else {
        return DateTime.now();
      }
    }

    // معالجة حالة المراجعة
    ReviewStatus parseStatus(String status) {
      switch (status) {
        case 'approved':
          return ReviewStatus.approved;
        case 'rejected':
          return ReviewStatus.rejected;
        case 'pending':
        default:
          return ReviewStatus.pending;
      }
    }

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'],
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      reviewText: json['review_text'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(json['status'] ?? 'pending'),
      createdAt: parseTimestamp(json['created_at']),
      updatedAt: parseTimestamp(json['updated_at']),
      adminNotes: json['admin_notes'],
      orderId: json['order_id'],
    );
  }

  Map<String, dynamic> toJson() {
    String statusToString(ReviewStatus status) {
      switch (status) {
        case ReviewStatus.approved:
          return 'approved';
        case ReviewStatus.rejected:
          return 'rejected';
        case ReviewStatus.pending:
        default:
          return 'pending';
      }
    }

    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'review_text': reviewText,
      'rating': rating,
      'status': statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'admin_notes': adminNotes,
      'order_id': orderId,
    };
  }

  // Getters مفيدة
  bool get isPending => status == ReviewStatus.pending;
  bool get isApproved => status == ReviewStatus.approved;
  bool get isRejected => status == ReviewStatus.rejected;
  
  // حساب متوسط التقييم (مفيد للمنتج)
  double get normalizedRating => rating.clamp(1.0, 5.0);

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? productId,
    String? productName,
    String? productImage,
    String? reviewText,
    double? rating,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
    String? orderId,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, userName: $userName, productName: $productName, rating: $rating, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 