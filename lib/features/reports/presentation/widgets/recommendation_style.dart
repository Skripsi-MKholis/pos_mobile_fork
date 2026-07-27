import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';

/// Pemetaan jenis rekomendasi ke gaya visual.
///
/// Sengaja berada di lapisan presentasi — provider tidak lagi menyimpan
/// `Color`/`IconData` di dalam state (T-14), sehingga state tetap murni data
/// dan bisa diserialisasi ke snapshot maupun diuji tanpa Flutter.
class RecommendationStyle {
  final Color color;
  final IconData icon;

  const RecommendationStyle(this.color, this.icon);

  static RecommendationStyle of(String kind) {
    switch (kind) {
      case 'restock':
        return const RecommendationStyle(Warna.primary, TablerIcons.package);
      case 'happy_hour':
        return const RecommendationStyle(Warna.primary, TablerIcons.discount_2);
      case 'target_omzet':
      default:
        return const RecommendationStyle(Warna.primary, TablerIcons.target);
    }
  }
}

/// Gaya indikator status model (§10 dokumen rencana).
class ForecastModeStyle {
  final Color color;
  final IconData icon;
  final String label;

  const ForecastModeStyle(this.color, this.icon, this.label);

  /// [isFromCache] menandakan hasil dibaca dari penyimpanan lokal karena
  /// perangkat sedang offline — statusnya lebih rendah dari mode mana pun.
  static ForecastModeStyle of(ForecastMode mode, {bool isFromCache = false}) {
    if (isFromCache) {
      return ForecastModeStyle(
        Colors.grey.shade500,
        TablerIcons.database,
        'Data tersimpan (offline)',
      );
    }

    switch (mode) {
      case ForecastMode.lstmFinetuned:
      case ForecastMode.lstm:
        return ForecastModeStyle(Warna.success, TablerIcons.brain, mode.label);
      case ForecastMode.seasonalNaive:
      case ForecastMode.naive:
        return ForecastModeStyle(
          Colors.amber.shade700,
          TablerIcons.chart_dots,
          mode.label,
        );
      case ForecastMode.offlineLocal:
        return ForecastModeStyle(
          Colors.grey.shade500,
          TablerIcons.device_mobile,
          mode.label,
        );
    }
  }
}

/// Gaya badge tren permintaan produk.
class DemandTrendStyle {
  final Color color;
  final IconData icon;
  final String label;

  const DemandTrendStyle(this.color, this.icon, this.label);

  static DemandTrendStyle of(DemandTrend trend) {
    switch (trend) {
      case DemandTrend.up:
        return DemandTrendStyle(
          Warna.success,
          TablerIcons.trending_up,
          trend.label,
        );
      case DemandTrend.down:
        return DemandTrendStyle(
          Colors.orange.shade700,
          TablerIcons.trending_down,
          trend.label,
        );
      case DemandTrend.flat:
        return DemandTrendStyle(
          Colors.grey.shade500,
          TablerIcons.minus,
          trend.label,
        );
    }
  }
}

/// Tingkat urgensi stok berdasarkan sisa hari hasil prediksi.
enum StockUrgency {
  critical, // < 2 hari
  warning, // < 5 hari
  safe,
  unknown;

  static StockUrgency fromDaysLeft(double? daysLeft) {
    if (daysLeft == null) return StockUrgency.unknown;
    if (daysLeft < 2) return StockUrgency.critical;
    if (daysLeft < 5) return StockUrgency.warning;
    return StockUrgency.safe;
  }

  Color get color {
    switch (this) {
      case StockUrgency.critical:
        return const Color(0xFFDC2626);
      case StockUrgency.warning:
        return const Color(0xFFEA580C);
      case StockUrgency.safe:
        return Warna.success;
      case StockUrgency.unknown:
        return const Color(0xFF9CA3AF);
    }
  }

  String label(double? daysLeft) {
    switch (this) {
      case StockUrgency.critical:
        return 'Habis < 2 hari';
      case StockUrgency.warning:
        return 'Habis < 5 hari';
      case StockUrgency.safe:
        return daysLeft == null
            ? 'Aman'
            : 'Cukup ${daysLeft.floor()} hari';
      case StockUrgency.unknown:
        return 'Belum ada prediksi';
    }
  }
}
