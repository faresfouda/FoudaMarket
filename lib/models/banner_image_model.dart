class BannerImage {
  final String id;
  final String imageUrl;
  final String title;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  BannerImage({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory BannerImage.fromMap(Map<String, dynamic> map, String id) {
    return BannerImage(
      id: id,
      imageUrl: map['image_url'] ?? '',
      title: map['title'] ?? '',
      isActive: map['is_active'] ?? false,
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: map['updated_at']?.toDate(),
      createdBy: map['created_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_url': imageUrl,
      'title': title,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt ?? DateTime.now(),
      'created_by': createdBy,
    };
  }

  BannerImage copyWith({
    String? id,
    String? imageUrl,
    String? title,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return BannerImage(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
