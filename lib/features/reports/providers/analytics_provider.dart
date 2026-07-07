import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:isar/isar.dart';

enum AnalyticsTimeRange { today, week, month, lifetime }

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

  // Bucket agregasi per rentang: hari ini per jam, minggu/bulan per hari,
  // lifetime per bulan (agar chart tetap ringkas untuk data bertahun-tahun).
  String _bucketFor(AnalyticsTimeRange range) {
    switch (range) {
      case AnalyticsTimeRange.today:
        return 'hour';
      case AnalyticsTimeRange.week:
      case AnalyticsTimeRange.month:
        return 'day';
      case AnalyticsTimeRange.lifetime:
        return 'month';
    }
  }

  String _labelFor(AnalyticsTimeRange range, DateTime bucket) {
    switch (range) {
      case AnalyticsTimeRange.today:
        return DateFormat('HH:00').format(bucket);
      case AnalyticsTimeRange.week:
      case AnalyticsTimeRange.month:
        return DateFormat('dd/MM').format(bucket);
      case AnalyticsTimeRange.lifetime:
        return DateFormat('MMM yy').format(bucket);
    }
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
      DateTime? startDate;
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
        case AnalyticsTimeRange.lifetime:
          startDate = null; // tanpa batas bawah: seluruh riwayat
          daysToFetch = 0;
          break;
      }

      final isOnline = _ref.read(connectivityNotifierProvider).value == ConnectivityStatus.online;

      if (isOnline) {
        try {
          // Agregasi dilakukan di server via RPC `get_analytics`: hanya hasil
          // ringkasan (beberapa KB) yang dikirim, bukan seluruh baris
          // transaksi. Aman dipakai untuk lifetime dengan puluhan ribu data.
          final response = await _client.rpc('get_analytics', params: {
            'p_store_id': storeId,
            'p_date_from': startDate?.toUtc().toIso8601String(),
            'p_date_to': null,
            'p_bucket': _bucketFor(timeRange),
            'p_tz_offset_minutes': now.timeZoneOffset.inMinutes,
          });

          final result = Map<String, dynamic>.from(response as Map);

          // Bucket dari server sudah digeser ke waktu lokal; format apa
          // adanya (toUtc) tanpa konversi zona waktu kedua kali.
          final Map<String, double> dailyMap = {};
          if (timeRange != AnalyticsTimeRange.lifetime && startDate != null) {
            if (timeRange == AnalyticsTimeRange.today) {
              dailyMap[DateFormat('HH:00').format(now)] = 0;
            } else {
              for (int i = 0; i < daysToFetch; i++) {
                dailyMap[DateFormat('dd/MM')
                    .format(startDate.add(Duration(days: i)))] = 0;
              }
            }
          }
          for (final row in (result['series'] as List? ?? [])) {
            final bucket = DateTime.parse(row['bucket'] as String).toUtc();
            final label = _labelFor(timeRange, bucket);
            dailyMap[label] =
                (dailyMap[label] ?? 0) + (row['amount'] as num).toDouble();
          }

          final topProducts = (result['top_products'] as List? ?? [])
              .map((e) => {
                    'name': e['name'],
                    'quantity': (e['quantity'] as num).toInt(),
                  })
              .toList();

          state = AsyncValue.data(AnalyticsState(
            totalRevenue: (result['total_revenue'] as num?)?.toDouble() ?? 0,
            totalTransactions:
                (result['total_transactions'] as num?)?.toInt() ?? 0,
            dailySales: dailyMap.entries
                .map((e) => {'date': e.key, 'amount': e.value})
                .toList(),
            topProducts: topProducts,
            timeRange: timeRange,
          ));
          return;
        } catch (e) {
          // ignore: avoid_print
          print('DEBUG: Error fetching analytics from remote: $e');
          // Fallback ke agregasi cache lokal di bawah
        }
      }

      // Offline / RPC gagal: agregasi dari cache Isar (hanya data yang sudah
      // pernah di-cache di device).
      await _fetchFromLocal(storeId, timeRange, startDate, daysToFetch, now);
    } catch (e, stack) {
      // ignore: avoid_print
      print('DEBUG: General exception in fetchAnalytics: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _fetchFromLocal(
    String storeId,
    AnalyticsTimeRange timeRange,
    DateTime? startDate,
    int daysToFetch,
    DateTime now,
  ) async {
    final isar = IsarService.instance;
    var query =
        isar.collection<TransactionLocal>().filter().storeIdEqualTo(storeId);
    if (startDate != null) {
      query = query.createdAtGreaterThan(
        startDate.subtract(const Duration(milliseconds: 1)),
        include: false,
      );
    }
    // Urutkan agar label bucket pada chart tersusun kronologis
    final localTxs = await query.sortByCreatedAt().findAll();

    double totalRevenue = 0;
    final Map<String, double> dailyMap = {};
    final Map<String, int> productMap = {};

    if (timeRange == AnalyticsTimeRange.today) {
      dailyMap[DateFormat('HH:00').format(now)] = 0;
    } else if (timeRange != AnalyticsTimeRange.lifetime && startDate != null) {
      for (int i = 0; i < daysToFetch; i++) {
        dailyMap[DateFormat('dd/MM').format(startDate.add(Duration(days: i)))] =
            0;
      }
    }

    for (final tx in localTxs) {
      totalRevenue += tx.totalAmount;
      final label = _labelFor(timeRange, tx.createdAt);
      dailyMap[label] = (dailyMap[label] ?? 0) + tx.totalAmount;

      final items = await isar
          .collection<TransactionItemLocal>()
          .filter()
          .transactionSupabaseIdEqualTo(tx.supabaseId)
          .findAll();
      for (final item in items) {
        productMap[item.productName] =
            (productMap[item.productName] ?? 0) + item.quantity;
      }
    }

    final topProducts = productMap.entries
        .map((e) => {'name': e.key, 'quantity': e.value})
        .toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

    state = AsyncValue.data(AnalyticsState(
      totalRevenue: totalRevenue,
      totalTransactions: localTxs.length,
      dailySales: dailyMap.entries
          .map((e) => {'date': e.key, 'amount': e.value})
          .toList(),
      topProducts: topProducts.take(5).toList(),
      timeRange: timeRange,
    ));
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsState>>((ref) {
  return AnalyticsNotifier(ref);
});
