import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/models/table.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/core/models/product.dart';

part 'table_monitoring_provider.g.dart';

class TableOrder {
  final TableModel table;
  final Map<String, dynamic>? transaction;
  final List<Map<String, dynamic>> items;

  TableOrder({
    required this.table,
    this.transaction,
    this.items = const [],
  });
}

@riverpod
class TableMonitoring extends _$TableMonitoring {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<TableOrder>> build() async {
    final activeStore = await ref.watch(activeStoreProvider.future);
    final storeId = activeStore?['id'];
    if (storeId == null) return [];

    // 1. Fetch all tables
    final tablesResponse = await _supabase
        .from('tables')
        .select()
        .eq('store_id', storeId)
        .order('name');
    
    final tables = (tablesResponse as List).map((t) => TableModel.fromMap(t)).toList();

    // 2. Fetch all pending transactions for this store
    final transactionsResponse = await _supabase
        .from('transactions')
        .select('*, transaction_items(*)')
        .eq('store_id', storeId)
        .eq('status', 'Pending')
        .order('created_at', ascending: false);
    
    final transactions = List<Map<String, dynamic>>.from(transactionsResponse);

    // 3. Map transactions to tables
    return tables.map((table) {
      final tx = transactions.firstWhere(
        (t) => t['table_id'] == table.id,
        orElse: () => {},
      );
      
      return TableOrder(
        table: table,
        transaction: tx.isEmpty ? null : tx,
        items: tx.isEmpty ? [] : List<Map<String, dynamic>>.from(tx['transaction_items'] ?? []),
      );
    }).toList();
  }

  Future<void> saveOrderToTable({
    required TableModel table,
    required List<CartItem> items,
    required double totalAmount,
    double discountTotal = 0,
    Map<String, dynamic>? voucherInfo,
    String? activeTransactionId,
  }) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) throw 'Store ID not found';

    final itemsToProcess = items.map((item) => {
      'product_id': item.product.supabaseId,
      'product_name': item.product.name,
      'unit_price': item.product.price,
      'quantity': item.quantity,
      'subtotal': item.subtotal,
    }).toList();

    try {
      if (activeTransactionId != null) {
        // Update existing transaction
        final response = await _supabase.rpc('sync_pending_transaction', params: {
          'p_transaction_id': activeTransactionId,
          'p_items': itemsToProcess,
          'p_total_amount': totalAmount,
          'p_discount_total': discountTotal,
          'p_voucher_info': voucherInfo ?? {},
        });

        if (response == null || (response is Map && response['success'] == false)) {
          throw response?['error'] ?? 'Gagal memperbarui pesanan';
        }
      } else {
        // Use RPC to create a new pending transaction
        final response = await _supabase.rpc('create_transaction_v3', params: {
          'p_store_id': storeId,
          'p_cashier_id': _supabase.auth.currentUser!.id,
          'p_total_amount': totalAmount,
          'p_payment_method': 'Tunai',
          'p_discount_total': discountTotal,
          'p_voucher_info': voucherInfo ?? {},
          'p_table_id': table.id,
          'p_items': itemsToProcess,
          'p_status': 'Pending',
          'p_cash_paid': 0,
          'p_change_amount': 0,
        });

        if (response == null || (response is Map && response['success'] == false)) {
          throw response?['error'] ?? 'Gagal menyimpan pesanan';
        }
      }

      // Update table status to occupied
      await _supabase.from('tables').update({'status': 'occupied'}).eq('id', table.id);

      ref.invalidateSelf();
    } catch (e) {
      print('Error saving order: $e');
      rethrow;
    }
  }

  Future<void> handleTableTransactionComplete({
    required String tableId,
    required List<CartItem> paidItems,
  }) async {
    try {
      // 1. Get current pending order for this table
      final currentState = await future;
      final orderIndex = currentState.indexWhere((o) => o.table.id == tableId);
      if (orderIndex == -1) return;
      
      final tableOrder = currentState[orderIndex];
      final pendingTx = tableOrder.transaction;
      
      if (pendingTx == null || pendingTx['status'] != 'Pending') {
        ref.invalidateSelf();
        return; 
      }

      final pendingTxId = pendingTx['id'];
      final pendingItems = List<Map<String, dynamic>>.from(tableOrder.items);
      
      // 2. Determine if this was a full payment or split
      bool isFullPayment = true;
      final List<Map<String, dynamic>> remainingItems = [];

      for (var pItem in pendingItems) {
        final paidItem = paidItems.firstWhere(
          (i) => i.product.supabaseId == pItem['product_id'],
          orElse: () => CartItem(product: Product(supabaseId: '', storeId: '', name: '', price: 0, stockQuantity: 0), quantity: 0),
        );

        if (paidItem.quantity < pItem['quantity']) {
          isFullPayment = false;
          remainingItems.add({
            ...pItem,
            'quantity': pItem['quantity'] - paidItem.quantity,
            'subtotal': (pItem['quantity'] - paidItem.quantity) * (pItem['unit_price'] as num).toDouble(),
          });
        }
      }

      if (isFullPayment && paidItems.length < pendingItems.length) {
          // Check if there are items in pending that are not in paidItems
          for (var pItem in pendingItems) {
              final isPaid = paidItems.any((i) => i.product.supabaseId == pItem['product_id']);
              if (!isPaid) {
                  isFullPayment = false;
                  remainingItems.add(pItem);
              }
          }
      }

      if (isFullPayment) {
        // Full payment: Delete pending transaction (items are deleted by cascade or manually)
        // Actually, better to just set status to something else or delete
        await _supabase.from('transactions').delete().eq('id', pendingTxId);
        await _supabase.from('tables').update({'status': 'available'}).eq('id', tableId);
      } else {
        // Split bill: Update pending transaction
        // Update items in transaction_items
        for (var item in paidItems) {
           final pItem = pendingItems.firstWhere((i) => i['product_id'] == item.product.supabaseId, orElse: () => {});
           if (pItem.isNotEmpty) {
             final newQty = pItem['quantity'] - item.quantity;
             if (newQty > 0) {
               await _supabase.from('transaction_items')
                .update({
                  'quantity': newQty,
                  'subtotal': newQty * (pItem['unit_price'] as num).toDouble(),
                })
                .eq('id', pItem['id']);
             } else {
               await _supabase.from('transaction_items').delete().eq('id', pItem['id']);
             }
           }
        }
        
        // Update total amount of pending transaction
        final newTotal = remainingItems.fold(0.0, (sum, item) => sum + (item['subtotal'] as num).toDouble());
        await _supabase.from('transactions').update({'total_amount': newTotal}).eq('id', pendingTxId);
      }

      ref.invalidateSelf();
    } catch (e) {
      print('Error completing table transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTableStatus(String tableId, String status) async {
    try {
      await _supabase.from('tables').update({'status': status}).eq('id', tableId);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }
}
