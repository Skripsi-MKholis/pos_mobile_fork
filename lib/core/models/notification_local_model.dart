import 'package:isar/isar.dart';

part 'notification_local_model.g.dart';

@collection
class NotificationLocalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String supabaseId;

  String? storeId;
  String? userId;
  late String type;
  late String title;
  late String message;
  
  @Index()
  bool isRead = false;
  
  DateTime? createdAt;
  String? imageUrl;
  String? metadataJson; // Mengonversi JSONB menjadi string untuk kemudahan penyimpanan offline
}
