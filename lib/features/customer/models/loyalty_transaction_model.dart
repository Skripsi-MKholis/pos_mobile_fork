class LoyaltyTransactionModel {
  const LoyaltyTransactionModel({
    required this.id,
    required this.customerId,
    required this.storeId,
    this.orderId,
    required this.type,
    required this.points,
    this.description,
    this.createdAt,
  });

  final String id;
  final String customerId;
  final String storeId;
  final String? orderId;
  final String type;
  final int points;
  final String? description;
  final DateTime? createdAt;

  factory LoyaltyTransactionModel.fromMap(Map<String, dynamic> map) {
    return LoyaltyTransactionModel(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      storeId: map['store_id']?.toString() ?? '',
      orderId: map['order_id']?.toString(),
      type: map['type']?.toString() ?? 'earn',
      points: (map['points'] as num?)?.toInt() ?? 0,
      description: map['description']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }
}
