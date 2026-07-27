import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/features/reports/data/forecast_notification_service.dart';
import 'package:pos_mobile/features/reports/domain/local_forecast_estimator.dart';
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';

void main() {
  final now = DateTime(2026, 7, 28); // Selasa

  ForecastInput buildInput({
    int days = 30,
    double weekdayRevenue = 1000000,
    double weekendRevenue = 2000000,
    StoreOperationalProfile profile = const StoreOperationalProfile(),
    List<HourlySalesPoint> hourly = const [],
  }) {
    final daily = <DailySalesPoint>[];
    for (int i = days; i >= 1; i--) {
      final date = now.subtract(Duration(days: i));
      final isWeekend = date.weekday >= 6;
      daily.add(
        DailySalesPoint(
          date: date,
          revenue: isWeekend ? weekendRevenue : weekdayRevenue,
          txCount: isWeekend ? 40 : 20,
        ),
      );
    }
    return ForecastInput(profile: profile, daily: daily, hourly: hourly);
  }

  group('T-02: tidak ada keacakan di jalur prediksi', () {
    test('dua pemanggilan dengan input sama menghasilkan angka identik', () {
      final input = buildInput();
      final a = LocalForecastEstimator.estimate(now: now, input: input);
      final b = LocalForecastEstimator.estimate(now: now, input: input);

      expect(a.daily.length, b.daily.length);
      for (int i = 0; i < a.daily.length; i++) {
        expect(a.daily[i].revenue, b.daily[i].revenue);
      }
    });

    test('hasil selalu ditandai sebagai estimasi lokal, bukan LSTM', () {
      final result = LocalForecastEstimator.estimate(
        now: now,
        input: buildInput(),
      );

      expect(result.mode, ForecastMode.offlineLocal);
      expect(result.mode.isLstm, isFalse);
      expect(result.metadata.fallbackReason, isNotNull);
    });
  });

  group('faktor musiman per hari', () {
    test('akhir pekan diprediksi lebih tinggi dari hari kerja', () {
      final result = LocalForecastEstimator.estimate(
        now: now,
        input: buildInput(),
      );

      // 1 Agustus 2026 = Sabtu, 3 Agustus = Senin.
      final sabtu = result.pointForDate(DateTime(2026, 8, 1))!;
      final senin = result.pointForDate(DateTime(2026, 8, 3))!;

      expect(sabtu.revenue, greaterThan(senin.revenue));
    });

    test('hari tutup diprediksi nol, bukan rata-rata', () {
      // Toko tutup Minggu (weekday 7).
      final profile = const StoreOperationalProfile(
        openWeekdays: [1, 2, 3, 4, 5, 6],
      );
      final result = LocalForecastEstimator.estimate(
        now: now,
        input: buildInput(profile: profile),
      );

      // 2 Agustus 2026 = Minggu.
      expect(result.pointForDate(DateTime(2026, 8, 2))!.revenue, 0);
      expect(result.pointForDate(DateTime(2026, 8, 3))!.revenue, greaterThan(0));
    });

    test('bulan tutup diprediksi nol', () {
      final profile = const StoreOperationalProfile(closedMonths: [8]);
      final result = LocalForecastEstimator.estimate(
        now: now,
        input: buildInput(profile: profile),
      );

      final agustus = result.daily.where((p) => p.date.month == 8);
      expect(agustus, isNotEmpty);
      expect(agustus.every((p) => p.revenue == 0), isTrue);
    });

    test('toko tanpa riwayat tidak menghasilkan NaN', () {
      final result = LocalForecastEstimator.estimate(
        now: now,
        input: const ForecastInput(profile: StoreOperationalProfile()),
      );

      expect(result.daily.every((p) => p.revenue.isFinite), isTrue);
      expect(result.daily.every((p) => p.revenue >= 0), isTrue);
    });
  });

  group('rekomendasi jam sepi', () {
    List<HourlySalesPoint> hourlyWith(Map<int, int> txByHour) {
      return [
        for (final entry in txByHour.entries)
          HourlySalesPoint(
            date: now.subtract(const Duration(days: 1)),
            hour: entry.key,
            revenue: entry.value * 50000,
            txCount: entry.value,
          ),
      ];
    }

    test('menemukan jam paling sepi bila distribusinya timpang', () {
      final input = buildInput(
        hourly: hourlyWith({9: 20, 12: 40, 15: 2, 18: 30}),
      );

      final rec = LocalForecastEstimator.quietHourRecommendation(input);

      expect(rec, isNotNull);
      expect(rec!.kind, 'happy_hour');
      expect(rec.payload['hour_from'], 15);
      expect(rec.payload['discount_percent'], 10);
    });

    test('tidak menyarankan apa pun bila distribusi jam merata', () {
      final input = buildInput(
        hourly: hourlyWith({9: 20, 12: 22, 15: 19, 18: 21}),
      );

      expect(LocalForecastEstimator.quietHourRecommendation(input), isNull);
    });

    test('butuh minimal empat jam berbeda', () {
      final input = buildInput(hourly: hourlyWith({12: 40, 15: 1}));
      expect(LocalForecastEstimator.quietHourRecommendation(input), isNull);
    });

    test('tanpa data per jam tidak menghasilkan rekomendasi', () {
      expect(
        LocalForecastEstimator.quietHourRecommendation(buildInput()),
        isNull,
      );
    });
  });

  group('isi notifikasi prediksi', () {
    ForecastResult resultWith(Map<DateTime, double> daily, {
      List<ProductDemand> demand = const [],
    }) {
      return ForecastResult(
        metadata: ForecastMetadata(
          mode: ForecastMode.lstm,
          generatedAt: now,
        ),
        daily: daily.entries
            .map((e) => ForecastPoint(date: e.key, revenue: e.value))
            .toList(),
        productDemand: demand,
      );
    }

    test('menandai hari ramai saat jauh di atas rata-rata', () {
      final content = ForecastNotificationService.buildContent(
        now: now,
        forecast: resultWith({
          DateTime(2026, 7, 29): 2000000,
          DateTime(2026, 7, 30): 1000000,
          DateTime(2026, 7, 31): 1000000,
        }),
      );

      expect(content, isNotNull);
      expect(content!.title, contains('ramai'));
    });

    test('menandai hari sepi saat jauh di bawah rata-rata', () {
      final content = ForecastNotificationService.buildContent(
        now: now,
        forecast: resultWith({
          DateTime(2026, 7, 29): 400000,
          DateTime(2026, 7, 30): 2000000,
          DateTime(2026, 7, 31): 2000000,
        }),
      );

      expect(content!.title, contains('sepi'));
    });

    test('menyebut produk yang perlu disiapkan', () {
      final content = ForecastNotificationService.buildContent(
        now: now,
        forecast: resultWith(
          {DateTime(2026, 7, 29): 1000000},
          demand: const [
            ProductDemand(productName: 'Kopi Susu Aren', predictedQty: 42),
          ],
        ),
      );

      expect(content!.body, contains('Kopi Susu Aren'));
      expect(content.body, contains('42'));
    });

    test('memperingatkan stok yang akan habis', () {
      final content = ForecastNotificationService.buildContent(
        now: now,
        forecast: resultWith(
          {DateTime(2026, 7, 29): 1000000},
          demand: const [
            ProductDemand(
              productName: 'Croissant',
              predictedQty: 10,
              daysOfStockLeft: 1.2,
            ),
          ],
        ),
      );

      expect(content!.body, contains('Croissant'));
      expect(content.body, contains('habis'));
    });

    test('tidak mengirim apa pun bila besok di luar horizon', () {
      final content = ForecastNotificationService.buildContent(
        now: now,
        forecast: resultWith({DateTime(2026, 8, 15): 1000000}),
      );

      expect(content, isNull);
    });

    test('tidak mengirim apa pun bila besok diprediksi tutup', () {
      final content = ForecastNotificationService.buildContent(
        now: now,
        forecast: resultWith({DateTime(2026, 7, 29): 0}),
      );

      expect(content, isNull);
    });
  });
}
