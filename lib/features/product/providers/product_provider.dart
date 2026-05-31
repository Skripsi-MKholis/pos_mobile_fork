import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/stock_history.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';

part 'product_provider.g.dart';

@riverpod
class ProductNotifier extends _$ProductNotifier {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Product>> build() async {
    final activeStoreAsync = ref.watch(activeStoreProvider);
    final activeStore = activeStoreAsync.value;
    final storeId = activeStore?['id'];

    if (storeId == null) return [];

    final channel = _listenToRealtimeChanges(storeId);
    ref.onDispose(() {
      _supabase.removeChannel(channel);
    });

    // Watch connectivity to trigger sync when online
    ref.listen(connectivityNotifierProvider, (previous, next) {
      if (next.value == ConnectivityStatus.online) {
        syncProducts();
      }
    });

    // Trigger initial background sync
    Future.microtask(() => syncProducts());
    return _fetchLocalProducts(storeId);
  }

  RealtimeChannel _listenToRealtimeChanges(String storeId) {
    return _supabase
        .channel('public:products:store:$storeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'store_id',
            value: storeId,
          ),
          callback: (payload) async {
            if (payload.newRecord.isNotEmpty) {
              final data = payload.newRecord;
              final product = _mapSupabaseToProduct(data);
              product.isSynced = true;

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
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
      isSynced: true,
    );
  }

  Future<List<Product>> _fetchLocalProducts(String storeId) async {
    return _isar.products
        .where()
        .filter()
        .storeIdEqualTo(storeId)
        .isDeletedEqualTo(false)
        .findAll();
  }
  Future<void> syncProducts() async {
    try {
      final activeStore = ref.read(activeStoreProvider).value;
      final storeId = activeStore?['id'];
      if (storeId == null) return;

      final isOnline =
          ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;
      if (!isOnline) return;

      final response = await _supabase.retryWithFreshSession(() => _supabase
          .from('products')
          .select()
          .eq('store_id', storeId));
      final products = (response as List)
          .map((data) => _mapSupabaseToProduct(data))
          .toList();
      final remoteIds = products.map((p) => p.supabaseId).toSet();

      await _isar.writeTxn(() async {
        // 1. Update/Add dari Remote
        for (var product in products) {
          await _isar.products.putBySupabaseId(product);
        }

        // 2. Hapus data lokal yang sudah tersinkron tapi tidak ada di Remote
        // (Artinya data tersebut dihapus dari server/dashboard oleh user lain)
        final localProducts = await _isar.products
            .filter()
            .isSyncedEqualTo(true)
            .isDeletedEqualTo(false)
            .findAll();

        for (var lp in localProducts) {
          if (!remoteIds.contains(lp.supabaseId)) {
            await _isar.products.delete(lp.id);
          }
        }
      });

      state = AsyncData(await _fetchLocalProducts(storeId));
    } catch (e) {
      print('DEBUG: Error syncing products: $e');
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'product_images/$fileName';

      await _supabase.storage.from('product-images').upload(path, imageFile);

      final imageUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'off_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localFile = await imageFile.copy('${dir.path}/$fileName');
      return localFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImageFromStorage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('product-images');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('product-images').remove([storagePath]);
      }
    } catch (e) {
      print('Error deleting remote image: $e');
    }
  }

  Future<void> deleteLocalImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting local image: $e');
    }
  }

  Future<void> saveProduct(Product product, {File? imageFile}) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];

    if (storeId == null) {
      throw Exception('Tidak ada toko aktif yang terpilih.');
    }

    // 1. Prepare Local Data
    final isNew = product.supabaseId.isEmpty;
    final localId = isNew ? _uuid.v4() : product.supabaseId;

    // Detect stock changes
    int oldStock = 0;
    if (!isNew) {
      final existingProduct = await _isar.products
          .filter()
          .supabaseIdEqualTo(localId)
          .findFirst();
      oldStock = existingProduct?.stockQuantity ?? 0;
    }
    final diff = product.stockQuantity - oldStock;

    StockHistoryLocal? history;
    if (isNew && product.stockQuantity > 0) {
      history = StockHistoryLocal(
        supabaseId: _uuid.v4(),
        storeId: storeId.toString(),
        productId: localId,
        productName: product.name,
        changeType: 'manual_addition',
        quantityChange: product.stockQuantity,
        oldStock: 0,
        newStock: product.stockQuantity,
        cashierId: _supabase.auth.currentUser?.id,
        createdAt: DateTime.now(),
        isSynced: false,
      );
    } else if (!isNew && diff != 0) {
      history = StockHistoryLocal(
        supabaseId: _uuid.v4(),
        storeId: storeId.toString(),
        productId: localId,
        productName: product.name,
        changeType: diff > 0 ? 'manual_addition' : 'manual_reduction',
        quantityChange: diff,
        oldStock: oldStock,
        newStock: product.stockQuantity,
        cashierId: _supabase.auth.currentUser?.id,
        createdAt: DateTime.now(),
        isSynced: false,
      );
    }

    String? imageUrl = product.imageUrl;
    String? localImagePath = product.localImagePath;

    final isOnline =
        ref.read(connectivityNotifierProvider).value ==
        ConnectivityStatus.online;

    if (imageFile != null) {
      if (isOnline) {
        imageUrl = await uploadImage(imageFile);
      } else {
        // Save locally if offline
        localImagePath = await _saveImageLocally(imageFile);
      }
    }

    final localProduct = product
      ..supabaseId = localId
      ..storeId = storeId
      ..imageUrl = imageUrl
      ..localImagePath = localImagePath
      ..isSynced = false;

    // 2. Save Locally First
    await _isar.writeTxn(() async {
      await _isar.products.putBySupabaseId(localProduct);
      if (history != null) {
        await _isar.collection<StockHistoryLocal>().put(history);
      }
    });
    ref.invalidateSelf();

    // 3. Try Sync if Online
    if (isOnline) {
      try {
        final productData = {
          'id': localId,
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

        if (isNew) {
          await _supabase.from('products').insert(productData);
        } else {
          await _supabase
              .from('products')
              .update(productData)
              .eq('id', localId);
        }

        // Mark as synced locally
        await _isar.writeTxn(() async {
          localProduct.isSynced = true;
          localProduct.syncError = null;
          await _isar.products.putBySupabaseId(localProduct);
        });
        ref.invalidateSelf();
      } catch (e) {
        await _isar.writeTxn(() async {
          localProduct.syncError = e.toString();
          await _isar.products.putBySupabaseId(localProduct);
        });
        ref.invalidateSelf();
      }
    }
  }

  Future<void> updateStock(String supabaseId, int newStock) async {
    try {
      final isOnline =
          ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;

      // Update locally
      final localProduct = await _isar.products
          .filter()
          .supabaseIdEqualTo(supabaseId)
          .findFirst();
          
      if (localProduct != null) {
        final oldStock = localProduct.stockQuantity;
        final diff = newStock - oldStock;
        
        if (diff != 0) {
          final activeStore = ref.read(activeStoreProvider).value;
          final storeId = activeStore?['id'];
          final cashierId = _supabase.auth.currentUser?.id;

          if (storeId != null) {
            final history = StockHistoryLocal(
              supabaseId: _uuid.v4(),
              storeId: storeId.toString(),
              productId: supabaseId,
              productName: localProduct.name,
              changeType: diff > 0 ? 'manual_addition' : 'manual_reduction',
              quantityChange: diff,
              oldStock: oldStock,
              newStock: newStock,
              cashierId: cashierId,
              createdAt: DateTime.now(),
              isSynced: false,
            );

            // 1. Save Locally First (marked as unsynced)
            await _isar.writeTxn(() async {
              localProduct.stockQuantity = newStock;
              localProduct.isSynced = false;
              await _isar.products.putBySupabaseId(localProduct);
              await _isar.collection<StockHistoryLocal>().put(history);
            });
            ref.invalidateSelf();

            // 2. Try Sync immediately if online
            if (isOnline) {
              try {
                await _supabase
                    .from('products')
                    .update({'stock_quantity': newStock})
                    .eq('id', supabaseId);

                // Mark product as synced upon success
                await _isar.writeTxn(() async {
                  localProduct.isSynced = true;
                  localProduct.syncError = null;
                  await _isar.products.putBySupabaseId(localProduct);
                });
                ref.invalidateSelf();
              } catch (e) {
                print('DEBUG: Immediate stock sync failed, queued for background retry: $e');
                await _isar.writeTxn(() async {
                  localProduct.syncError = e.toString();
                  await _isar.products.putBySupabaseId(localProduct);
                });
                ref.invalidateSelf();
              }
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String supabaseId) async {
    try {
      // 1. Soft delete locally
      final localProduct = await _isar.products
          .filter()
          .supabaseIdEqualTo(supabaseId)
          .findFirst();
      if (localProduct != null) {
        await _isar.writeTxn(() async {
          localProduct.isDeleted = true;
          localProduct.isSynced = false;
          await _isar.products.put(localProduct);
        });
        ref.invalidateSelf();
      }

      // 2. Try sync if online
      final isOnline =
          ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;
      if (isOnline) {
        // Delete image from storage first
        if (localProduct != null) {
          await deleteImageFromStorage(localProduct.imageUrl);
          await deleteLocalImage(localProduct.localImagePath);
        }

        await _supabase.from('products').delete().eq('id', supabaseId);
        
        // Hard delete locally if sync success
        await _isar.writeTxn(() async {
          await _isar.products
              .filter()
              .supabaseIdEqualTo(supabaseId)
              .deleteAll();
        });
        ref.invalidateSelf();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProductCategory(String productSupabaseId, String? categoryId) async {
    final products = state.value ?? [];
    final product = products.firstWhere((p) => p.supabaseId == productSupabaseId);
    final updatedProduct = Product(
      id: product.id,
      supabaseId: product.supabaseId,
      storeId: product.storeId,
      name: product.name,
      description: product.description,
      price: product.price,
      modalPrice: product.modalPrice,
      stockQuantity: product.stockQuantity,
      sku: product.sku,
      barcode: product.barcode,
      imageUrl: product.imageUrl,
      localImagePath: product.localImagePath,
      categoryId: categoryId,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await saveProduct(updatedProduct);
  }
}
