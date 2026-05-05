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
              final product = _mapSupabaseToProduct(data);

              await _isar.writeTxn(() async {
                await _isar.products.putBySupabaseId(product);
              });
              
              ref.invalidateSelf();
            }
          },
        )
        .subscribe();
  }

  Product _mapSupabaseToProduct(Map<String, dynamic> data) {
    return Product(
      supabaseId: data['id'].toString(),
      storeId: data['store_id'].toString(),
      name: data['name'],
      description: data['description'],
      price: (data['price'] as num).toDouble(),
      modalPrice: data['modal_price'] != null ? (data['modal_price'] as num).toDouble() : null,
      stockQuantity: data['stock_quantity'] ?? 0,
      barcode: data['barcode'],
      sku: data['sku'],
      imageUrl: data['image_url'],
      categoryId: data['category_id']?.toString(),
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
    );
  }

  Future<List<Product>> _fetchLocalProducts() async {
    return _isar.products.where().findAll();
  }

  Future<void> syncProducts() async {
    try {
      final response = await _supabase.from('products').select();
      
      final products = (response as List).map((data) => _mapSupabaseToProduct(data)).toList();

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

  Future<void> saveProduct(Product product, {File? imageFile}) async {
    final userData = await _supabase.from('users').select('store_id').eq('id', _supabase.auth.currentUser!.id).single();
    final storeId = userData['store_id'];

    String? imageUrl = product.imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    final productData = {
      'store_id': storeId,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'modal_price': product.modalPrice,
      'stock_quantity': product.stockQuantity,
      'barcode': product.barcode,
      'sku': product.sku,
      'category_id': product.categoryId,
      'image_url': imageUrl,
    };

    dynamic response;
    if (product.supabaseId.isEmpty) {
      // Create new
      response = await _supabase.from('products').insert(productData).select().single();
    } else {
      // Update existing
      response = await _supabase.from('products').update(productData).eq('id', product.supabaseId).select().single();
    }

    final savedProduct = _mapSupabaseToProduct(response);

    await _isar.writeTxn(() async {
      await _isar.products.putBySupabaseId(savedProduct);
    });

    ref.invalidateSelf();
  }
}
