import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:pos_mobile/features/reports/domain/math_utils.dart';
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';
import 'package:pos_mobile/features/reports/models/forecast_tab.dart';
import 'package:pos_mobile/features/reports/models/tab_analytics_data.dart';

/// Mengubah riwayat penjualan + hasil prediksi menjadi data siap-tampil untuk
/// grafik Smart Analitik.
///
/// Seluruh fungsi di kelas ini **murni**: tanpa I/O, tanpa `DateTime.now()`
/// implisit, tanpa angka acak. Itu yang membuatnya bisa diuji unit dan
/// mencegah kembalinya masalah lama:
///
/// * **T-02** — tidak ada `Random` di jalur prediksi.
/// * **T-03** — hari tanpa transaksi bernilai `0` dan ditandai
///   `hasActual: false`, tidak lagi diisi hasil forecast lalu digambar
///   sebagai data riil.
/// * **T-09** — label bulan memakai indeks `month - 1` pada daftar yang
///   diawali Januari.
/// * **T-10** — proyeksi "bulanan" memakai horizon 30 hari ke depan secara
///   eksplisit, bukan menjumlahkan H+1…H+n lalu menyebutnya bulan berikutnya.
/// * **T-11** — semua pembagian dijaga terhadap nol/NaN.
class TabAggregator {
  TabAggregator._();

  static final NumberFormat currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const List<String> dayNames = [
    'Min',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
  ];

  /// Daftar bulan yang benar: indeks 0 = Januari (perbaikan T-09).
  static const List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Horizon default untuk tab bulanan (mengikuti horizon model).
  static const int monthlyHorizonDays = 30;

  static const int defaultCustomDays = 3;

  /// Menghitung keempat tab sekaligus — satu snapshot mencakup semua tampilan.
  static Map<ForecastTab, TabAnalyticsData> computeAll({
    required DateTime now,
    required ForecastInput input,
    required ForecastResult forecast,
  }) {
    return {
      for (final tab in ForecastTab.values)
        tab: compute(tab: tab, now: now, input: input, forecast: forecast),
    };
  }

  static TabAnalyticsData compute({
    required ForecastTab tab,
    required DateTime now,
    required ForecastInput input,
    required ForecastResult forecast,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    switch (tab) {
      case ForecastTab.daily:
        return _daily(today, input, forecast);
      case ForecastTab.weekly:
        return _weekly(today, input, forecast);
      case ForecastTab.monthly:
        return _monthly(today, input, forecast);
      case ForecastTab.custom:
        return _custom(today, input, forecast, customFrom, customTo);
    }
  }

  // ================================================================
  // Tab: Harian — 5 hari aktual, 2 hari prediksi
  // ================================================================
  static TabAnalyticsData _daily(
    DateTime today,
    ForecastInput input,
    ForecastResult forecast,
  ) {
    final sales = input.salesByDate;
    final actual = <ChartPoint>[];
    final labels = <String>[];

    for (int i = 4; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = forecastDateKey(date);
      final has = sales.containsKey(key);
      actual.add(
        ChartPoint(x: (4 - i).toDouble(), y: has ? sales[key]! : 0, hasActual: has),
      );
      labels.add(dayNames[date.weekday % 7]);
    }

    final horizonDates = <DateTime>[];
    for (int i = 1; i <= 2; i++) {
      horizonDates.add(today.add(Duration(days: i)));
    }

    final forecastPoints = _forecastSeries(
      anchorX: 4,
      anchorY: actual.isEmpty ? 0 : actual.last.y,
      dates: horizonDates,
      forecast: forecast,
      labels: labels,
      labelBuilder: (d) => '${dayNames[d.weekday % 7]}*',
    );

    final covered = forecastPoints.length - 1;
    final total = _sumForecast(forecastPoints);

    return _finish(
      actual: actual,
      forecastPoints: forecastPoints,
      labels: labels,
      total: total,
      coveredDays: covered,
      input: input,
      forecast: forecast,
      dates: horizonDates.take(math.max(covered, 0)).toList(),
      emptyNote: 'Prediksi harian belum tersedia untuk rentang ini.',
    );
  }

  // ================================================================
  // Tab: Mingguan — 3 minggu aktual, 7 hari prediksi
  // ================================================================
  static TabAnalyticsData _weekly(
    DateTime today,
    ForecastInput input,
    ForecastResult forecast,
  ) {
    final sales = input.salesByDate;
    final actual = <ChartPoint>[];
    final labels = <String>[];

    for (int w = 2; w >= 0; w--) {
      double sum = 0;
      bool has = false;
      for (int d = 0; d < 7; d++) {
        final date = today.subtract(Duration(days: (w * 7) + d));
        final value = sales[forecastDateKey(date)];
        if (value != null) {
          sum += value;
          has = true;
        }
      }
      actual.add(ChartPoint(x: (2 - w).toDouble(), y: sum, hasActual: has));
      labels.add('Minggu ${3 - w}');
    }

    final horizonDates = <DateTime>[
      for (int i = 1; i <= 7; i++) today.add(Duration(days: i)),
    ];

    final covered = _coveredDates(horizonDates, forecast);
    final total = forecast.revenueBetween(
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: 7)),
    );

    final forecastPoints = <ChartPoint>[
      ChartPoint(
        x: 2,
        y: actual.isEmpty ? 0 : actual.last.y,
        hasActual: false,
      ),
      if (covered.isNotEmpty)
        ChartPoint(
          x: 3,
          y: total,
          hasActual: false,
          low: _intervalSum(covered, forecast, low: true),
          high: _intervalSum(covered, forecast, low: false),
        ),
    ];
    if (covered.isNotEmpty) labels.add('7 Hari*');

    return _finish(
      actual: actual,
      forecastPoints: forecastPoints,
      labels: labels,
      total: total,
      coveredDays: covered.length,
      input: input,
      forecast: forecast,
      dates: covered,
      emptyNote: 'Prediksi 7 hari ke depan belum tersedia.',
      extraNote: covered.length < 7 && covered.isNotEmpty
          ? 'Horizon model hanya mencakup ${covered.length} dari 7 hari.'
          : '',
    );
  }

  // ================================================================
  // Tab: Bulanan — 5 bulan aktual (bulan berjalan parsial), 30 hari prediksi
  // ================================================================
  static TabAnalyticsData _monthly(
    DateTime today,
    ForecastInput input,
    ForecastResult forecast,
  ) {
    final sales = input.salesByDate;
    final actual = <ChartPoint>[];
    final labels = <String>[];

    for (int m = 4; m >= 0; m--) {
      final month = DateTime(today.year, today.month - m, 1);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

      double sum = 0;
      bool has = false;
      for (int d = 0; d < daysInMonth; d++) {
        final date = DateTime(month.year, month.month, d + 1);
        if (date.isAfter(today)) break; // bulan berjalan: sampai hari ini saja
        final value = sales[forecastDateKey(date)];
        if (value != null) {
          sum += value;
          has = true;
        }
      }

      actual.add(ChartPoint(x: (4 - m).toDouble(), y: sum, hasActual: has));
      // Perbaikan T-09: indeks bulan yang benar.
      labels.add(monthNames[month.month - 1]);
    }

    // Perbaikan T-10: proyeksi eksplisit "30 hari ke depan", bukan mengaku
    // sebagai satu bulan kalender penuh.
    final horizonDates = <DateTime>[
      for (int i = 1; i <= monthlyHorizonDays; i++) today.add(Duration(days: i)),
    ];
    final covered = _coveredDates(horizonDates, forecast);
    final total = forecast.revenueBetween(
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: monthlyHorizonDays)),
    );

    final forecastPoints = <ChartPoint>[
      ChartPoint(x: 4, y: actual.isEmpty ? 0 : actual.last.y, hasActual: false),
      if (covered.isNotEmpty)
        ChartPoint(
          x: 5,
          y: total,
          hasActual: false,
          low: _intervalSum(covered, forecast, low: true),
          high: _intervalSum(covered, forecast, low: false),
        ),
    ];
    if (covered.isNotEmpty) labels.add('30 Hari*');

    final notes = <String>['Bulan berjalan dihitung sampai hari ini.'];
    if (covered.isNotEmpty && covered.length < monthlyHorizonDays) {
      notes.add('Horizon model mencakup ${covered.length} dari 30 hari.');
    }

    return _finish(
      actual: actual,
      forecastPoints: forecastPoints,
      labels: labels,
      total: total,
      coveredDays: covered.length,
      input: input,
      forecast: forecast,
      dates: covered,
      emptyNote: 'Prediksi 30 hari ke depan belum tersedia.',
      extraNote: notes.join(' '),
    );
  }

  // ================================================================
  // Tab: Kustom — rentang tanggal pilihan pengguna
  // ================================================================
  static TabAnalyticsData _custom(
    DateTime today,
    ForecastInput input,
    ForecastResult forecast,
    DateTime? customFrom,
    DateTime? customTo,
  ) {
    var from = customFrom == null
        ? today.add(const Duration(days: 1))
        : DateTime(customFrom.year, customFrom.month, customFrom.day);
    var to = customTo == null
        ? today.add(const Duration(days: defaultCustomDays))
        : DateTime(customTo.year, customTo.month, customTo.day);

    if (from.isBefore(today.add(const Duration(days: 1)))) {
      from = today.add(const Duration(days: 1));
    }
    if (to.isBefore(from)) to = from;

    final rangeDays = to.difference(from).inDays + 1;
    final horizonDates = <DateTime>[
      for (int i = 0; i < rangeDays; i++) from.add(Duration(days: i)),
    ];

    final dateLabel = DateFormat('dd/MM');
    final actual = <ChartPoint>[];
    final labels = <String>[];
    final sales = input.salesByDate;

    // Pembanding: jumlah hari yang sama, tepat sebelum hari ini.
    final compareDays = math.min(rangeDays, 7);
    for (int i = compareDays - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = forecastDateKey(date);
      final has = sales.containsKey(key);
      actual.add(
        ChartPoint(
          x: (compareDays - 1 - i).toDouble(),
          y: has ? sales[key]! : 0,
          hasActual: has,
        ),
      );
      labels.add(i == 0 ? 'Hari Ini' : dateLabel.format(date));
    }

    final forecastPoints = _forecastSeries(
      anchorX: (compareDays - 1).toDouble(),
      anchorY: actual.isEmpty ? 0 : actual.last.y,
      dates: horizonDates,
      forecast: forecast,
      labels: labels,
      labelBuilder: (d) => '${dateLabel.format(d)}*',
    );

    final covered = forecastPoints.length - 1;
    final total = _sumForecast(forecastPoints);
    final coveredDates = horizonDates
        .where((d) => forecast.pointForDate(d) != null)
        .toList();

    return _finish(
      actual: actual,
      forecastPoints: forecastPoints,
      labels: labels,
      total: total,
      coveredDays: covered,
      input: input,
      forecast: forecast,
      dates: coveredDates,
      emptyNote:
          'Rentang yang dipilih berada di luar horizon prediksi model '
          '(${forecast.daily.length} hari).',
      extraNote: covered > 0 && covered < rangeDays
          ? 'Hanya $covered dari $rangeDays hari yang tercakup horizon model.'
          : '',
    );
  }

  // ================================================================
  // Helper
  // ================================================================

  /// Membangun deret titik prediksi harian: satu titik penyambung ke data
  /// aktual terakhir, lalu satu titik per tanggal yang ada di horizon model.
  /// Tanggal di luar horizon **dilewati**, tidak ditebak.
  static List<ChartPoint> _forecastSeries({
    required double anchorX,
    required double anchorY,
    required List<DateTime> dates,
    required ForecastResult forecast,
    required List<String> labels,
    required String Function(DateTime) labelBuilder,
  }) {
    final points = <ChartPoint>[
      ChartPoint(x: anchorX, y: anchorY, hasActual: false),
    ];

    var x = anchorX;
    for (final date in dates) {
      final point = forecast.pointForDate(date);
      if (point == null) continue;
      x += 1;
      points.add(
        ChartPoint(
          x: x,
          y: point.revenue,
          hasActual: false,
          low: point.revenueLow,
          high: point.revenueHigh,
        ),
      );
      labels.add(labelBuilder(date));
    }
    return points;
  }

  static List<DateTime> _coveredDates(
    List<DateTime> dates,
    ForecastResult forecast,
  ) {
    return dates.where((d) => forecast.pointForDate(d) != null).toList();
  }

  static double _sumForecast(List<ChartPoint> points) {
    if (points.length <= 1) return 0;
    return points.skip(1).fold<double>(0, (sum, p) => sum + p.y);
  }

  /// Menjumlahkan batas interval; null bila server tidak mengirim interval.
  static double? _intervalSum(
    List<DateTime> dates,
    ForecastResult forecast, {
    required bool low,
  }) {
    double sum = 0;
    var any = false;
    for (final date in dates) {
      final p = forecast.pointForDate(date);
      final bound = low ? p?.revenueLow : p?.revenueHigh;
      if (bound == null) return null;
      sum += bound;
      any = true;
    }
    return any ? sum : null;
  }

  /// Teks pembanding terhadap rata-rata historis harian.
  static String _diffText(double predictedDailyAvg, double historicalDailyAvg) {
    final ratio = safeDiv(
      predictedDailyAvg - historicalDailyAvg,
      historicalDailyAvg,
    );
    if (ratio == null) return 'Belum ada pembanding';
    final percent = ratio * 100;
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}% vs rerata';
  }

  /// Estimasi jumlah pelanggan untuk daftar tanggal prediksi.
  /// Memakai `tx_count` dari model bila ada; jika tidak, memakai rata-rata
  /// historis (bukan angka acak).
  static String _trafficText(
    List<DateTime> dates,
    ForecastResult forecast,
    ForecastInputStats stats,
  ) {
    if (dates.isEmpty) return '0 Pelanggan';

    var total = 0;
    var fromModel = false;
    for (final date in dates) {
      final tx = forecast.pointForDate(date)?.txCount;
      if (tx != null) {
        total += tx;
        fromModel = true;
      }
    }

    if (!fromModel) {
      total = (stats.avgDailyTraffic * dates.length).round();
    }
    return '$total Pelanggan';
  }

  static TabAnalyticsData _finish({
    required List<ChartPoint> actual,
    required List<ChartPoint> forecastPoints,
    required List<String> labels,
    required double total,
    required int coveredDays,
    required ForecastInput input,
    required ForecastResult forecast,
    required List<DateTime> dates,
    required String emptyNote,
    String extraNote = '',
  }) {
    final stats = input.stats;
    final hasForecast = coveredDays > 0;

    final dailyAvg = hasForecast ? safeDiv(total, coveredDays.toDouble()) : null;
    final revenueDiff = dailyAvg == null
        ? 'Belum ada pembanding'
        : _diffText(dailyAvg, stats.avgDailyRevenue);

    final allPoints = [...actual, ...forecastPoints];
    double maxValue = 0;
    for (final p in allPoints) {
      maxValue = math.max(maxValue, math.max(p.y, p.high ?? 0));
    }
    var maxY = maxValue * 1.25;
    if (maxY <= 0 || !maxY.isFinite) maxY = 1000000;

    final notes = <String>[
      if (!hasForecast) emptyNote,
      if (extraNote.isNotEmpty) extraNote,
    ];

    return TabAnalyticsData(
      totalRevenue: total,
      revenueText: currency.format(total),
      revenueDiff: revenueDiff,
      trafficText: _trafficText(dates, forecast, stats),
      actualPoints: actual,
      forecastPoints: hasForecast ? forecastPoints : const [],
      xLabels: labels,
      maxY: maxY,
      note: notes.join(' '),
    );
  }
}
