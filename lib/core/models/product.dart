import 'package:isar/isar.dart';

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

  DateTime? updatedAt;

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
    this.updatedAt,
  });
}
