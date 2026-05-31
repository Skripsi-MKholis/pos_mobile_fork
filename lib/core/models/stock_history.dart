import 'package:isar/isar.dart';

part 'stock_history.g.dart';

@collection
class StockHistoryLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String storeId;
  String? productId;
  late String productName;
  
  // 'sale', 'manual_addition', 'manual_reduction', 'manual_adjustment'
  late String changeType;
  
  late int quantityChange;
  late int oldStock;
  late int newStock;
  String? referenceId; // Transaction ID
  String? cashierId;
  
  late DateTime createdAt;

  late bool isSynced;
  String? syncError;

  StockHistoryLocal({
    this.id = Isar.autoIncrement,
    required this.supabaseId,
    required this.storeId,
    this.productId,
    required this.productName,
    required this.changeType,
    required this.quantityChange,
    required this.oldStock,
    required this.newStock,
    this.referenceId,
    this.cashierId,
    required this.createdAt,
    this.isSynced = false,
    this.syncError,
  });
}
