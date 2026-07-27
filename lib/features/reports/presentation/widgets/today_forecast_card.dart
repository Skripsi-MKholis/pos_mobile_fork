import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/reports/domain/math_utils.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/recommendation_style.dart';
import 'package:pos_mobile/features/reports/providers/forecast_provider.dart';
import 'package:pos_mobile/features/reports/providers/today_revenue_provider.dart';

/// Kartu "Prediksi Hari Ini" di Dashboard (§8.2).
///
/// Hanya membaca hasil prediksi yang sudah tersimpan — tidak pernah memanggil
/// server model — supaya Dashboard tetap terbuka seketika, termasuk offline.
/// Kartu menyembunyikan diri sendiri bila toko belum pernah menjalankan
/// analisis, agar tidak menampilkan kotak kosong.
class TodayForecastCard extends ConsumerWidget {
  const TodayForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(forecastProvider);
    final summary = summaryAsync.valueOrNull;
    if (summary == null) return const SizedBox.shrink();

    final predicted = summary.today?.revenue;
    if (predicted == null || predicted <= 0) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final today = ref.watch(todayRevenueProvider).valueOrNull;
    final actual = today?.revenue ?? 0;
    final progress = (safeDiv(actual, predicted) ?? 0).clamp(0.0, 1.0);
    final modeStyle = ForecastModeStyle.of(summary.mode);

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: () => context.push('/smart-analytics'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Warna.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    TablerIcons.brain,
                    size: 16,
                    color: Warna.black,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prediksi Hari Ini',
                    style: theme.textTheme.large.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
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
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Realisasi',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(actual),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Perkiraan',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(predicted),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1 ? Warna.success : Warna.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _subtitle(summary, progress),
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (summary.isStale)
                  Text(
                    'perlu disegarkan',
                    style: TextStyle(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: Colors.orange.shade700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(ForecastSummary summary, double progress) {
    final parts = <String>['${(progress * 100).round()}% dari perkiraan'];

    final traffic = summary.today?.txCount;
    if (traffic != null) parts.add('±$traffic transaksi');

    final peak = summary.peakHour;
    if (peak != null) {
      parts.add('jam tersibuk ${peak.hour.toString().padLeft(2, '0')}.00');
    }
    return parts.join(' • ');
  }
}
