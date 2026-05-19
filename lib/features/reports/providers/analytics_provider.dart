import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:isar/isar.dart';
import 'dart:convert';

enum AnalyticsTimeRange { today, week, month }

class AnalyticsState {
  final double totalRevenue;
  final int totalTransactions;
  final List<Map<String, dynamic>> dailySales;
  final List<Map<String, dynamic>> topProducts;
  final AnalyticsTimeRange timeRange;
  final bool isLoading;

  AnalyticsState({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.dailySales,
    required this.topProducts,
    required this.timeRange,
    this.isLoading = false,
  });

  factory AnalyticsState.initial() => AnalyticsState(
        totalRevenue: 0,
        totalTransactions: 0,
        dailySales: [],
        topProducts: [],
        timeRange: AnalyticsTimeRange.week,
      );

  AnalyticsState copyWith({
    double? totalRevenue,
    int? totalTransactions,
    List<Map<String, dynamic>>? dailySales,
    List<Map<String, dynamic>>? topProducts,
    AnalyticsTimeRange? timeRange,
    bool? isLoading,
  }) {
    return AnalyticsState(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      dailySales: dailySales ?? this.dailySales,
      topProducts: topProducts ?? this.topProducts,
      timeRange: timeRange ?? this.timeRange,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsState>> {
  final Ref _ref;
  final SupabaseClient _client = Supabase.instance.client;

  AnalyticsNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Re-fetch when active store changes
    _ref.listen(activeStoreProvider, (previous, next) {
      if (next.value != null) {
        fetchAnalytics();
      }
    });
    fetchAnalytics();
  }

  Future<void> fetchAnalytics([AnalyticsTimeRange timeRange = AnalyticsTimeRange.week]) async {
    final activeStore = _ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    
    if (storeId == null) {
      state = AsyncValue.data(AnalyticsState.initial());
      return;
    }

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      DateTime startDate;
      int daysToFetch = 7;

      switch (timeRange) {
        case AnalyticsTimeRange.today:
          startDate = DateTime(now.year, now.month, now.day);
          daysToFetch = 1;
          break;
        case AnalyticsTimeRange.week:
          startDate = now.subtract(const Duration(days: 6));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          daysToFetch = 7;
          break;
        case AnalyticsTimeRange.month:
          startDate = DateTime(now.year, now.month, 1);
          daysToFetch = now.day;
          break;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final isOnline = _ref.read(connectivityNotifierProvider).value == ConnectivityStatus.online;
      final isar = IsarService.instance;
      List<dynamic> data = [];

      if (isOnline) {
        try {
          // Fetch transactions with full fields to properly cache them in Isar
          final response = await _client
              .from('transactions')
              .select('*, transaction_items(*)')
              .eq('store_id', storeId)
              .filter('created_at', 'gte', dateStr)
              .order('created_at', ascending: true);

          final remoteData = List<Map<String, dynamic>>.from(response);
          data = remoteData;

          // Cache remote data in local Isar database
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

              // Clear and re-populate items
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
          print('DEBUG: Error fetching analytics from remote: $e');
          // Fallback to local Isar data
          data = [];
        }
      }

      // If offline or remote fetch yielded nothing/failed, query from local Isar
      if (data.isEmpty) {
        final localTxs = await isar.collection<TransactionLocal>()
            .filter()
            .storeIdEqualTo(storeId)
            .createdAtGreaterThan(startDate.subtract(const Duration(milliseconds: 1)), include: false)
            .findAll();

        final List<dynamic> localDataList = [];
        for (var tx in localTxs) {
          final items = await isar.collection<TransactionItemLocal>()
              .filter()
              .transactionSupabaseIdEqualTo(tx.supabaseId)
              .findAll();
          
          localDataList.add({
            'id': tx.supabaseId,
            'total_amount': tx.totalAmount,
            'created_at': tx.createdAt.toIso8601String(),
            'transaction_items': items.map((item) => {
              'product_name': item.productName,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
            }).toList(),
          });
        }
        data = localDataList;
      }

      double totalRevenue = 0;
      int totalTransactions = data.length;
      Map<String, double> dailyMap = {};
      Map<String, int> productMap = {};

      // Initialize dailyMap for the range
      if (timeRange == AnalyticsTimeRange.today) {
        final d = DateFormat('HH:00').format(now);
        dailyMap[d] = 0;
      } else {
        for (int i = 0; i < daysToFetch; i++) {
          final d = DateFormat('dd/MM').format(startDate.add(Duration(days: i)));
          dailyMap[d] = 0;
        }
      }

      for (var tx in data) {
        totalRevenue += (tx['total_amount'] as num).toDouble();
        
        final createdAt = DateTime.parse(tx['created_at']).toLocal();
        String dayStr;
        if (timeRange == AnalyticsTimeRange.today) {
          dayStr = DateFormat('HH:00').format(createdAt);
        } else {
          dayStr = DateFormat('dd/MM').format(createdAt);
        }

        dailyMap[dayStr] = (dailyMap[dayStr] ?? 0) + (tx['total_amount'] as num).toDouble();

        final items = tx['transaction_items'] as List<dynamic>;
        for (var item in items) {
          final name = item['product_name'] as String;
          final qty = (item['quantity'] as num).toInt();
          productMap[name] = (productMap[name] ?? 0) + qty;
        }
      }

      final dailySales = dailyMap.entries
          .map((e) => {'date': e.key, 'amount': e.value})
          .toList();

      final topProducts = productMap.entries
          .map((e) => {'name': e.key, 'quantity': e.value})
          .toList();
      topProducts.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      state = AsyncValue.data(AnalyticsState(
        totalRevenue: totalRevenue,
        totalTransactions: totalTransactions,
        dailySales: dailySales,
        topProducts: topProducts.take(5).toList(),
        timeRange: timeRange,
      ));
    } catch (e, stack) {
      // ignore: avoid_print
      print('DEBUG: General exception in fetchAnalytics: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsState>>((ref) {
  return AnalyticsNotifier(ref);
});

