import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String name;
  String? description;

  DateTime? updatedAt;
}
