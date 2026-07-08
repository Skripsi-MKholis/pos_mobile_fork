import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:isar_community/isar.dart';
import 'dart:convert';

part 'transaction_history_provider.g.dart';

class TransactionHistoryState {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final DateTime? filterDate;
  final String filterStatus;

  TransactionHistoryState({
    required this.transactions,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.filterDate,
    this.filterStatus = 'Semua',
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
      filterDate: filterDate,
      filterStatus: filterStatus,
    );
  }
}

class TransactionSummary {
  final double totalRevenue;
  final int transactionCount;

  const TransactionSummary({
    required this.totalRevenue,
    required this.transactionCount,
  });
}

/// Omzet & jumlah transaksi dihitung di server via RPC `get_transaction_summary`
/// (agregasi Postgres, hanya 1 baris yang dikirim) — bukan menjumlahkan list
/// transaksi di client. Fallback ke agregasi cache Isar saat offline.
@riverpod
Future<TransactionSummary> transactionSummary(
  TransactionSummaryRef ref, {
  DateTime? date,
}) async {
  final activeStore = ref.watch(activeStoreProvider).value;
  final storeId = activeStore?['id'];
  if (storeId == null) {
    return const TransactionSummary(totalRevenue: 0, transactionCount: 0);
  }

  DateTime? start;
  DateTime? end;
  if (date != null) {
    start = DateTime(date.year, date.month, date.day);
    end = start.add(const Duration(days: 1));
  }

  final isOnline =
      ref.watch(connectivityNotifierProvider).value == ConnectivityStatus.online;

  if (isOnline) {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_transaction_summary',
        params: {
          'p_store_id': storeId,
          'p_date_from': start?.toUtc().toIso8601String(),
          'p_date_to': end?.toUtc().toIso8601String(),
        },
      );
      final row = (response as List).first as Map<String, dynamic>;
      return TransactionSummary(
        totalRevenue: (row['total_revenue'] as num?)?.toDouble() ?? 0.0,
        transactionCount: (row['transaction_count'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Error fetching transaction summary: $e');
      // Fallback ke cache lokal di bawah
    }
  }

  final isar = IsarService.instance;
  var query = isar
      .collection<TransactionLocal>()
      .filter()
      .storeIdEqualTo(storeId);
  if (start != null && end != null) {
    query = query.createdAtBetween(start, end, includeUpper: false);
  }
  final count = await query.count();
  final sum = await query.totalAmountProperty().sum();
  return TransactionSummary(totalRevenue: sum, transactionCount: count);
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

    final data = await _fetchFromSupabaseAndCache(storeId, 0, null, 'Semua');
    return TransactionHistoryState(
      transactions: data,
      page: 0,
      hasMore: data.length == _pageSize,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFromSupabaseAndCache(
    String storeId,
    int page,
    DateTime? filterDate,
    String filterStatus,
  ) async {
    final isOnline = ref.read(connectivityNotifierProvider).value == ConnectivityStatus.online;
    final isar = IsarService.instance;

    DateTime? start;
    DateTime? end;
    if (filterDate != null) {
      start = DateTime(filterDate.year, filterDate.month, filterDate.day);
      end = start.add(const Duration(days: 1));
    }

    if (isOnline) {
      try {
        // Filter tanggal & status dilakukan di server sehingga paginasi hanya
        // mengunduh baris yang relevan, bukan seluruh riwayat.
        var query = _supabase
            .from('transactions')
            .select('*, transaction_items(*)')
            .eq('store_id', storeId);
        if (filterStatus != 'Semua') {
          query = query.eq('status', filterStatus);
        }
        if (start != null && end != null) {
          query = query
              .gte('created_at', start.toUtc().toIso8601String())
              .lt('created_at', end.toUtc().toIso8601String());
        }
        final response = await query
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

        return remoteData;
      } catch (e) {
        // ignore: avoid_print
        print('DEBUG: Error fetching transactions from Supabase: $e');
        // Fallback to local Isar cache gracefully without throwing an error
      }
    }

    return _fetchLocalTransactions(
        storeId, page, _pageSize, start, end, filterStatus);
  }

  Future<List<Map<String, dynamic>>> _fetchLocalTransactions(
    String storeId,
    int page,
    int pageSize,
    DateTime? start,
    DateTime? end,
    String filterStatus,
  ) async {
    final isar = IsarService.instance;
    var query = isar.collection<TransactionLocal>()
        .filter()
        .storeIdEqualTo(storeId);
    if (filterStatus != 'Semua') {
      query = query.statusEqualTo(filterStatus);
    }
    if (start != null && end != null) {
      query = query.createdAtBetween(start, end, includeUpper: false);
    }
    final txs = await query
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

  /// Ganti filter tanggal/status: reset ke halaman 0 dan query ulang di server.
  Future<void> applyFilters({DateTime? date, String status = 'Semua'}) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    state = const AsyncLoading();
    try {
      final data = await _fetchFromSupabaseAndCache(storeId, 0, date, status);
      state = AsyncValue.data(
        TransactionHistoryState(
          transactions: data,
          page: 0,
          hasMore: data.length == _pageSize,
          filterDate: date,
          filterStatus: status,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
      final newData = await _fetchFromSupabaseAndCache(
        storeId,
        nextPage,
        currentState.filterDate,
        currentState.filterStatus,
      );

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
    final currentState = state.value;
    await applyFilters(
      date: currentState?.filterDate,
      status: currentState?.filterStatus ?? 'Semua',
    );
  }
}
