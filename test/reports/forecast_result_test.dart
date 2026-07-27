import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';

void main() {
  group('ForecastMode: pelabelan jujur (T-01)', () {
    test('hanya lstm & lstm_finetuned yang dianggap LSTM', () {
      expect(ForecastMode.fromApi('lstm').isLstm, isTrue);
      expect(ForecastMode.fromApi('lstm_finetuned').isLstm, isTrue);
      expect(ForecastMode.fromApi('seasonal_naive').isLstm, isFalse);
      expect(ForecastMode.fromApi('naive').isLstm, isFalse);
      expect(ForecastMode.fromApi('offline_local').isLstm, isFalse);
    });

    test('nilai tak dikenal tidak pernah diklaim sebagai LSTM', () {
      expect(ForecastMode.fromApi('sesuatu_yang_baru').isLstm, isFalse);
      expect(ForecastMode.fromApi(null).isLstm, isFalse);
      expect(ForecastMode.fromApi(''), ForecastMode.seasonalNaive);
    });

    test('estimasi lokal ditandai bukan berasal dari server', () {
      expect(ForecastMode.offlineLocal.isFromServer, isFalse);
      expect(ForecastMode.seasonalNaive.isFromServer, isTrue);
    });
  });

  group('ForecastResult.fromJson', () {
    test('membaca response v2 lengkap', () {
      final result = ForecastResult.fromJson({
        'metadata': {
          'model_used': 'lstm',
          'model_version': 'lstm-v2.1.0',
          'input_days': 174,
          'min_days_required': 45,
          'generated_at': '2026-07-28T03:10:00Z',
        },
        'metrics': {'backtest_mape': 0.142, 'baseline_mape': 0.231},
        'daily': [
          {
            'date': '2026-07-29',
            'revenue': 1432000,
            'revenue_low': 1180000,
            'revenue_high': 1690000,
            'tx_count': 38,
            'confidence': 0.81,
          },
        ],
        'hourly': [
          {'hour': 12, 'tx_count': 9, 'share': 0.14},
        ],
        'product_demand': [
          {
            'product_name': 'Kopi Susu Aren',
            'predicted_qty': 42,
            'trend': 'up',
          },
        ],
        'recommendations': [
          {'kind': 'happy_hour', 'title': 'Promo Sore', 'desc': ''},
        ],
      });

      expect(result.mode, ForecastMode.lstm);
      expect(result.metadata.modelVersion, 'lstm-v2.1.0');
      expect(result.metrics.mape, 0.142);
      expect(result.metrics.improvementOverBaseline, closeTo(8.9, 0.01));
      expect(result.daily.single.revenue, 1432000);
      expect(result.daily.single.hasInterval, isTrue);
      expect(result.hourly.single.hour, 12);
      expect(result.productDemand.single.trend, DemandTrend.up);
      expect(result.recommendations.single.kind, 'happy_hour');
    });

    test('field yang hilang tidak membuat parsing gagal', () {
      final result = ForecastResult.fromJson({'metadata': {}});

      expect(result.isEmpty, isTrue);
      expect(result.metrics.isEmpty, isTrue);
      expect(result.hourly, isEmpty);
      expect(result.mode.isLstm, isFalse);
    });

    test('bertahan terhadap tipe yang tidak sesuai', () {
      final result = ForecastResult.fromJson({
        'metadata': 'bukan map',
        'daily': 'bukan list',
        'hourly': 42,
      });

      expect(result.daily, isEmpty);
      expect(result.hourly, isEmpty);
    });

    test('bolak-balik JSON mempertahankan nilai', () {
      final original = ForecastResult(
        metadata: ForecastMetadata(
          mode: ForecastMode.lstmFinetuned,
          modelUsedRaw: 'lstm_finetuned',
          inputDays: 120,
          generatedAt: DateTime(2026, 7, 28, 10),
        ),
        daily: [
          ForecastPoint(date: DateTime(2026, 7, 29), revenue: 500000, txCount: 12),
        ],
      );

      final restored = ForecastResult.fromJson(original.toJson());

      expect(restored.mode, ForecastMode.lstmFinetuned);
      expect(restored.metadata.inputDays, 120);
      expect(restored.daily.single.revenue, 500000);
      expect(restored.daily.single.txCount, 12);
    });
  });

  group('ForecastResult: pencarian tanggal', () {
    final result = ForecastResult(
      metadata: ForecastMetadata(
        mode: ForecastMode.lstm,
        generatedAt: DateTime(2026, 7, 28),
      ),
      daily: [
        ForecastPoint(date: DateTime(2026, 7, 29), revenue: 100),
        ForecastPoint(date: DateTime(2026, 7, 30), revenue: 200),
        ForecastPoint(date: DateTime(2026, 7, 31), revenue: 300),
      ],
    );

    test('tanggal di luar horizon mengembalikan null, bukan titik terakhir', () {
      // Implementasi lama mengembalikan prediksi terakhir untuk tanggal apa pun.
      expect(result.revenueForDate(DateTime(2026, 8, 15)), isNull);
      expect(result.revenueForDate(DateTime(2026, 7, 30)), 200);
    });

    test('revenueBetween hanya menjumlahkan tanggal yang tercakup', () {
      expect(
        result.revenueBetween(DateTime(2026, 7, 29), DateTime(2026, 8, 10)),
        600,
      );
      expect(
        result.revenueBetween(DateTime(2026, 7, 30), DateTime(2026, 7, 31)),
        500,
      );
    });

    test('pencocokan tidak terpengaruh komponen jam', () {
      expect(result.revenueForDate(DateTime(2026, 7, 30, 23, 59)), 200);
    });
  });

  group('ProductDemand: kompatibilitas snapshot lama', () {
    test('membaca bentuk lama {name, quantity}', () {
      final demand = ProductDemand.fromJson({
        'name': 'Croissant',
        'category': 'Makanan',
        'quantity': 15,
      });

      expect(demand.productName, 'Croissant');
      expect(demand.predictedQty, 15);
      expect(demand.recommendedQty, 15);
    });

    test('bentuk baru diutamakan bila keduanya ada', () {
      final demand = ProductDemand.fromJson({
        'product_name': 'Kopi',
        'name': 'Lama',
        'predicted_qty': 30,
        'quantity': 10,
        'recommended_qty': 40,
      });

      expect(demand.productName, 'Kopi');
      expect(demand.predictedQty, 30);
      expect(demand.recommendedQty, 40);
    });
  });
}
