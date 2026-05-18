import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/store.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';

class IsarService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [CategorySchema, ProductSchema, StoreSchema, NotificationLocalModelSchema],
      directory: dir.path,
    );
  }
}
