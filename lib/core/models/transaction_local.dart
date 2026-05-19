import 'package:isar/isar.dart';
import 'dart:convert';

part 'transaction_local.g.dart';

@collection
class TransactionLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String storeId;
  late String cashierId;
  late double totalAmount;
  late String paymentMethod;
  late double cashPaid;
  late double changeAmount;
  late String status;
  String? tableId;
  late double discountTotal;
  String? voucherInfo; // JSON string

  late DateTime createdAt;

  late bool isSynced;
  String? syncError;

  TransactionLocal({
    this.id = Isar.autoIncrement,
    required this.supabaseId,
    required this.storeId,
    required this.cashierId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.cashPaid,
    required this.changeAmount,
    required this.status,
    this.tableId,
    required this.discountTotal,
    this.voucherInfo,
    required this.createdAt,
    this.isSynced = false,
    this.syncError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': supabaseId,
      'store_id': storeId,
      'cashier_id': cashierId,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'cash_paid': cashPaid,
      'change_amount': changeAmount,
      'status': status,
      'table_id': tableId,
      'discount_total': discountTotal,
      'voucher_info': voucherInfo != null ? jsonDecode(voucherInfo!) : {},
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@collection
class TransactionItemLocal {
  Id id = Isar.autoIncrement;

  @Index()
  late String transactionSupabaseId;

  late String productId;
  late String productName;
  late double unitPrice;
  late int quantity;
  late double subtotal;

  TransactionItemLocal({
    this.id = Isar.autoIncrement,
    required this.transactionSupabaseId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
