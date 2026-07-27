import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/features/reports/domain/tab_aggregator.dart';
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';
import 'package:pos_mobile/features/reports/models/forecast_tab.dart';

/// Regresi untuk temuan T-03, T-09, T-10, dan T-11 pada
/// `Dokumen/28 Juli - Improve Fitur LSTM.md`.
void main() {
  // Acuan tetap agar hasil uji tidak bergantung tanggal menjalankan test.
  final now = DateTime(2026, 7, 28); // Selasa

  ForecastInput inputWith(
    Map<DateTime, double> sales, {
    Map<DateTime, int>? tx,
    StoreOperationalProfile profile = const StoreOperationalProfile(),
  }) {
    final daily = sales.entries
        .map(
          (e) => DailySalesPoint(
            date: e.key,
            revenue: e.value,
            txCount: tx?[e.key] ?? 10,
          ),
        )
        .toList();
    return ForecastInput(profile: profile, daily: daily);
  }

  ForecastResult forecastWith(
    Map<DateTime, double> predictions, {
    ForecastMode mode = ForecastMode.lstm,
    Map<DateTime, int>? tx,
    bool withInterval = false,
  }) {
    return ForecastResult(
      metadata: ForecastMetadata(mode: mode, generatedAt: now),
      daily: predictions.entries
          .map(
            (e) => ForecastPoint(
              date: e.key,
              revenue: e.value,
              txCount: tx?[e.key],
              revenueLow: withInterval ? e.value * 0.8 : null,
              revenueHigh: withInterval ? e.value * 1.2 : null,
            ),
          )
          .toList(),
    );
  }

  group('T-03: data historis tidak boleh difabrikasi', () {
    test('hari tanpa transaksi bernilai 0 dan ditandai hasActual=false', () {
      // Hanya dua dari lima hari terakhir yang punya transaksi.
      final input = inputWith({
        DateTime(2026, 7, 26): 500000,
        DateTime(2026, 7, 28): 700000,
      });
      final forecast = forecastWith({
        DateTime(2026, 7, 29): 900000,
        DateTime(2026, 7, 30): 950000,
      });

      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: input,
        forecast: forecast,
      );

      expect(data.actualPoints, hasLength(5));
      // 24, 25, 27 Juli tidak punya transaksi.
      expect(data.actualPoints[0].y, 0);
      expect(data.actualPoints[0].hasActual, isFalse);
      expect(data.actualPoints[1].y, 0);
      expect(data.actualPoints[1].hasActual, isFalse);
      expect(data.actualPoints[3].y, 0);
      expect(data.actualPoints[3].hasActual, isFalse);

      // Hari yang benar-benar ada transaksinya memakai nilai aslinya.
      expect(data.actualPoints[2].y, 500000);
      expect(data.actualPoints[2].hasActual, isTrue);
      expect(data.actualPoints[4].y, 700000);
      expect(data.actualPoints[4].hasActual, isTrue);
    });

    test('tidak ada titik aktual yang menyamai nilai forecast', () {
      final input = inputWith({DateTime(2026, 7, 28): 700000});
      final forecast = forecastWith({DateTime(2026, 7, 29): 1234567});

      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: input,
        forecast: forecast,
      );

      // Implementasi lama mengisi hari kosong dengan forecast * 0.9.
      for (final point in data.actualPoints) {
        expect(point.y, isNot(closeTo(1234567 * 0.9, 1)));
      }
    });
  });

  group('T-09: label bulan', () {
    test('Juli terbaca "Jul", bukan bergeser satu bulan', () {
      final data = TabAggregator.compute(
        tab: ForecastTab.monthly,
        now: now,
        input: inputWith({DateTime(2026, 7, 10): 100000}),
        forecast: forecastWith({DateTime(2026, 7, 29): 200000}),
      );

      // Lima bulan aktual: Mar, Apr, Mei, Jun, Jul.
      expect(data.xLabels.take(5).toList(), ['Mar', 'Apr', 'Mei', 'Jun', 'Jul']);
    });

    test('Januari terbaca "Jan" (kasus batas pergantian tahun)', () {
      final januari = DateTime(2026, 1, 15);
      final data = TabAggregator.compute(
        tab: ForecastTab.monthly,
        now: januari,
        input: inputWith({januari: 100000}),
        forecast: forecastWith({DateTime(2026, 1, 16): 120000}),
      );

      expect(data.xLabels.take(5).toList(), ['Sep', 'Okt', 'Nov', 'Des', 'Jan']);
    });
  });

  group('T-10: proyeksi bulanan', () {
    test('menjumlahkan tepat hari yang ada di horizon, tanpa menebak', () {
      // Horizon hanya 3 hari, jauh lebih pendek dari 30.
      final forecast = forecastWith({
        DateTime(2026, 7, 29): 100000,
        DateTime(2026, 7, 30): 200000,
        DateTime(2026, 7, 31): 300000,
      });

      final data = TabAggregator.compute(
        tab: ForecastTab.monthly,
        now: now,
        input: inputWith({DateTime(2026, 7, 27): 500000}),
        forecast: forecast,
      );

      expect(data.totalRevenue, 600000);
      // Label menyatakan horizon apa adanya, bukan nama bulan berikutnya.
      expect(data.xLabels.last, '30 Hari*');
      expect(data.note, contains('3 dari 30 hari'));
    });

    test('horizon penuh 30 hari tidak memunculkan catatan cakupan', () {
      final predictions = <DateTime, double>{
        for (int i = 1; i <= 30; i++) now.add(Duration(days: i)): 100000,
      };

      final data = TabAggregator.compute(
        tab: ForecastTab.monthly,
        now: now,
        input: inputWith({DateTime(2026, 7, 27): 500000}),
        forecast: forecastWith(predictions),
      );

      expect(data.totalRevenue, 3000000);
      expect(data.note, isNot(contains('dari 30 hari')));
    });
  });

  group('T-11: pembagian aman', () {
    test('toko tanpa omzet tidak menghasilkan NaN pada teks pembanding', () {
      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: inputWith({DateTime(2026, 7, 27): 0}),
        forecast: forecastWith({DateTime(2026, 7, 29): 100000}),
      );

      expect(data.revenueDiff, 'Belum ada pembanding');
      expect(data.revenueDiff, isNot(contains('NaN')));
      expect(data.revenueDiff, isNot(contains('Infinity')));
    });

    test('maxY tetap berhingga saat semua nilai nol', () {
      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: inputWith({}),
        forecast: forecastWith({}),
      );

      expect(data.maxY.isFinite, isTrue);
      expect(data.maxY, greaterThan(0));
    });

    test('persentase dihitung benar saat ada pembanding', () {
      final input = inputWith({
        DateTime(2026, 7, 26): 1000000,
        DateTime(2026, 7, 27): 1000000,
      });
      // Prediksi dua hari, rata-rata 1.200.000 → +20%.
      final forecast = forecastWith({
        DateTime(2026, 7, 29): 1200000,
        DateTime(2026, 7, 30): 1200000,
      });

      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: input,
        forecast: forecast,
      );

      expect(data.revenueDiff, '+20.0% vs rerata');
    });
  });

  group('horizon di luar jangkauan', () {
    test('tanggal tanpa prediksi dilewati, bukan ditebak dari titik terakhir', () {
      // Model hanya memprediksi besok; lusa tidak ada.
      final forecast = forecastWith({DateTime(2026, 7, 29): 900000});

      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: inputWith({DateTime(2026, 7, 28): 800000}),
        forecast: forecast,
      );

      // Satu titik penyambung + satu titik prediksi.
      expect(data.forecastPoints, hasLength(2));
      expect(data.totalRevenue, 900000);
    });

    test('tanpa prediksi sama sekali, tab menjelaskan alih-alih menampilkan angka palsu', () {
      final data = TabAggregator.compute(
        tab: ForecastTab.weekly,
        now: now,
        input: inputWith({DateTime(2026, 7, 28): 800000}),
        forecast: forecastWith({}),
      );

      expect(data.forecastPoints, isEmpty);
      expect(data.totalRevenue, 0);
      expect(data.note, isNotEmpty);
    });
  });

  group('traffic', () {
    test('memakai tx_count model bila tersedia', () {
      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: inputWith({DateTime(2026, 7, 27): 500000}),
        forecast: forecastWith(
          {DateTime(2026, 7, 29): 100000, DateTime(2026, 7, 30): 100000},
          tx: {DateTime(2026, 7, 29): 12, DateTime(2026, 7, 30): 18},
        ),
      );

      expect(data.trafficText, '30 Pelanggan');
    });

    test('jatuh ke rata-rata historis bila model tidak mengirim tx_count', () {
      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: inputWith(
          {DateTime(2026, 7, 26): 500000, DateTime(2026, 7, 27): 500000},
          tx: {DateTime(2026, 7, 26): 20, DateTime(2026, 7, 27): 20},
        ),
        forecast: forecastWith({
          DateTime(2026, 7, 29): 100000,
          DateTime(2026, 7, 30): 100000,
        }),
      );

      // Rata-rata 20 transaksi/hari × 2 hari prediksi.
      expect(data.trafficText, '40 Pelanggan');
    });
  });

  group('tab kustom', () {
    test('menghormati rentang yang dipilih pengguna', () {
      final predictions = <DateTime, double>{
        for (int i = 1; i <= 10; i++) now.add(Duration(days: i)): 100000,
      };

      final data = TabAggregator.compute(
        tab: ForecastTab.custom,
        now: now,
        input: inputWith({DateTime(2026, 7, 27): 500000}),
        forecast: forecastWith(predictions),
        customFrom: DateTime(2026, 8, 1),
        customTo: DateTime(2026, 8, 3),
      );

      expect(data.totalRevenue, 300000);
    });

    test('rentang di masa lalu digeser ke hari pertama horizon', () {
      final predictions = <DateTime, double>{
        for (int i = 1; i <= 5; i++) now.add(Duration(days: i)): 100000,
      };

      final data = TabAggregator.compute(
        tab: ForecastTab.custom,
        now: now,
        input: inputWith({DateTime(2026, 7, 27): 500000}),
        forecast: forecastWith(predictions),
        customFrom: DateTime(2026, 7, 1),
        customTo: DateTime(2026, 7, 30),
      );

      // Hanya 29 & 30 Juli yang berada di dalam horizon.
      expect(data.totalRevenue, 200000);
    });
  });

  group('interval prediksi', () {
    test('pita interval ikut terbawa ke titik forecast', () {
      final data = TabAggregator.compute(
        tab: ForecastTab.daily,
        now: now,
        input: inputWith({DateTime(2026, 7, 27): 500000}),
        forecast: forecastWith(
          {DateTime(2026, 7, 29): 1000000},
          withInterval: true,
        ),
      );

      expect(data.hasInterval, isTrue);
      expect(data.forecastPoints.last.low, 800000);
      expect(data.forecastPoints.last.high, 1200000);
      // maxY memperhitungkan batas atas interval.
      expect(data.maxY, greaterThanOrEqualTo(1200000));
    });
  });
}
