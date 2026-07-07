import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart'
    show AnalyticsTimeRange;

class SalesBucket {
  final DateTime bucket;
  final double amount;
  final int txCount;
  const SalesBucket({
    required this.bucket,
    required this.amount,
    required this.txCount,
  });
}

class PaymentBreakdown {
  final String method;
  final double amount;
  final int txCount;
  const PaymentBreakdown({
    required this.method,
    required this.amount,
    required this.txCount,
  });
}

class HourStat {
  final int hour; // 0-23 (waktu lokal device)
  final double amount;
  final int txCount;
  const HourStat({
    required this.hour,
    required this.amount,
    required this.txCount,
  });
}

class WeekdayStat {
  final int dow; // ISO: 1 = Senin ... 7 = Minggu
  final double amount;
  final int txCount;
  const WeekdayStat({
    required this.dow,
    required this.amount,
    required this.txCount,
  });
}

class ProductStat {
  final String name;
  final int quantity;
  final double revenue;
  const ProductStat({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

class SalesPerformanceState {
  final AnalyticsTimeRange timeRange;
  final double totalRevenue;
  final int totalTransactions;
  final int totalItems;
  final double? prevRevenue; // null untuk lifetime (tak ada pembanding)
  final int? prevTransactions;
  final List<SalesBucket> series;
  final List<PaymentBreakdown> byPayment;
  final List<HourStat> byHour;
  final List<WeekdayStat> byWeekday;
  final List<ProductStat> topByQuantity;
  final List<ProductStat> topByRevenue;

  const SalesPerformanceState({
    required this.timeRange,
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalItems,
    this.prevRevenue,
    this.prevTransactions,
    required this.series,
    required this.byPayment,
    required this.byHour,
    required this.byWeekday,
    required this.topByQuantity,
    required this.topByRevenue,
  });

  double get avgTransaction =>
      totalTransactions == 0 ? 0 : totalRevenue / totalTransactions;

  /// Pertumbuhan omzet vs periode sebelumnya (persen); null jika tidak ada
  /// pembanding (lifetime, atau periode sebelumnya kosong).
  double? get revenueGrowth {
    final prev = prevRevenue;
    if (prev == null || prev == 0) return null;
    return (totalRevenue - prev) / prev * 100;
  }

  double? get transactionGrowth {
    final prev = prevTransactions;
    if (prev == null || prev == 0) return null;
    return (totalTransactions - prev) / prev * 100;
  }

  HourStat? get busiestHour {
    if (byHour.isEmpty) return null;
    return byHour.reduce((a, b) => b.txCount > a.txCount ? b : a);
  }

  WeekdayStat? get bestWeekday {
    if (byWeekday.isEmpty) return null;
    return byWeekday.reduce((a, b) => b.amount > a.amount ? b : a);
  }
}

class SalesPerformanceNotifier
    extends StateNotifier<AsyncValue<SalesPerformanceState>> {
  final Ref _ref;
  final SupabaseClient _client = Supabase.instance.client;

  SalesPerformanceNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(activeStoreProvider, (previous, next) {
      if (next.value != null) fetch(state.value?.timeRange ?? AnalyticsTimeRange.week);
    });
    fetch();
  }

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

  Future<void> fetch([AnalyticsTimeRange range = AnalyticsTimeRange.week]) async {
    final activeStore = _ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      DateTime? startDate;
      switch (range) {
        case AnalyticsTimeRange.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case AnalyticsTimeRange.week:
          final d = now.subtract(const Duration(days: 6));
          startDate = DateTime(d.year, d.month, d.day);
          break;
        case AnalyticsTimeRange.month:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case AnalyticsTimeRange.lifetime:
          startDate = null;
          break;
      }

      // Semua agregasi dihitung di server (RPC): hanya ringkasan jsonb kecil
      // yang dikirim, aman untuk toko dengan puluhan ribu transaksi.
      final response = await _client.rpc('get_sales_performance', params: {
        'p_store_id': storeId,
        'p_date_from': startDate?.toUtc().toIso8601String(),
        'p_date_to': null,
        'p_bucket': _bucketFor(range),
        'p_tz_offset_minutes': now.timeZoneOffset.inMinutes,
      });

      final r = Map<String, dynamic>.from(response as Map);

      List<T> parseList<T>(String key, T Function(Map<String, dynamic>) f) =>
          (r[key] as List? ?? [])
              .map((e) => f(Map<String, dynamic>.from(e)))
              .toList();

      state = AsyncValue.data(SalesPerformanceState(
        timeRange: range,
        totalRevenue: (r['total_revenue'] as num?)?.toDouble() ?? 0,
        totalTransactions: (r['total_transactions'] as num?)?.toInt() ?? 0,
        totalItems: (r['total_items'] as num?)?.toInt() ?? 0,
        prevRevenue: (r['prev_revenue'] as num?)?.toDouble(),
        prevTransactions: (r['prev_transactions'] as num?)?.toInt(),
        series: parseList('series', (e) => SalesBucket(
              // bucket sudah digeser ke waktu lokal oleh server; jangan
              // dikonversi zona waktu lagi.
              bucket: DateTime.parse(e['bucket'] as String).toUtc(),
              amount: (e['amount'] as num).toDouble(),
              txCount: (e['tx_count'] as num).toInt(),
            )),
        byPayment: parseList('by_payment', (e) => PaymentBreakdown(
              method: e['method'] as String,
              amount: (e['amount'] as num).toDouble(),
              txCount: (e['tx_count'] as num).toInt(),
            )),
        byHour: parseList('by_hour', (e) => HourStat(
              hour: (e['hour'] as num).toInt(),
              amount: (e['amount'] as num).toDouble(),
              txCount: (e['tx_count'] as num).toInt(),
            )),
        byWeekday: parseList('by_weekday', (e) => WeekdayStat(
              dow: (e['dow'] as num).toInt(),
              amount: (e['amount'] as num).toDouble(),
              txCount: (e['tx_count'] as num).toInt(),
            )),
        topByQuantity: parseList('top_by_quantity', (e) => ProductStat(
              name: e['name'] as String,
              quantity: (e['quantity'] as num).toInt(),
              revenue: (e['revenue'] as num).toDouble(),
            )),
        topByRevenue: parseList('top_by_revenue', (e) => ProductStat(
              name: e['name'] as String,
              quantity: (e['quantity'] as num).toInt(),
              revenue: (e['revenue'] as num).toDouble(),
            )),
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final salesPerformanceProvider = StateNotifierProvider<SalesPerformanceNotifier,
    AsyncValue<SalesPerformanceState>>((ref) {
  return SalesPerformanceNotifier(ref);
});
