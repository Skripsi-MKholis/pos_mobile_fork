import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

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

      // Fetch transactions for the store and time range
      final response = await _client
          .from('transactions')
          .select('id, total_amount, created_at, transaction_items(product_name, quantity, subtotal)')
          .eq('store_id', storeId)
          .filter('created_at', 'gte', dateStr)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      double totalRevenue = 0;
      int totalTransactions = data.length;
      Map<String, double> dailyMap = {};
      Map<String, int> productMap = {};

      // Initialize dailyMap for the range
      if (timeRange == AnalyticsTimeRange.today) {
        final d = DateFormat('HH:00').format(now); // Could show hourly for today
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
      state = AsyncValue.error(e, stack);
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsState>>((ref) {
  return AnalyticsNotifier(ref);
});
