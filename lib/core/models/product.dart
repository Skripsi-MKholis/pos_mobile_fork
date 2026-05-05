import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String name;
  String? description;
  
  late double price;
  
  @Index()
  int stock = 0;

  String? sku;
  
  @Index()
  String? barcode;

  String? imageUrl;

  @Index()
  String? categorySupabaseId;

  DateTime? updatedAt;
}
