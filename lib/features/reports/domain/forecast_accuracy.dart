import 'dart:math' as math;

/// Satu pasang prediksi ↔ realisasi untuk satu tanggal.
/// Bersumber dari tabel `ai_forecast_points` setelah kolom `actual_*` diisi.
class ForecastEvaluationPoint {
  final DateTime targetDate;
  final int horizonDays;
  final String modelUsed;
  final double predictedRevenue;
  final double? actualRevenue;
  final int? predictedTx;
  final int? actualTx;

  const ForecastEvaluationPoint({
    required this.targetDate,
    required this.horizonDays,
    required this.modelUsed,
    required this.predictedRevenue,
    this.actualRevenue,
    this.predictedTx,
    this.actualTx,
  });

  bool get isEvaluated => actualRevenue != null;

  factory ForecastEvaluationPoint.fromMap(Map<String, dynamic> map) {
    return ForecastEvaluationPoint(
      targetDate: DateTime.parse(map['target_date'] as String),
      horizonDays: (map['horizon_days'] as num?)?.toInt() ?? 0,
      modelUsed: map['model_used']?.toString() ?? 'unknown',
      predictedRevenue: (map['predicted_revenue'] as num?)?.toDouble() ?? 0,
      actualRevenue: (map['actual_revenue'] as num?)?.toDouble(),
      predictedTx: (map['predicted_tx'] as num?)?.toInt(),
      actualTx: (map['actual_tx'] as num?)?.toInt(),
    );
  }
}

/// Metrik akurasi lapangan (dihitung dari pemakaian nyata, bukan backtest).
class AccuracyMetrics {
  /// Jumlah titik yang ikut dihitung.
  final int sampleCount;

  /// Titik yang dilewati karena realisasinya nol (MAPE tak terdefinisi).
  final int skippedZeroActual;

  final double mae;
  final double rmse;

  /// Mean Absolute Percentage Error dalam satuan rasio (0.14 = 14%).
  final double? mape;

  /// Symmetric MAPE — lebih stabil saat ada nilai mendekati nol.
  final double? smape;

  const AccuracyMetrics({
    required this.sampleCount,
    this.skippedZeroActual = 0,
    this.mae = 0,
    this.rmse = 0,
    this.mape,
    this.smape,
  });

  static const AccuracyMetrics empty = AccuracyMetrics(sampleCount: 0);

  bool get hasData => sampleCount > 0;

  /// MAPE dalam persen, siap ditampilkan.
  double? get mapePercent => mape == null ? null : mape! * 100;

  /// Akurasi kasar (100% − MAPE), dibatasi di 0 agar tidak negatif di UI.
  double? get accuracyPercent {
    final p = mapePercent;
    if (p == null) return null;
    return math.max(0, 100 - p);
  }
}

/// Perhitungan metrik akurasi prediksi vs realisasi.
///
/// Dipakai layar Akurasi Model (`/smart-analytics/accuracy`) dan menjadi dasar
/// tabel perbandingan LSTM vs baseline pada laporan skripsi.
class ForecastAccuracy {
  ForecastAccuracy._();

  static AccuracyMetrics compute(List<ForecastEvaluationPoint> points) {
    final evaluated = points.where((p) => p.isEvaluated).toList();
    if (evaluated.isEmpty) return AccuracyMetrics.empty;

    double sumAbs = 0;
    double sumSquared = 0;
    double sumPercent = 0;
    double sumSymmetric = 0;
    var percentCount = 0;
    var skipped = 0;

    for (final p in evaluated) {
      final actual = p.actualRevenue!;
      final error = p.predictedRevenue - actual;
      sumAbs += error.abs();
      sumSquared += error * error;

      if (actual == 0) {
        skipped++;
      } else {
        sumPercent += (error / actual).abs();
        percentCount++;
      }

      final denominator = (p.predictedRevenue.abs() + actual.abs()) / 2;
      if (denominator > 0) {
        sumSymmetric += (error.abs() / denominator);
      }
    }

    final n = evaluated.length;
    return AccuracyMetrics(
      sampleCount: n,
      skippedZeroActual: skipped,
      mae: sumAbs / n,
      rmse: math.sqrt(sumSquared / n),
      mape: percentCount > 0 ? sumPercent / percentCount : null,
      smape: sumSymmetric / n,
    );
  }

  /// Metrik per model — inti tabel perbandingan LSTM vs baseline.
  static Map<String, AccuracyMetrics> byModel(
    List<ForecastEvaluationPoint> points,
  ) {
    final grouped = <String, List<ForecastEvaluationPoint>>{};
    for (final p in points.where((p) => p.isEvaluated)) {
      grouped.putIfAbsent(p.modelUsed, () => []).add(p);
    }
    return grouped.map((model, list) => MapEntry(model, compute(list)));
  }

  /// Metrik per horizon (H+1, H+3, H+7, …).
  static Map<int, AccuracyMetrics> byHorizon(
    List<ForecastEvaluationPoint> points,
  ) {
    final grouped = <int, List<ForecastEvaluationPoint>>{};
    for (final p in points.where((p) => p.isEvaluated)) {
      grouped.putIfAbsent(p.horizonDays, () => []).add(p);
    }
    final keys = grouped.keys.toList()..sort();
    return {for (final k in keys) k: compute(grouped[k]!)};
  }

  /// Menyaring titik pada N hari terakhir.
  static List<ForecastEvaluationPoint> lastDays(
    List<ForecastEvaluationPoint> points,
    int days, {
    required DateTime now,
  }) {
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days));
    return points
        .where((p) => !p.targetDate.isBefore(cutoff))
        .toList();
  }

  /// Ekspor CSV untuk lampiran skripsi.
  static String toCsv(List<ForecastEvaluationPoint> points) {
    final buffer = StringBuffer()
      ..writeln(
        'target_date,horizon_days,model_used,predicted_revenue,'
        'actual_revenue,abs_error,pct_error',
      );

    final sorted = [...points]
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    for (final p in sorted) {
      final actual = p.actualRevenue;
      final absError = actual == null
          ? ''
          : (p.predictedRevenue - actual).abs().toStringAsFixed(2);
      final pctError = (actual == null || actual == 0)
          ? ''
          : (((p.predictedRevenue - actual) / actual).abs() * 100)
                .toStringAsFixed(4);

      buffer.writeln(
        '${p.targetDate.toIso8601String().split('T').first},'
        '${p.horizonDays},'
        '${p.modelUsed},'
        '${p.predictedRevenue.toStringAsFixed(2)},'
        '${actual?.toStringAsFixed(2) ?? ''},'
        '$absError,'
        '$pctError',
      );
    }
    return buffer.toString();
  }
}
