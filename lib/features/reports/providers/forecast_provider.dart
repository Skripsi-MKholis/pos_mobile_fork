import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/reports/data/smart_analytics_repository.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';
import 'package:pos_mobile/features/reports/models/forecast_snapshot.dart';
import 'package:pos_mobile/features/reports/providers/smart_analytics_provider.dart';

/// Ringkasan prediksi terakhir yang siap dipakai fitur di luar Smart Analitik.
class ForecastSummary {
  final ForecastResult forecast;
  final DateTime generatedAt;
  final ForecastMode mode;

  const ForecastSummary({
    required this.forecast,
    required this.generatedAt,
    required this.mode,
  });

  /// Umur hasil prediksi. Dipakai UI untuk menandai data yang sudah basi.
  Duration get age => DateTime.now().difference(generatedAt);

  bool get isStale => age.inHours >= 36;

  ForecastPoint? get today => forecast.pointForDate(DateTime.now());

  ForecastPoint? get tomorrow =>
      forecast.pointForDate(DateTime.now().add(const Duration(days: 1)));

  double get revenueNext7Days {
    final now = DateTime.now();
    return forecast.revenueBetween(
      now.add(const Duration(days: 1)),
      now.add(const Duration(days: 7)),
    );
  }

  HourlyTraffic? get peakHour => forecast.peakHour;

  List<ProductDemand> get productDemand => forecast.productDemand;
}

/// Hasil prediksi terakhir toko aktif — **sumber tunggal** bagi Dashboard,
/// Manajemen Stok, POS, dan notifikasi.
///
/// Provider ini sengaja hanya membaca: snapshot dari Supabase bila tersedia,
/// atau cache perangkat bila offline. Ia **tidak pernah** memanggil server
/// model, sehingga aman dipakai di layar yang harus terasa instan seperti
/// Dashboard dan POS. Pemanggilan model hanya terjadi lewat tombol
/// "Segarkan Analisis" di layar Smart Analitik.
final forecastProvider = FutureProvider.autoDispose<ForecastSummary?>((
  ref,
) async {
  final store = ref.watch(activeStoreProvider).value;
  final storeId = store?['id']?.toString();
  if (storeId == null) return null;

  // Ikut menyegarkan saat analisis baru dijalankan di layar Smart Analitik.
  final live = ref.watch(smartAnalyticsProvider);
  if (live.forecast != null && !live.isHistoryView) {
    return ForecastSummary(
      forecast: live.forecast!,
      generatedAt: live.snapshotCreatedAt ?? DateTime.now(),
      mode: live.mode,
    );
  }

  final repository = SmartAnalyticsRepository();
  var row = await repository.readCachedSnapshot(storeId);
  row ??= await repository.fetchLatestSnapshot(storeId);
  if (row == null) return null;

  final payload = ForecastSnapshotPayload.fromJson(
    row['forecast_payload'] is Map
        ? Map<String, dynamic>.from(row['forecast_payload'] as Map)
        : null,
  );
  if (payload == null) return null;

  return ForecastSummary(
    forecast: payload.forecast,
    generatedAt: row['created_at'] != null
        ? DateTime.parse(row['created_at'] as String).toLocal()
        : DateTime.now(),
    mode: ForecastMode.fromApi(row['model_used']?.toString()),
  );
});
