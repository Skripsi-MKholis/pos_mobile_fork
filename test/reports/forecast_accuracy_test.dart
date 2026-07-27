import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/features/reports/domain/forecast_accuracy.dart';

void main() {
  ForecastEvaluationPoint point({
    required int day,
    required double predicted,
    double? actual,
    int horizon = 1,
    String model = 'lstm',
  }) {
    return ForecastEvaluationPoint(
      targetDate: DateTime(2026, 7, day),
      horizonDays: horizon,
      modelUsed: model,
      predictedRevenue: predicted,
      actualRevenue: actual,
    );
  }

  group('ForecastAccuracy.compute', () {
    test('menghitung MAE, RMSE, dan MAPE dari contoh yang diketahui', () {
      // Galat: +100, -200 → MAE 150; RMSE = sqrt((100²+200²)/2) ≈ 158,11
      // MAPE = (100/1000 + 200/2000)/2 = 10%
      final metrics = ForecastAccuracy.compute([
        point(day: 1, predicted: 1100, actual: 1000),
        point(day: 2, predicted: 1800, actual: 2000),
      ]);

      expect(metrics.sampleCount, 2);
      expect(metrics.mae, 150);
      expect(metrics.rmse, closeTo(158.11, 0.01));
      expect(metrics.mape, closeTo(0.10, 0.0001));
      expect(metrics.mapePercent, closeTo(10, 0.01));
      expect(metrics.accuracyPercent, closeTo(90, 0.01));
    });

    test('titik tanpa realisasi diabaikan', () {
      final metrics = ForecastAccuracy.compute([
        point(day: 1, predicted: 1100, actual: 1000),
        point(day: 2, predicted: 9999), // belum dievaluasi
      ]);

      expect(metrics.sampleCount, 1);
      expect(metrics.mae, 100);
    });

    test('realisasi nol dilewati dari MAPE, bukan menghasilkan Infinity', () {
      final metrics = ForecastAccuracy.compute([
        point(day: 1, predicted: 500, actual: 0),
        point(day: 2, predicted: 1100, actual: 1000),
      ]);

      expect(metrics.sampleCount, 2);
      expect(metrics.skippedZeroActual, 1);
      expect(metrics.mape, closeTo(0.10, 0.0001));
      expect(metrics.mape!.isFinite, isTrue);
    });

    test('semua realisasi nol menghasilkan MAPE null, bukan NaN', () {
      final metrics = ForecastAccuracy.compute([
        point(day: 1, predicted: 500, actual: 0),
      ]);

      expect(metrics.mape, isNull);
      expect(metrics.accuracyPercent, isNull);
      expect(metrics.mae, 500);
    });

    test('daftar kosong menghasilkan metrik kosong', () {
      final metrics = ForecastAccuracy.compute([]);
      expect(metrics.hasData, isFalse);
      expect(metrics.sampleCount, 0);
    });

    test('akurasi tidak pernah negatif meski MAPE > 100%', () {
      final metrics = ForecastAccuracy.compute([
        point(day: 1, predicted: 5000, actual: 1000), // galat 400%
      ]);

      expect(metrics.mapePercent, closeTo(400, 0.01));
      expect(metrics.accuracyPercent, 0);
    });
  });

  group('pengelompokan untuk tabel perbandingan skripsi', () {
    final points = [
      point(day: 1, predicted: 1100, actual: 1000, model: 'lstm'),
      point(day: 2, predicted: 1050, actual: 1000, model: 'lstm'),
      point(day: 1, predicted: 1400, actual: 1000, model: 'seasonal_naive'),
      point(day: 2, predicted: 1300, actual: 1000, model: 'seasonal_naive'),
    ];

    test('byModel memisahkan LSTM dari baseline', () {
      final byModel = ForecastAccuracy.byModel(points);

      expect(byModel.keys, containsAll(['lstm', 'seasonal_naive']));
      expect(byModel['lstm']!.mae, 75);
      expect(byModel['seasonal_naive']!.mae, 350);
      // Inti klaim skripsi: LSTM harus mengalahkan baseline.
      expect(byModel['lstm']!.mape!, lessThan(byModel['seasonal_naive']!.mape!));
    });

    test('byHorizon mengelompokkan per H+n dan terurut', () {
      final byHorizon = ForecastAccuracy.byHorizon([
        point(day: 1, predicted: 1100, actual: 1000, horizon: 7),
        point(day: 2, predicted: 1050, actual: 1000, horizon: 1),
        point(day: 3, predicted: 1020, actual: 1000, horizon: 1),
      ]);

      expect(byHorizon.keys.toList(), [1, 7]);
      expect(byHorizon[1]!.sampleCount, 2);
      expect(byHorizon[7]!.mae, 100);
    });
  });

  group('lastDays', () {
    test('menyaring titik di luar jendela', () {
      final now = DateTime(2026, 7, 28);
      final filtered = ForecastAccuracy.lastDays([
        point(day: 27, predicted: 1, actual: 1),
        point(day: 20, predicted: 1, actual: 1),
        point(day: 10, predicted: 1, actual: 1),
      ], 10, now: now);

      expect(filtered, hasLength(2));
    });
  });

  group('ekspor CSV', () {
    test('menghasilkan header dan baris yang bisa dibaca spreadsheet', () {
      final csv = ForecastAccuracy.toCsv([
        point(day: 2, predicted: 1100, actual: 1000),
        point(day: 1, predicted: 900),
      ]);

      final lines = csv.trim().split('\n');
      expect(lines.first, startsWith('target_date,horizon_days,model_used'));
      expect(lines, hasLength(3));
      // Terurut menaik berdasarkan tanggal.
      expect(lines[1], startsWith('2026-07-01'));
      expect(lines[2], contains('2026-07-02'));
      expect(lines[2], contains('100.00')); // absolute error
    });

    test('titik tanpa realisasi tetap tercatat dengan kolom kosong', () {
      final csv = ForecastAccuracy.toCsv([point(day: 1, predicted: 900)]);
      expect(csv.trim().split('\n')[1], endsWith(',,,'));
    });
  });
}
