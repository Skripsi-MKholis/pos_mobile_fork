class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.storeId,
    this.userId,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.loyaltyPoints = 0,
    this.loyaltyTier = 'bronze',
    this.totalSpent = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String storeId;
  final String? userId;
  final String? displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final int loyaltyPoints;
  final String loyaltyTier;
  final double totalSpent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id']?.toString() ?? '',
      storeId: map['store_id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      displayName: map['display_name']?.toString(),
      phoneNumber: map['phone_number']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      loyaltyPoints: (map['loyalty_points'] as num?)?.toInt() ?? 0,
      loyaltyTier: map['loyalty_tier']?.toString() ?? 'bronze',
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'user_id': userId,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'loyalty_points': loyaltyPoints,
      'loyalty_tier': loyaltyTier,
      'total_spent': totalSpent,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
