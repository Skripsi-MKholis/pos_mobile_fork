import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/recommendation_style.dart';
import 'package:pos_mobile/features/reports/providers/forecast_provider.dart';

/// Prediksi distribusi transaksi per jam untuk perencanaan shift (§8.5).
///
/// Menyembunyikan diri bila model belum menghasilkan seri per jam, agar
/// layar Performa Penjualan tidak menampilkan grafik kosong.
class HourlyForecastCard extends ConsumerWidget {
  const HourlyForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(forecastProvider).valueOrNull;
    final hourly = summary?.forecast.hourly ?? const [];
    if (summary == null || hourly.isEmpty) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final modeStyle = ForecastModeStyle.of(summary.mode);

    final counts = List<double>.filled(24, 0);
    for (final h in hourly) {
      if (h.hour < 0 || h.hour > 23) continue;
      counts[h.hour] = h.txCount.toDouble();
    }
    final maxY = counts.reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) return const SizedBox.shrink();

    final peakHour = summary.peakHour?.hour;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  TablerIcons.clock_bolt,
                  size: 16,
                  color: Warna.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perkiraan Jam Ramai',
                      style: theme.textTheme.large.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      peakHour == null
                          ? 'Distribusi transaksi per jam'
                          : 'Puncak diperkirakan pukul '
                                '${peakHour.toString().padLeft(2, '0')}.00',
                      style: theme.textTheme.muted.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Icon(modeStyle.icon, size: 12, color: modeStyle.color),
              const SizedBox(width: 4),
              Text(
                summary.mode.shortLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: modeStyle.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (v, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          v.toInt().toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${group.x.toString().padLeft(2, '0')}.00\n'
                      '±${rod.toY.round()} transaksi',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (int h = 0; h < 24; h++)
                    BarChartGroupData(
                      x: h,
                      barRods: [
                        BarChartRodData(
                          toY: counts[h],
                          width: 8,
                          borderRadius: BorderRadius.circular(2),
                          color: h == peakHour
                              ? Warna.primary
                              : Warna.primary.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner tipis di layar POS: mengingatkan jam sibuk yang akan datang (§8.5).
///
/// Hanya membaca cache, dan menghilang setelah jam puncak berlalu agar tidak
/// mengganggu alur kasir.
class PosPeakHourBanner extends ConsumerWidget {
  const PosPeakHourBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(forecastProvider).valueOrNull;
    final peak = summary?.peakHour;
    if (summary == null || peak == null) return const SizedBox.shrink();

    final now = DateTime.now();
    // Tampilkan hanya menjelang jam sibuk (maksimal 3 jam sebelumnya).
    final hoursUntil = peak.hour - now.hour;
    if (hoursUntil < 0 || hoursUntil > 3) return const SizedBox.shrink();

    final label = hoursUntil == 0
        ? 'Sekarang jam tersibuk'
        : 'Jam sibuk ${hoursUntil == 1 ? 'sejam lagi' : '$hoursUntil jam lagi'}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Warna.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Warna.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.clock_bolt, size: 14, color: Warna.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label — pukul ${peak.hour.toString().padLeft(2, '0')}.00, '
              'perkiraan ±${peak.txCount} transaksi.',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Warna.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
