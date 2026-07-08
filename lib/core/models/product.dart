import 'package:isar_community/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String storeId; 

  late String name;
  String? description;
  
  late double price;
  double? modalPrice; 
  
  @Index()
  int stockQuantity = 0; 

  String? sku;
  
  @Index()
  String? barcode;

  String? imageUrl;

  @Index()
  String? categoryId; 

  String? localImagePath;

  DateTime? updatedAt;
  
  // SYNC METADATA
  @Index()
  bool isSynced = true;
  
  bool isDeleted = false;
  
  String? syncError;

  Product({
    this.id = Isar.autoIncrement,
    required this.supabaseId,
    required this.storeId,
    required this.name,
    this.description,
    required this.price,
    this.modalPrice,
    this.stockQuantity = 0,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.categoryId,
    this.localImagePath,
    this.updatedAt,
    this.isSynced = true,
    this.isDeleted = false,
    this.syncError,
  });
}
