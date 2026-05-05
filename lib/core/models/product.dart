import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String storeId; // Ditambahkan sesuai Supabase

  late String name;
  String? description;
  
  late double price;
  double? modalPrice; // Ditambahkan (Harga Modal)
  
  @Index()
  int stockQuantity = 0; // Diganti dari stock -> stock_quantity

  String? sku;
  
  @Index()
  String? barcode;

  String? imageUrl;

  @Index()
  String? categoryId; // Diselaraskan dengan nama di Supabase

  DateTime? updatedAt;
}
