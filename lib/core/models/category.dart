import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String storeId; // Ditambahkan sesuai Supabase

  late String name;

  DateTime? updatedAt;
  
  @Index()
  bool isSynced = true;
  
  bool isDeleted = false;
  
  String? syncError;
}
