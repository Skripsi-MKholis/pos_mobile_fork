import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:isar/isar.dart';

part 'product_provider.g.dart';

@riverpod
class ProductNotifier extends _$ProductNotifier {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;

  @override
  Future<List<Product>> build() async {
    _listenToRealtimeChanges();
    return _fetchLocalProducts();
  }

  void _listenToRealtimeChanges() {
    _supabase
        .channel('public:products')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) async {
            if (payload.newRecord.isNotEmpty) {
              final data = payload.newRecord;
              final product = Product()
                ..supabaseId = data['id'].toString()
                ..name = data['name']
                ..description = data['description']
                ..price = (data['price'] as num).toDouble()
                ..stock = data['stock'] as int
                ..barcode = data['barcode']
                ..sku = data['sku']
                ..imageUrl = data['image_url']
                ..categorySupabaseId = data['category_id']?.toString()
                ..updatedAt = DateTime.parse(data['updated_at']);

              await _isar.writeTxn(() async {
                await _isar.products.putBySupabaseId(product);
              });
              
              ref.invalidateSelf();
            }
          },
        )
        .subscribe();
  }

  Future<List<Product>> _fetchLocalProducts() async {
    return _isar.products.where().findAll();
  }

  Future<void> syncProducts() async {
    try {
      final response = await _supabase.from('products').select();
      
      final products = (response as List).map((data) {
        return Product()
          ..supabaseId = data['id'].toString()
          ..name = data['name']
          ..description = data['description']
          ..price = (data['price'] as num).toDouble()
          ..stock = data['stock'] as int
          ..barcode = data['barcode']
          ..sku = data['sku']
          ..imageUrl = data['image_url']
          ..categorySupabaseId = data['category_id']?.toString()
          ..updatedAt = DateTime.parse(data['updated_at']);
      }).toList();

      await _isar.writeTxn(() async {
        for (var product in products) {
          await _isar.products.putBySupabaseId(product);
        }
      });

      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'product_images/$fileName';
      
      await _supabase.storage.from('products').upload(path, imageFile);
      
      final imageUrl = _supabase.storage.from('products').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> addProduct(Product product, {File? imageFile}) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    final response = await _supabase.from('products').insert({
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'stock': product.stock,
      'barcode': product.barcode,
      'sku': product.sku,
      'category_id': product.categorySupabaseId,
      'image_url': imageUrl,
    }).select().single();

    product.supabaseId = response['id'].toString();
    product.updatedAt = DateTime.parse(response['updated_at']);
    product.imageUrl = imageUrl;

    await _isar.writeTxn(() async {
      await _isar.products.put(product);
    });

    ref.invalidateSelf();
  }
}
