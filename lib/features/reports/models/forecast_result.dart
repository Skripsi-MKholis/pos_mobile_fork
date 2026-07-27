import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';

/// Metadata tentang bagaimana sebuah hasil forecast dihasilkan.
class ForecastMetadata {
  final ForecastMode mode;

  /// Nilai `model_used` mentah dari server (untuk audit/debug).
  final String? modelUsedRaw;
  final String? modelVersion;

  /// Alasan server memakai baseline alih-alih LSTM, mis.
  /// `insufficient_history` / `model_unavailable`.
  final String? fallbackReason;

  /// Jumlah hari data yang benar-benar dipakai sebagai input model.
  final int inputDays;

  /// Ambang minimum hari data agar LSTM diaktifkan.
  final int minDaysRequired;

  final DateTime generatedAt;

  const ForecastMetadata({
    required this.mode,
    this.modelUsedRaw,
    this.modelVersion,
    this.fallbackReason,
    this.inputDays = 0,
    this.minDaysRequired = 45,
    required this.generatedAt,
  });

  /// Sisa hari data yang dibutuhkan sebelum LSTM bisa dipakai.
  int get daysUntilLstmReady =>
      inputDays >= minDaysRequired ? 0 : minDaysRequired - inputDays;

  Map<String, dynamic> toJson() => {
    'model_used': modelUsedRaw ?? mode.apiValue,
    'model_version': modelVersion,
    'fallback_reason': fallbackReason,
    'input_days': inputDays,
    'min_days_required': minDaysRequired,
    'generated_at': generatedAt.toUtc().toIso8601String(),
  };

  factory ForecastMetadata.fromJson(Map<String, dynamic> json) {
    final raw = json['model_used']?.toString();
    return ForecastMetadata(
      mode: ForecastMode.fromApi(raw),
      modelUsedRaw: raw,
      modelVersion: json['model_version']?.toString(),
      fallbackReason: json['fallback_reason']?.toString(),
      inputDays: (json['input_days'] as num?)?.toInt() ?? 0,
      minDaysRequired: (json['min_days_required'] as num?)?.toInt() ?? 45,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }
}

/// Metrik akurasi yang dilaporkan server (hasil backtest internal model).
/// Berbeda dengan akurasi lapangan yang dihitung dari `ai_forecast_points`.
class ForecastMetrics {
  final double? mape;
  final double? rmse;
  final double? baselineMape;

  const ForecastMetrics({this.mape, this.rmse, this.baselineMape});

  bool get isEmpty => mape == null && rmse == null && baselineMape == null;

  /// Selisih poin persentase MAPE terhadap baseline (positif = model lebih baik).
  double? get improvementOverBaseline {
    if (mape == null || baselineMape == null) return null;
    return (baselineMape! - mape!) * 100;
  }

  Map<String, dynamic> toJson() => {
    if (mape != null) 'backtest_mape': mape,
    if (rmse != null) 'backtest_rmse': rmse,
    if (baselineMape != null) 'baseline_mape': baselineMape,
  };

  factory ForecastMetrics.fromJson(Map<String, dynamic> json) {
    return ForecastMetrics(
      mape: (json['backtest_mape'] as num?)?.toDouble(),
      rmse: (json['backtest_rmse'] as num?)?.toDouble(),
      baselineMape: (json['baseline_mape'] as num?)?.toDouble(),
    );
  }
}

/// Hasil lengkap satu kali pemanggilan model — sumber tunggal bagi seluruh
/// fitur yang memakai prediksi (Smart Analitik, Dashboard, Stok, POS, dst).
class ForecastResult {
  final ForecastMetadata metadata;
  final ForecastMetrics metrics;
  final List<ForecastPoint> daily;
  final List<HourlyTraffic> hourly;
  final List<ProductDemand> productDemand;
  final List<ForecastRecommendation> recommendations;

  const ForecastResult({
    required this.metadata,
    this.metrics = const ForecastMetrics(),
    this.daily = const [],
    this.hourly = const [],
    this.productDemand = const [],
    this.recommendations = const [],
  });

  ForecastMode get mode => metadata.mode;

  bool get isEmpty => daily.isEmpty;

  /// Prediksi omzet untuk tanggal tertentu.
  ///
  /// Mengembalikan `null` bila tanggal itu berada di luar horizon prediksi.
  /// Sengaja **tidak** jatuh ke "titik terakhir" seperti implementasi lama —
  /// pemanggil yang harus memutuskan cara menampilkan ketiadaan data.
  double? revenueForDate(DateTime date) => pointForDate(date)?.revenue;

  ForecastPoint? pointForDate(DateTime date) {
    final key = forecastDateKey(date);
    for (final p in daily) {
      if (p.dateKey == key) return p;
    }
    return null;
  }

  /// Total prediksi omzet untuk rentang tanggal (inklusif), hanya menjumlahkan
  /// tanggal yang benar-benar ada di horizon.
  double revenueBetween(DateTime from, DateTime to) {
    final fromKey = forecastDateKey(from);
    final toKey = forecastDateKey(to);
    double sum = 0;
    for (final p in daily) {
      if (p.dateKey.compareTo(fromKey) >= 0 && p.dateKey.compareTo(toKey) <= 0) {
        sum += p.revenue;
      }
    }
    return sum;
  }

  /// Jam tersibuk hasil prediksi, null bila tidak ada data per jam.
  HourlyTraffic? get peakHour {
    if (hourly.isEmpty) return null;
    return hourly.reduce((a, b) => b.txCount > a.txCount ? b : a);
  }

  ProductDemand? demandForProduct(String? productId, String productName) {
    for (final d in productDemand) {
      if (productId != null && d.productId != null && d.productId == productId) {
        return d;
      }
    }
    for (final d in productDemand) {
      if (d.productName.toLowerCase() == productName.toLowerCase()) return d;
    }
    return null;
  }

  ForecastRecommendation? recommendationOfKind(String kind) {
    for (final r in recommendations) {
      if (r.kind == kind) return r;
    }
    return null;
  }

  ForecastResult copyWith({
    ForecastMetadata? metadata,
    List<ProductDemand>? productDemand,
    List<ForecastRecommendation>? recommendations,
  }) {
    return ForecastResult(
      metadata: metadata ?? this.metadata,
      metrics: metrics,
      daily: daily,
      hourly: hourly,
      productDemand: productDemand ?? this.productDemand,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  Map<String, dynamic> toJson() => {
    'metadata': metadata.toJson(),
    'metrics': metrics.toJson(),
    'daily': daily.map((e) => e.toJson()).toList(),
    'hourly': hourly.map((e) => e.toJson()).toList(),
    'product_demand': productDemand.map((e) => e.toJson()).toList(),
    'recommendations': recommendations.map((e) => e.toJson()).toList(),
  };

  factory ForecastResult.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) build) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => build(Map<String, dynamic>.from(e)))
          .toList();
    }

    return ForecastResult(
      metadata: ForecastMetadata.fromJson(
        json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : <String, dynamic>{},
      ),
      metrics: ForecastMetrics.fromJson(
        json['metrics'] is Map
            ? Map<String, dynamic>.from(json['metrics'] as Map)
            : <String, dynamic>{},
      ),
      daily: parse('daily', ForecastPoint.fromJson),
      hourly: parse('hourly', HourlyTraffic.fromJson),
      productDemand: parse('product_demand', ProductDemand.fromJson),
      recommendations: parse('recommendations', ForecastRecommendation.fromJson),
    );
  }
}
