import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AnalyticsState {
  final double totalRevenue;
  final int totalTransactions;
  final List<Map<String, dynamic>> dailySales;
  final List<Map<String, dynamic>> topProducts;
  final bool isLoading;

  AnalyticsState({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.dailySales,
    required this.topProducts,
    this.isLoading = false,
  });

  factory AnalyticsState.initial() => AnalyticsState(
        totalRevenue: 0,
        totalTransactions: 0,
        dailySales: [],
        topProducts: [],
      );

  AnalyticsState copyWith({
    double? totalRevenue,
    int? totalTransactions,
    List<Map<String, dynamic>>? dailySales,
    List<Map<String, dynamic>>? topProducts,
    bool? isLoading,
  }) {
    return AnalyticsState(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      dailySales: dailySales ?? this.dailySales,
      topProducts: topProducts ?? this.topProducts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsState>> {
  final SupabaseClient _client = Supabase.instance.client;

  AnalyticsNotifier() : super(const AsyncValue.loading()) {
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final dateStr = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

      // Fetch transactions for the last 7 days
      final response = await _client
          .from('transactions')
          .select('id, total_amount, created_at, transaction_items(product_name, quantity, subtotal)')
          .filter('created_at', 'gte', dateStr)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      double totalRevenue = 0;
      int totalTransactions = data.length;
      Map<String, double> dailyMap = {};
      Map<String, int> productMap = {};

      // Initialize dailyMap for the last 7 days
      for (int i = 0; i < 7; i++) {
        final d = DateFormat('dd/MM').format(now.subtract(Duration(days: 6 - i)));
        dailyMap[d] = 0;
      }

      for (var tx in data) {
        totalRevenue += (tx['total_amount'] as num).toDouble();
        
        final createdAt = DateTime.parse(tx['created_at']);
        final dayStr = DateFormat('dd/MM').format(createdAt);
        if (dailyMap.containsKey(dayStr)) {
          dailyMap[dayStr] = dailyMap[dayStr]! + (tx['total_amount'] as num).toDouble();
        }

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
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsState>>((ref) {
  return AnalyticsNotifier();
});
