import 'dart:math' as math;

import 'package:pos_mobile/features/reports/domain/math_utils.dart';
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';

/// Estimasi cadangan yang dihitung **di perangkat** ketika server model tidak
/// bisa dihubungi (offline / endpoint mati).
///
/// Menggantikan `predictForDay()` lama yang memakai `math.Random` sebagai
/// "variansi deep learning" (T-02). Perhitungan di sini murni statistik
/// deterministik: rata-rata per hari dalam seminggu × tren linear. Hasilnya
/// selalu ditandai [ForecastMode.offlineLocal] sehingga UI tidak pernah
/// menyebutnya prediksi LSTM.
class LocalForecastEstimator {
  LocalForecastEstimator._();

  /// Minimal jumlah observasi satu hari-dalam-seminggu sebelum faktor
  /// musimannya dianggap bermakna.
  static const int _minSamplesPerWeekday = 2;

  static ForecastResult estimate({
    required DateTime now,
    required ForecastInput input,
    int horizonDays = 30,
    String? reason,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final stats = input.stats;
    final profile = input.profile;

    final weekdayFactors = _weekdayFactors(input, stats.avgDailyRevenue);
    final trafficPerRupiah = safeDiv(
      stats.avgDailyTraffic,
      stats.avgDailyRevenue,
    );

    final points = <ForecastPoint>[];
    for (int i = 1; i <= horizonDays; i++) {
      final date = today.add(Duration(days: i));

      // Hari tutup terjadwal diprediksi nol, bukan diisi rata-rata.
      if (!profile.isOpenOn(date)) {
        points.add(ForecastPoint(date: date, revenue: 0, txCount: 0));
        continue;
      }

      final trended = stats.avgDailyRevenue + (stats.slope * i);
      final base = math.max(0.0, trended);
      final revenue = base * (weekdayFactors[date.weekday] ?? 1.0);

      points.add(
        ForecastPoint(
          date: date,
          revenue: revenue,
          txCount: trafficPerRupiah == null
              ? null
              : math.max(0, (revenue * trafficPerRupiah).round()),
          confidence: null, // estimasi lokal tidak melaporkan confidence
        ),
      );
    }

    return ForecastResult(
      metadata: ForecastMetadata(
        mode: ForecastMode.offlineLocal,
        modelUsedRaw: ForecastMode.offlineLocal.apiValue,
        fallbackReason: reason ?? 'model_unavailable',
        inputDays: stats.activeDays,
        generatedAt: now,
      ),
      daily: points,
      hourly: _hourlyFromHistory(input),
      productDemand: productDemandFromHistory(input, horizonDays: 7),
    );
  }

  /// Faktor musiman per hari-dalam-seminggu (1 = Senin … 7 = Minggu).
  /// Hari dengan sampel terlalu sedikit memakai faktor netral 1.0.
  static Map<int, double> _weekdayFactors(
    ForecastInput input,
    double avgDailyRevenue,
  ) {
    if (avgDailyRevenue <= 0) return const {};

    final sums = <int, double>{};
    final counts = <int, int>{};
    for (final day in input.daily) {
      if (day.revenue <= 0) continue;
      sums[day.date.weekday] = (sums[day.date.weekday] ?? 0) + day.revenue;
      counts[day.date.weekday] = (counts[day.date.weekday] ?? 0) + 1;
    }

    final factors = <int, double>{};
    for (final weekday in sums.keys) {
      final count = counts[weekday] ?? 0;
      if (count < _minSamplesPerWeekday) continue;
      final avg = sums[weekday]! / count;
      final factor = safeDiv(avg, avgDailyRevenue);
      if (factor == null) continue;
      // Batasi agar satu hari ekstrem tidak mendistorsi proyeksi.
      factors[weekday] = factor.clamp(0.4, 2.0);
    }
    return factors;
  }

  /// Distribusi jam dari rata-rata historis (bukan prediksi model).
  static List<HourlyTraffic> _hourlyFromHistory(ForecastInput input) {
    if (input.hourly.isEmpty) return const [];

    final txByHour = <int, int>{};
    final daysByHour = <int, Set<String>>{};
    for (final h in input.hourly) {
      txByHour[h.hour] = (txByHour[h.hour] ?? 0) + h.txCount;
      daysByHour.putIfAbsent(h.hour, () => <String>{}).add(forecastDateKey(h.date));
    }

    final totalTx = txByHour.values.fold<int>(0, (a, b) => a + b);
    if (totalTx == 0) return const [];

    final hours = txByHour.keys.toList()..sort();
    return [
      for (final hour in hours)
        HourlyTraffic(
          hour: hour,
          txCount: (txByHour[hour]! / math.max(1, daysByHour[hour]!.length))
              .round(),
          share: txByHour[hour]! / totalTx,
        ),
    ];
  }

  /// Menyusun saran promo jam sepi dari distribusi transaksi per jam milik
  /// toko sendiri.
  ///
  /// Dipakai bila server model tidak mengirim rekomendasi `happy_hour` — mis.
  /// endpoint v1 yang belum mendukungnya. Ini murni statistik deskriptif dari
  /// riwayat toko, dan di UI tetap memakai label mode yang sedang berlaku,
  /// sehingga tidak pernah tampil sebagai keluaran LSTM.
  static ForecastRecommendation? quietHourRecommendation(
    ForecastInput input, {
    int discountPercent = 10,
  }) {
    if (input.hourly.isEmpty) return null;

    final profile = input.profile;
    final txByHour = <int, int>{};
    for (final h in input.hourly) {
      if (h.hour < profile.openHour || h.hour > profile.closeHour) continue;
      txByHour[h.hour] = (txByHour[h.hour] ?? 0) + h.txCount;
    }
    // Perlu cukup banyak jam berbeda agar "paling sepi" bermakna.
    if (txByHour.length < 4) return null;

    final total = txByHour.values.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return null;

    final quietest = txByHour.entries.reduce(
      (a, b) => b.value < a.value ? b : a,
    );
    final average = total / txByHour.length;
    // Hanya sarankan bila jam itu benar-benar timpang, bukan sekadar terendah.
    if (quietest.value >= average * 0.6) return null;

    final from = quietest.key;
    final to = math.min(profile.closeHour, from + 2);
    final share = (quietest.value / total * 100).toStringAsFixed(1);

    return ForecastRecommendation(
      kind: 'happy_hour',
      title: 'Promo Jam Sepi',
      desc: '',
      badge: 'PROMO',
      rationale:
          'Jam ${from.toString().padLeft(2, '0')}.00 hanya menyumbang $share% '
          'transaksi harian.',
      payload: {
        'discount_percent': discountPercent,
        'hour_from': from,
        'hour_to': to,
        'product_ids': const <String>[],
      },
    );
  }

  /// Proyeksi permintaan produk dari rata-rata penjualan harian aktual.
  /// Dipakai juga sebagai pelengkap saat server v1 tidak mengirim
  /// `product_demand`.
  static List<ProductDemand> productDemandFromHistory(
    ForecastInput input, {
    int horizonDays = 7,
  }) {
    if (input.products.isEmpty) return const [];

    final sorted = [...input.products]
      ..sort((a, b) => b.avgDailyQty.compareTo(a.avgDailyQty));

    return [
      for (final p in sorted)
        ProductDemand(
          productId: p.productId,
          productName: p.productName,
          category: p.category,
          predictedQty: p.avgDailyQty.ceil(),
          predictedQtyWeek: (p.avgDailyQty * horizonDays).ceil(),
        ),
    ];
  }
}
