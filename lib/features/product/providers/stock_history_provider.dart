import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/stock_history.dart';
import 'package:isar_community/isar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';

part 'stock_history_provider.g.dart';

@riverpod
class StockHistory extends _$StockHistory {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;

  @override
  Future<List<StockHistoryLocal>> build() async {
    final activeStoreAsync = ref.watch(activeStoreProvider);
    final activeStore = activeStoreAsync.value;
    final storeId = activeStore?['id'];

    if (storeId == null) return [];

    // Trigger initial background sync
    Future.microtask(() => syncStockHistory());

    return _fetchLocalStockHistory(storeId.toString());
  }

  Future<List<StockHistoryLocal>> _fetchLocalStockHistory(String storeId) async {
    return _isar.collection<StockHistoryLocal>()
        .filter()
        .storeIdEqualTo(storeId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> syncStockHistory() async {
    try {
      final activeStore = ref.read(activeStoreProvider).value;
      final storeId = activeStore?['id'];
      if (storeId == null) return;

      final isOnline =
          ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;
      if (!isOnline) return;

      await _supabase.ensureValidSession();
      final response = await _supabase
          .from('stock_history')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);
          
      final histories = (response as List)
          .map((data) => _mapSupabaseToStockHistory(data))
          .toList();

      await _isar.writeTxn(() async {
        for (var h in histories) {
          await _isar.collection<StockHistoryLocal>().putBySupabaseId(h);
        }
      });
      
      ref.invalidateSelf();
    } catch (e) {
      print('DEBUG: Error syncing stock history: $e');
    }
  }

  StockHistoryLocal _mapSupabaseToStockHistory(Map<String, dynamic> data) {
    return StockHistoryLocal(
      supabaseId: data['id'] as String,
      storeId: data['store_id'] as String,
      productId: data['product_id'] as String?,
      productName: data['product_name'] as String,
      changeType: data['change_type'] as String,
      quantityChange: data['quantity_change'] as int,
      oldStock: data['old_stock'] as int,
      newStock: data['new_stock'] as int,
      referenceId: data['reference_id'] as String?,
      cashierId: data['cashier_id'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String).toLocal(),
      isSynced: true,
    );
  }
}
