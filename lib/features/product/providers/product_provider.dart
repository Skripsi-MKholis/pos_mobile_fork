import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:isar/isar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

part 'product_provider.g.dart';

@riverpod
class ProductNotifier extends _$ProductNotifier {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;

  @override
  Future<List<Product>> build() async {
    final channel = _listenToRealtimeChanges();
    ref.onDispose(() {
      _supabase.removeChannel(channel);
    });
    
    // Trigger background sync
    Future.microtask(() => syncProducts());
    return _fetchLocalProducts();
  }

  RealtimeChannel _listenToRealtimeChanges() {
    return _supabase
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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    double? parseDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return Product(
      supabaseId: data['id'].toString(),
      storeId: data['store_id'].toString(),
      name: data['name'] ?? 'Tanpa Nama',
      description: data['description'],
      price: parseDouble(data['price']),
      modalPrice: parseDoubleNullable(data['modal_price']),
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
      print('DEBUG: Memulai sinkronisasi produk dari Supabase...');
      final response = await _supabase.from('products').select();
      
      print('DEBUG: Berhasil mengambil ${response.length} produk dari Supabase.');
      
      final products = (response as List).map((data) => _mapSupabaseToProduct(data)).toList();

      await _isar.writeTxn(() async {
        for (var product in products) {
          await _isar.products.putBySupabaseId(product);
        }
      });

      final localCount = await _isar.products.count();
      print('DEBUG: Sinkronisasi produk ke Isar selesai. Total produk di Isar: $localCount');
      
      // Update state directly to avoid infinite loop from invalidateSelf()
      state = AsyncData(await _fetchLocalProducts());
    } catch (e) {
      print('DEBUG: Error saat sinkronisasi produk: $e');
      rethrow;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'product_images/$fileName';
      
      await _supabase.storage.from('product-images').upload(path, imageFile);
      
      final imageUrl = _supabase.storage.from('product-images').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      print('DEBUG: Error upload image: $e');
      return null;
    }
  }

  Future<void> saveProduct(Product product, {File? imageFile}) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];

    if (storeId == null) {
      throw Exception('Tidak ada toko aktif yang terpilih.');
    }

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

  Future<void> deleteProduct(String supabaseId) async {
    try {
      // 1. Delete from Supabase
      await _supabase.from('products').delete().eq('id', supabaseId);

      // 2. Delete from Isar
      await _isar.writeTxn(() async {
        await _isar.products.filter().supabaseIdEqualTo(supabaseId).deleteAll();
      });

      // 3. Update state
      ref.invalidateSelf();
    } catch (e) {
      print('DEBUG: Error saat menghapus produk: $e');
      rethrow;
    }
  }
}
