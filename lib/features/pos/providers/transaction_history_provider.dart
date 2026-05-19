import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:isar/isar.dart';
import 'dart:convert';

part 'transaction_history_provider.g.dart';

class TransactionHistoryState {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;

  TransactionHistoryState({
    required this.transactions,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
  });

  TransactionHistoryState copyWith({
    List<Map<String, dynamic>>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

@riverpod
class TransactionHistory extends _$TransactionHistory {
  final _supabase = Supabase.instance.client;
  final int _pageSize = 20;

  @override
  FutureOr<TransactionHistoryState> build() async {
    final activeStore = ref.watch(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return TransactionHistoryState(transactions: []);

    final data = await _fetchFromSupabaseAndCache(storeId, 0);
    return TransactionHistoryState(
      transactions: data,
      page: 0,
      hasMore: data.length == _pageSize,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFromSupabaseAndCache(
    String storeId,
    int page,
  ) async {
    final isOnline = ref.read(connectivityNotifierProvider).value == ConnectivityStatus.online;
    final isar = IsarService.instance;

    if (isOnline) {
      try {
        final response = await _supabase
            .from('transactions')
            .select('*, transaction_items(*)')
            .eq('store_id', storeId)
            .order('created_at', ascending: false)
            .range(page * _pageSize, (page + 1) * _pageSize - 1);

        final remoteData = List<Map<String, dynamic>>.from(response);

        // Cache remote data in Isar
        await isar.writeTxn(() async {
          for (var tx in remoteData) {
            final voucherInfoStr = tx['voucher_info'] != null ? jsonEncode(tx['voucher_info']) : null;
            final txLocal = TransactionLocal(
              supabaseId: tx['id'].toString(),
              storeId: tx['store_id'].toString(),
              cashierId: tx['cashier_id']?.toString() ?? '',
              totalAmount: (tx['total_amount'] as num).toDouble(),
              paymentMethod: tx['payment_method']?.toString() ?? 'Tunai',
              cashPaid: (tx['cash_paid'] as num?)?.toDouble() ?? (tx['total_amount'] as num).toDouble(),
              changeAmount: (tx['change_amount'] as num?)?.toDouble() ?? 0.0,
              status: tx['status']?.toString() ?? 'Berhasil',
              tableId: tx['table_id']?.toString(),
              discountTotal: (tx['discount_total'] as num?)?.toDouble() ?? 0.0,
              voucherInfo: voucherInfoStr,
              createdAt: DateTime.parse(tx['created_at']).toLocal(),
              isSynced: true,
            );

            await isar.collection<TransactionLocal>().putBySupabaseId(txLocal);

            // Delete existing items for this transaction to avoid duplicates
            await isar.collection<TransactionItemLocal>()
                .filter()
                .transactionSupabaseIdEqualTo(txLocal.supabaseId)
                .deleteAll();

            final items = tx['transaction_items'] as List? ?? [];
            for (var item in items) {
              final itemLocal = TransactionItemLocal(
                transactionSupabaseId: txLocal.supabaseId,
                productId: item['product_id']?.toString() ?? '',
                productName: item['product_name']?.toString() ?? 'Produk',
                unitPrice: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
                quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                subtotal: (item['subtotal'] as num?)?.toDouble() ?? 0.0,
              );
              await isar.collection<TransactionItemLocal>().put(itemLocal);
            }
          }
        });
      } catch (e) {
        // ignore: avoid_print
        print('DEBUG: Error fetching transactions from Supabase: $e');
        // Fallback to local Isar cache gracefully without throwing an error
      }
    }

    return _fetchLocalTransactions(storeId, page, _pageSize);
  }

  Future<List<Map<String, dynamic>>> _fetchLocalTransactions(
    String storeId,
    int page,
    int pageSize,
  ) async {
    final isar = IsarService.instance;
    final txs = await isar.collection<TransactionLocal>()
        .filter()
        .storeIdEqualTo(storeId)
        .sortByCreatedAtDesc()
        .offset(page * pageSize)
        .limit(pageSize)
        .findAll();

    final List<Map<String, dynamic>> list = [];
    for (var tx in txs) {
      final items = await isar.collection<TransactionItemLocal>()
          .filter()
          .transactionSupabaseIdEqualTo(tx.supabaseId)
          .findAll();
      
      final txMap = tx.toMap();
      txMap['transaction_items'] = items.map((item) => item.toMap()).toList();
      list.add(txMap);
    }
    return list;
  }

  Future<void> fetchMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.page + 1;
      final newData = await _fetchFromSupabaseAndCache(storeId, nextPage);

      state = AsyncValue.data(
        currentState.copyWith(
          transactions: [...currentState.transactions, ...newData],
          page: nextPage,
          hasMore: newData.length == _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    state = const AsyncLoading();
    try {
      final data = await _fetchFromSupabaseAndCache(storeId, 0);
      state = AsyncValue.data(
        TransactionHistoryState(
          transactions: data,
          page: 0,
          hasMore: data.length == _pageSize,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

