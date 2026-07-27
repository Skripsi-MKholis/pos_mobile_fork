import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/reports/data/smart_analytics_repository.dart';
import 'package:pos_mobile/features/reports/domain/forecast_accuracy.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';

/// Titik evaluasi akurasi untuk toko aktif (§8.6).
final _evaluationPointsProvider =
    FutureProvider.autoDispose<List<ForecastEvaluationPoint>>((ref) async {
      final storeId = ref.watch(activeStoreProvider).value?['id']?.toString();
      if (storeId == null) return const [];

      final repository = SmartAnalyticsRepository();
      // Isi dulu realisasi untuk tanggal yang sudah lewat, baru dibaca.
      await repository.evaluateForecastPoints(storeId);
      return repository.fetchEvaluationPoints(storeId);
    });

/// Layar "Akurasi Model": membandingkan prediksi dengan realisasi.
///
/// Ini yang sebelumnya sama sekali tidak ada (T-05). Selain membangun
/// kepercayaan pengguna, isinya adalah materi evaluasi model untuk laporan
/// skripsi — termasuk tombol ekspor CSV.
class ForecastAccuracyScreen extends ConsumerWidget {
  const ForecastAccuracyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final pointsAsync = ref.watch(_evaluationPointsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Akurasi Model',
          style: theme.textTheme.h4.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          pointsAsync.maybeWhen(
            data: (points) => points.any((p) => p.isEvaluated)
                ? IconButton(
                    icon: const Icon(TablerIcons.download, color: Warna.primary),
                    tooltip: 'Salin CSV',
                    onPressed: () => _copyCsv(context, points),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Warna.primary,
          onRefresh: () async => ref.invalidate(_evaluationPointsProvider),
          child: pointsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Warna.primary),
            ),
            error: (e, _) => _message(
              icon: TablerIcons.alert_triangle,
              title: 'Gagal Memuat Evaluasi',
              desc: 'Terjadi kesalahan saat mengambil data akurasi.\n$e',
            ),
            data: (points) {
              final evaluated = points.where((p) => p.isEvaluated).toList();
              if (evaluated.isEmpty) return _emptyState(points.length);
              return _buildContent(context, theme, evaluated);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ShadThemeData theme,
    List<ForecastEvaluationPoint> points,
  ) {
    final now = DateTime.now();
    final last7 = ForecastAccuracy.compute(
      ForecastAccuracy.lastDays(points, 7, now: now),
    );
    final last30 = ForecastAccuracy.compute(
      ForecastAccuracy.lastDays(points, 30, now: now),
    );
    final byModel = ForecastAccuracy.byModel(points);
    final byHorizon = ForecastAccuracy.byHorizon(points);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _explainer(theme, points.length),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _metricCard(theme, '7 Hari', last7)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(theme, '30 Hari', last30)),
          ],
        ),
        const SizedBox(height: 20),
        _chartCard(theme, points),
        const SizedBox(height: 20),
        _modelComparison(theme, byModel),
        const SizedBox(height: 20),
        _horizonTable(theme, byHorizon),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _explainer(ShadThemeData theme, int sampleCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Warna.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Warna.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(TablerIcons.target_arrow, size: 16, color: Warna.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Setiap prediksi disimpan, lalu dibandingkan dengan penjualan '
              'yang benar-benar terjadi. Saat ini $sampleCount prediksi sudah '
              'punya realisasi.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    ShadThemeData theme,
    String label,
    AccuracyMetrics metrics,
  ) {
    final accuracy = metrics.accuracyPercent;
    final color = accuracy == null
        ? Colors.grey.shade400
        : (accuracy >= 80
              ? Warna.success
              : (accuracy >= 60 ? Colors.amber.shade700 : Colors.red.shade600));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.muted.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            accuracy == null ? '—' : '${accuracy.toStringAsFixed(1)}%',
            style: theme.textTheme.h4.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metrics.hasData
                ? 'MAPE ${metrics.mapePercent?.toStringAsFixed(1) ?? '—'}% • '
                      '${metrics.sampleCount} sampel'
                : 'Belum ada sampel',
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    ShadThemeData theme,
    List<ForecastEvaluationPoint> points,
  ) {
    // Ambil maksimal 14 titik terbaru agar grafik tetap terbaca.
    final recent = points.length > 14
        ? points.sublist(points.length - 14)
        : points;

    final predicted = <FlSpot>[];
    final actual = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < recent.length; i++) {
      final p = recent[i];
      predicted.add(FlSpot(i.toDouble(), p.predictedRevenue));
      actual.add(FlSpot(i.toDouble(), p.actualRevenue ?? 0));
      maxY = [maxY, p.predictedRevenue, p.actualRevenue ?? 0].reduce(
        (a, b) => a > b ? a : b,
      );
    }
    if (maxY <= 0) maxY = 1000000;

    final dateFormat = DateFormat('dd/MM');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prediksi vs Realisasi',
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _legendDot(Warna.primary, 'Prediksi'),
              const SizedBox(width: 10),
              _legendDot(Warna.success, 'Riil'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (recent.length / 5).ceilToDouble().clamp(1, 99),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= recent.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dateFormat.format(recent[idx].targetDate),
                            style: TextStyle(
                              fontSize: 8.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: actual,
                    isCurved: true,
                    color: Warna.success,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: predicted,
                    isCurved: true,
                    color: Warna.primary,
                    barWidth: 3,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
    ],
  );

  Widget _modelComparison(
    ShadThemeData theme,
    Map<String, AccuracyMetrics> byModel,
  ) {
    if (byModel.isEmpty) return const SizedBox.shrink();

    final entries = byModel.entries.toList()
      ..sort((a, b) {
        final aMape = a.value.mape ?? double.infinity;
        final bMape = b.value.mape ?? double.infinity;
        return aMape.compareTo(bMape);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perbandingan Model',
          style: theme.textTheme.h4.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dihitung dari pemakaian nyata di toko ini, bukan dari backtest.',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _modelRow(theme, entries[i], isBest: i == 0),
          ),
      ],
    );
  }

  Widget _modelRow(
    ShadThemeData theme,
    MapEntry<String, AccuracyMetrics> entry, {
    required bool isBest,
  }) {
    final mode = ForecastMode.fromApi(entry.key);
    final metrics = entry.value;
    final currency = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBest ? Warna.success.withOpacity(0.4) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mode.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Warna.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TERBAIK',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Warna.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'MAE ${currency.format(metrics.mae)} • '
                  'RMSE ${currency.format(metrics.rmse)} • '
                  '${metrics.sampleCount} sampel',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            metrics.mapePercent == null
                ? '—'
                : '${metrics.mapePercent!.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _horizonTable(
    ShadThemeData theme,
    Map<int, AccuracyMetrics> byHorizon,
  ) {
    if (byHorizon.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akurasi per Jarak Prediksi',
          style: theme.textTheme.h4.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Makin jauh ke depan, biasanya makin besar galatnya.',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Column(
            children: [
              for (final entry in byHorizon.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          'H+${entry.key}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((entry.value.accuracyPercent ?? 0) / 100)
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation(
                              Warna.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 82,
                        child: Text(
                          entry.value.mapePercent == null
                              ? '— (${entry.value.sampleCount})'
                              : 'MAPE ${entry.value.mapePercent!.toStringAsFixed(1)}%',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(int pendingCount) {
    return _message(
      icon: TablerIcons.hourglass_low,
      title: 'Belum Ada Evaluasi',
      desc: pendingCount > 0
          ? 'Ada $pendingCount prediksi yang menunggu tanggalnya lewat. '
                'Akurasi muncul setelah hari yang diprediksi berlalu dan '
                'penjualannya tercatat.'
          : 'Jalankan Smart Analitik beberapa kali, lalu kembali ke sini '
                'setelah tanggal yang diprediksi berlalu.',
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _copyCsv(
    BuildContext context,
    List<ForecastEvaluationPoint> points,
  ) async {
    final csv = ForecastAccuracy.toCsv(points);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    mySnackBar(
      context: context,
      text: 'Data evaluasi (${points.length} baris) disalin sebagai CSV.',
      status: ToastStatus.success,
    );
  }
}
