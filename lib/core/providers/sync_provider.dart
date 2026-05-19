import 'dart:io';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'dart:convert';

part 'sync_provider.g.dart';

@riverpod
class SyncNotifier extends _$SyncNotifier {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;

  @override
  Future<void> build() async {
    // Watch connectivity
    final status = ref.watch(connectivityNotifierProvider);
    
    status.whenData((s) {
      final user = _supabase.auth.currentUser;
      if (s == ConnectivityStatus.online && user != null) {
        print('DEBUG: [SyncNotifier] Terdeteksi Online & User Login. Menjalankan sinkronisasi...');
        _syncUnsyncedData();
      } else if (user == null) {
        print('DEBUG: [SyncNotifier] User belum login, melewati sinkronisasi.');
      }
    });
  }

  Future<void> _syncUnsyncedData() async {
    print('DEBUG: Memulai sinkronisasi otomatis karena status Online...');
    await _syncCategories();
    await _syncProducts();
    await _syncTransactions();
    print('DEBUG: Sinkronisasi otomatis selesai.');
    
    // Invalidate providers agar UI terupdate
    ref.invalidate(productNotifierProvider);
    ref.invalidate(categoryNotifierProvider);
  }

  Future<void> syncUnsynced() async {
    final status = ref.read(connectivityNotifierProvider).value;
    final user = _supabase.auth.currentUser;
    if (status == ConnectivityStatus.online && user != null) {
      await _syncUnsyncedData();
    }
  }

  Future<void> _syncCategories() async {
    final unsynced = await _isar.collection<Category>().filter().isSyncedEqualTo(false).findAll();
    
    for (var cat in unsynced) {
      try {
        if (cat.isDeleted) {
          await _supabase.from('categories').delete().eq('id', cat.supabaseId);
          await _isar.writeTxn(() => _isar.collection<Category>().delete(cat.id));
        } else {
          final data = {
            'store_id': cat.storeId,
            'name': cat.name,
          };
          
          // Check if it already exists in Supabase
          final existing = await _supabase.from('categories').select().eq('id', cat.supabaseId).maybeSingle();
          
          if (existing == null) {
            await _supabase.from('categories').insert({'id': cat.supabaseId, ...data});
          } else {
            await _supabase.from('categories').update(data).eq('id', cat.supabaseId);
          }
          
          await _isar.writeTxn(() async {
            cat.isSynced = true;
            cat.syncError = null;
            await _isar.collection<Category>().put(cat);
          });
        }
      } catch (e) {
        await _isar.writeTxn(() async {
          cat.syncError = e.toString();
          await _isar.collection<Category>().put(cat);
        });
      }
    }
  }

  Future<void> _syncProducts() async {
    final unsynced = await _isar.products.filter().isSyncedEqualTo(false).findAll();
    
    for (var prod in unsynced) {
      try {
        if (prod.isDeleted) {
          // Delete image before deleting record
          final productNotifier = ref.read(productNotifierProvider.notifier);
          await productNotifier.deleteImageFromStorage(prod.imageUrl);
          await productNotifier.deleteLocalImage(prod.localImagePath);

          await _supabase.from('products').delete().eq('id', prod.supabaseId);
          await _isar.writeTxn(() => _isar.products.delete(prod.id));
        } else {
          String? imageUrl = prod.imageUrl;
          
          // Upload local image if exists
          if (prod.localImagePath != null) {
            final file = File(prod.localImagePath!);
            if (await file.exists()) {
              final newUrl = await ref.read(productNotifierProvider.notifier).uploadImage(file);
              if (newUrl != null) {
                imageUrl = newUrl;
              }
            }
          }

          final data = {
            'store_id': prod.storeId,
            'name': prod.name,
            'description': prod.description,
            'price': prod.price,
            'modal_price': prod.modalPrice,
            'stock_quantity': prod.stockQuantity,
            'barcode': prod.barcode,
            'sku': prod.sku,
            'category_id': prod.categoryId,
            'image_url': imageUrl,
          };

          final existing = await _supabase.from('products').select().eq('id', prod.supabaseId).maybeSingle();
          
          if (existing == null) {
            await _supabase.from('products').insert({'id': prod.supabaseId, ...data});
          } else {
            await _supabase.from('products').update(data).eq('id', prod.supabaseId);
          }

          await _isar.writeTxn(() async {
            prod.isSynced = true;
            prod.imageUrl = imageUrl;
            prod.localImagePath = null; // Clear local path after sync
            prod.syncError = null;
            await _isar.products.put(prod);
          });
        }
      } catch (e) {
        await _isar.writeTxn(() async {
          prod.syncError = e.toString();
          await _isar.products.put(prod);
        });
      }
    }
  }

  Future<void> _syncTransactions() async {
    final unsynced = await _isar.collection<TransactionLocal>().filter().isSyncedEqualTo(false).findAll();

    for (var tx in unsynced) {
      try {
        // Fetch local items associated with this transaction
        final localItems = await _isar.collection<TransactionItemLocal>()
            .filter()
            .transactionSupabaseIdEqualTo(tx.supabaseId)
            .findAll();

        final itemsToProcess = localItems.map((item) => {
          'product_id': item.productId,
          'product_name': item.productName,
          'unit_price': item.unitPrice,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
        }).toList();

        // Check if transaction already exists in Supabase
        final existing = await _supabase.from('transactions').select().eq('id', tx.supabaseId).maybeSingle();

        if (existing == null) {
          // Call create_transaction_v4 on Supabase via RPC
          final response = await _supabase.rpc(
            'create_transaction_v4',
            params: {
              'p_transaction_id': tx.supabaseId,
              'p_store_id': tx.storeId,
              'p_cashier_id': tx.cashierId,
              'p_total_amount': tx.totalAmount,
              'p_payment_method': tx.paymentMethod,
              'p_discount_total': tx.discountTotal,
              'p_voucher_info': tx.voucherInfo != null ? jsonDecode(tx.voucherInfo!) : {},
              'p_table_id': tx.tableId,
              'p_items': itemsToProcess,
              'p_status': tx.status,
              'p_cash_paid': tx.cashPaid,
              'p_change_amount': tx.changeAmount,
            },
          );

          if (response == null || (response is Map && response['success'] == false)) {
            throw response?['error'] ?? 'Gagal membuat transaksi di server.';
          }
        }

        // If success, update local state
        await _isar.writeTxn(() async {
          tx.isSynced = true;
          tx.syncError = null;
          await _isar.collection<TransactionLocal>().put(tx);
        });
      } catch (e) {
        print('DEBUG: Error syncing transaction ${tx.supabaseId}: $e');
        await _isar.writeTxn(() async {
          tx.syncError = e.toString();
          await _isar.collection<TransactionLocal>().put(tx);
        });
      }
    }
  }
}
