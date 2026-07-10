import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart'
    show AnalyticsTimeRange;
import 'package:pos_mobile/features/reports/providers/sales_performance_provider.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shimmer/shimmer.dart';

/// Halaman Performa Penjualan: grafik dan insight lengkap (tren omzet,
/// distribusi per jam/hari, metode pembayaran, top produk, growth).
/// Semua angka diagregasi di server via RPC `get_sales_performance`.
class SalesPerformanceScreen extends ConsumerStatefulWidget {
  const SalesPerformanceScreen({super.key});

  @override
  ConsumerState<SalesPerformanceScreen> createState() =>
      _SalesPerformanceScreenState();
}

class _SalesPerformanceScreenState
    extends ConsumerState<SalesPerformanceScreen> {
  bool _topByRevenue = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final compact = NumberFormat.compactCurrency(
      locale: locale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final perfAsync = ref.watch(salesPerformanceProvider);
    final range = perfAsync.value?.timeRange ?? AnalyticsTimeRange.week;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.salesPerformance,
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: Warna.primary,
        onRefresh: () =>
            ref.read(salesPerformanceProvider.notifier).fetch(range),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildTimeFilter(l10n, theme, range),
            const SizedBox(height: 16),
            perfAsync.when(
              data: (state) => _buildContent(
                context,
                state,
                l10n,
                theme,
                currency,
                compact,
                locale,
              ),
              loading: () => _buildSkeleton(theme),
              error: (err, _) => Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Text(
                    l10n.failedToLoad(err.toString()),
                    style: theme.textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- filter

  Widget _buildTimeFilter(
    AppLocalizations l10n,
    ShadThemeData theme,
    AnalyticsTimeRange current,
  ) {
    final items = [
      (l10n.today, AnalyticsTimeRange.today),
      (l10n.thisWeek, AnalyticsTimeRange.week),
      (l10n.thisMonth, AnalyticsTimeRange.month),
      (l10n.allTime, AnalyticsTimeRange.lifetime),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.$2 == current;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(salesPerformanceProvider.notifier).fetch(item.$2),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------------------- content

  Widget _buildContent(
    BuildContext context,
    SalesPerformanceState state,
    AppLocalizations l10n,
    ShadThemeData theme,
    NumberFormat currency,
    NumberFormat compact,
    String locale,
  ) {
    if (state.totalTransactions == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            children: [
              Icon(
                TablerIcons.chart_bar_off,
                size: 48,
                color: theme.colorScheme.mutedForeground.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(l10n.noDataPeriod, style: theme.textTheme.muted),
            ],
          ),
        ),
      );
    }

    final decimal = NumberFormat.decimalPattern(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid(state, l10n, theme, currency, compact, decimal),
        const SizedBox(height: 16),
        _buildInsightsCard(state, l10n, theme, locale),
        const SizedBox(height: 16),
        _buildChartCard(
          theme,
          title: l10n.revenueTrend,
          icon: TablerIcons.trending_up,
          child: _buildTrendChart(state, theme, compact),
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          theme,
          title: l10n.salesByHour,
          icon: TablerIcons.clock,
          child: _buildHourChart(state, theme, compact),
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          theme,
          title: l10n.salesByDay,
          icon: TablerIcons.calendar_week,
          child: _buildWeekdayChart(state, theme, compact, locale),
        ),
        const SizedBox(height: 16),
        _buildPaymentCard(state, l10n, theme, currency),
        const SizedBox(height: 16),
        _buildTopProductsCard(state, l10n, theme, currency, decimal),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03, end: 0);
  }

  // ----------------------------------------------------------- stats grid

  Widget _buildStatsGrid(
    SalesPerformanceState state,
    AppLocalizations l10n,
    ShadThemeData theme,
    NumberFormat currency,
    NumberFormat compact,
    NumberFormat decimal,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          theme,
          l10n.revenue,
          currency.format(state.totalRevenue),
          TablerIcons.wallet,
          Warna.primary,
          growth: state.revenueGrowth,
          growthLabel: l10n.vsPreviousPeriod,
        ),
        _statCard(
          theme,
          l10n.transaction,
          decimal.format(state.totalTransactions),
          TablerIcons.shopping_cart,
          Colors.blue,
          growth: state.transactionGrowth,
          growthLabel: l10n.vsPreviousPeriod,
        ),
        _statCard(
          theme,
          l10n.avgPerTransaction,
          currency.format(state.avgTransaction),
          TablerIcons.calculator,
          Colors.purple,
        ),
        _statCard(
          theme,
          l10n.itemsSold,
          decimal.format(state.totalItems),
          TablerIcons.package,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statCard(
    ShadThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color, {
    double? growth,
    String? growthLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (growth != null)
            Row(
              children: [
                Icon(
                  growth >= 0
                      ? TablerIcons.arrow_up_right
                      : TablerIcons.arrow_down_right,
                  size: 12,
                  color: growth >= 0 ? const Color(0xFF5B9E00) : Colors.red,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${growth.abs().toStringAsFixed(1)}% ${growthLabel ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color:
                          growth >= 0 ? const Color(0xFF5B9E00) : Colors.red,
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- insights

  Widget _buildInsightsCard(
    SalesPerformanceState state,
    AppLocalizations l10n,
    ShadThemeData theme,
    String locale,
  ) {
    final busiest = state.busiestHour;
    final bestDay = state.bestWeekday;
    final favPayment =
        state.byPayment.isNotEmpty ? state.byPayment.first : null;

    String weekdayName(int isoDow) {
      // 2024-01-01 adalah Senin (ISO dow 1)
      final ref = DateTime(2024, 1, 1).add(Duration(days: isoDow - 1));
      return DateFormat.EEEE(locale).format(ref);
    }

    final rows = <(IconData, String, String)>[
      if (busiest != null)
        (
          TablerIcons.clock_bolt,
          l10n.busiestHour,
          '${busiest.hour.toString().padLeft(2, '0')}:00 - '
              '${(busiest.hour + 1).toString().padLeft(2, '0')}:00',
        ),
      if (bestDay != null)
        (TablerIcons.calendar_star, l10n.bestDay, weekdayName(bestDay.dow)),
      if (favPayment != null)
        (TablerIcons.credit_card, l10n.paymentMethod, favPayment.method),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Warna.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.bulb, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.insights.toUpperCase(),
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(row.$1, size: 16,
                      color: theme.colorScheme.mutedForeground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                  ),
                  Text(
                    row.$3,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- charts

  Widget _buildChartCard(
    ShadThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Warna.primary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _bucketLabel(AnalyticsTimeRange range, DateTime bucket) {
    switch (range) {
      case AnalyticsTimeRange.today:
        return DateFormat('HH:00').format(bucket);
      case AnalyticsTimeRange.week:
      case AnalyticsTimeRange.month:
        return DateFormat('dd/MM').format(bucket);
      case AnalyticsTimeRange.lifetime:
        return DateFormat('MMM yy').format(bucket);
    }
  }

  Widget _buildTrendChart(
    SalesPerformanceState state,
    ShadThemeData theme,
    NumberFormat compact,
  ) {
    final series = state.series;
    if (series.isEmpty) return const SizedBox(height: 180);
    final maxY =
        series.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: theme.colorScheme.border.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, meta) => Text(
                  compact.format(v),
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (series.length / 5).ceilToDouble().clamp(1, 999),
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _bucketLabel(state.timeRange, series[i].bucket),
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${_bucketLabel(state.timeRange, series[s.x.toInt()].bucket)}\n'
                        '${compact.format(s.y)} • ${series[s.x.toInt()].txCount} tx',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < series.length; i++)
                  FlSpot(i.toDouble(), series[i].amount),
              ],
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: Warna.primary,
              barWidth: 3,
              dotData: FlDotData(show: series.length <= 15),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Warna.primary.withValues(alpha: 0.25),
                    Warna.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourChart(
    SalesPerformanceState state,
    ShadThemeData theme,
    NumberFormat compact,
  ) {
    // Lengkapi 24 jam agar sumbu-x konsisten meski jam tanpa penjualan.
    final amounts = List<double>.filled(24, 0);
    for (final h in state.byHour) {
      amounts[h.hour] = h.amount;
    }
    final maxY = amounts.reduce((a, b) => a > b ? a : b) * 1.2;
    final busiest = state.busiestHour?.hour;

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 4,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    v.toInt().toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${group.x.toString().padLeft(2, '0')}:00\n'
                '${compact.format(rod.toY)}',
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
              BarChartGroupData(x: h, barRods: [
                BarChartRodData(
                  toY: amounts[h],
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                  color: h == busiest
                      ? Warna.primary
                      : Warna.primary.withValues(alpha: 0.35),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayChart(
    SalesPerformanceState state,
    ShadThemeData theme,
    NumberFormat compact,
    String locale,
  ) {
    final amounts = List<double>.filled(7, 0); // index 0 = Senin (ISO 1)
    for (final d in state.byWeekday) {
      amounts[d.dow - 1] = d.amount;
    }
    final maxY = amounts.reduce((a, b) => a > b ? a : b) * 1.2;
    final best = state.bestWeekday?.dow;

    String dayShort(int index) {
      final ref = DateTime(2024, 1, 1).add(Duration(days: index));
      return DateFormat.E(locale).format(ref);
    }

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dayShort(v.toInt()),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${dayShort(group.x)}\n${compact.format(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < 7; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: amounts[i],
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  color: (best != null && i == best - 1)
                      ? Warna.primary
                      : Warna.primary.withValues(alpha: 0.35),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- payment

  Widget _buildPaymentCard(
    SalesPerformanceState state,
    AppLocalizations l10n,
    ShadThemeData theme,
    NumberFormat currency,
  ) {
    if (state.byPayment.isEmpty) return const SizedBox.shrink();
    final total = state.byPayment.fold(0.0, (s, p) => s + p.amount);

    return _buildChartCard(
      theme,
      title: l10n.paymentMethod,
      icon: TablerIcons.credit_card,
      child: Column(
        children: state.byPayment.map((p) {
          final pct = total == 0 ? 0.0 : p.amount / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${p.method} • ${p.txCount} tx',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${currency.format(p.amount)} (${(pct * 100).toStringAsFixed(0)}%)',
                      style: theme.textTheme.muted.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.muted.withValues(alpha: 0.4),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Warna.primary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------------- top produk

  Widget _buildTopProductsCard(
    SalesPerformanceState state,
    AppLocalizations l10n,
    ShadThemeData theme,
    NumberFormat currency,
    NumberFormat decimal,
  ) {
    final list = _topByRevenue ? state.topByRevenue : state.topByQuantity;
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.trophy, size: 16, color: Warna.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.topProducts.toUpperCase(),
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
              _topToggle(l10n.byQuantity, !_topByRevenue,
                  () => setState(() => _topByRevenue = false)),
              const SizedBox(width: 6),
              _topToggle(l10n.byRevenue, _topByRevenue,
                  () => setState(() => _topByRevenue = true)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(list.length, (i) {
            final p = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Warna.primary
                          : theme.colorScheme.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: i == 0
                            ? Colors.black
                            : theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _topByRevenue
                        ? currency.format(p.revenue)
                        : '${decimal.format(p.quantity)} ${l10n.sold}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B9E00),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _topToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- skeleton

  Widget _buildSkeleton(ShadThemeData theme) {
    Widget box(double height) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: theme.colorScheme.muted.withValues(alpha: 0.5),
            highlightColor: theme.colorScheme.muted.withValues(alpha: 0.2),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
    return Column(children: [box(220), box(120), box(240), box(200)]);
  }
}
