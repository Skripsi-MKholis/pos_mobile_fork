class CustomerOrderModel {
  const CustomerOrderModel({
    required this.id,
    required this.storeId,
    this.customerId,
    this.transactionId,
    required this.status,
    this.tableNumber,
    this.customerName,
    this.notes,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String storeId;
  final String? customerId;
  final String? transactionId;
  final String status;
  final String? tableNumber;
  final String? customerName;
  final String? notes;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomerOrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return CustomerOrderModel(
      id: map['id']?.toString() ?? '',
      storeId: map['store_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString(),
      transactionId: map['transaction_id']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      tableNumber: map['table_number']?.toString(),
      customerName: map['customer_name']?.toString(),
      notes: map['notes']?.toString(),
      items: rawItems is List
          ? rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : const [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'store_id': storeId,
      'customer_id': customerId,
      'transaction_id': transactionId,
      'status': status,
      'table_number': tableNumber,
      'customer_name': customerName,
      'notes': notes,
      'items': items,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
    };
  }
}
