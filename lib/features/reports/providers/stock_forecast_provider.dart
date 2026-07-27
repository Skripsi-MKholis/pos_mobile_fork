import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/reports/domain/math_utils.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/recommendation_style.dart';
import 'package:pos_mobile/features/reports/providers/forecast_provider.dart';

/// Gabungan stok saat ini dengan prediksi permintaan satu produk (§8.3).
class StockForecast {
  final Product product;
  final ProductDemand demand;

  /// Sisa hari sebelum stok habis pada laju permintaan yang diprediksi.
  /// Null bila permintaan diprediksi nol (tidak bisa dihitung).
  final double? daysOfStockLeft;

  /// Saran jumlah pembelian agar stok cukup satu pekan + penyangga.
  final int recommendedPurchase;

  const StockForecast({
    required this.product,
    required this.demand,
    this.daysOfStockLeft,
    this.recommendedPurchase = 0,
  });

  StockUrgency get urgency => StockUrgency.fromDaysLeft(daysOfStockLeft);

  bool get needsRestock => recommendedPurchase > 0;
}

/// Penyangga keamanan: 20% di atas permintaan pekan depan, agar lonjakan
/// kecil tidak langsung membuat stok habis.
const double _safetyBufferRatio = 0.2;

/// Peta prediksi stok per `supabaseId` produk.
///
/// Membaca hasil prediksi yang sudah tersimpan lewat [forecastProvider] —
/// tidak memanggil server model, sehingga layar stok tetap ringan.
final stockForecastProvider = Provider.autoDispose<Map<String, StockForecast>>((
  ref,
) {
  final summary = ref.watch(forecastProvider).valueOrNull;
  final products = ref.watch(productNotifierProvider).valueOrNull;
  if (summary == null || products == null) return const {};

  final result = <String, StockForecast>{};

  for (final product in products) {
    if (product.isDeleted) continue;

    final demand = summary.forecast.demandForProduct(
      product.supabaseId,
      product.name,
    );
    if (demand == null) continue;

    final dailyQty = demand.predictedQty.toDouble();
    final weekQty = demand.predictedQtyWeek > 0
        ? demand.predictedQtyWeek
        : (demand.predictedQty * 7);

    final daysLeft = dailyQty > 0
        ? safeDiv(product.stockQuantity.toDouble(), dailyQty)
        : null;

    final target = (weekQty * (1 + _safetyBufferRatio)).ceil();
    final purchase = math.max(0, target - product.stockQuantity);

    result[product.supabaseId] = StockForecast(
      product: product,
      demand: demand,
      daysOfStockLeft: daysLeft,
      recommendedPurchase: purchase,
    );
  }

  return result;
});

/// `supabaseId` produk yang permintaannya diproyeksikan melambat (§8.4).
///
/// Kandidat promo cuci gudang. Kosong bila belum ada hasil analisis, sehingga
/// filternya otomatis tersembunyi di UI.
final slowingProductIdsProvider = Provider.autoDispose<Set<String>>((ref) {
  final map = ref.watch(stockForecastProvider);
  return {
    for (final entry in map.entries)
      if (entry.value.demand.trend == DemandTrend.down) entry.key,
  };
});

/// Daftar produk yang perlu dibeli, terurut dari yang paling mendesak.
final restockSuggestionsProvider = Provider.autoDispose<List<StockForecast>>((
  ref,
) {
  final map = ref.watch(stockForecastProvider);
  final list = map.values.where((s) => s.needsRestock).toList();

  list.sort((a, b) {
    // Produk yang stoknya paling cepat habis didahulukan; produk tanpa
    // perkiraan sisa hari ditempatkan paling belakang.
    final aDays = a.daysOfStockLeft ?? double.infinity;
    final bDays = b.daysOfStockLeft ?? double.infinity;
    final byDays = aDays.compareTo(bDays);
    if (byDays != 0) return byDays;
    return b.recommendedPurchase.compareTo(a.recommendedPurchase);
  });

  return list;
});
