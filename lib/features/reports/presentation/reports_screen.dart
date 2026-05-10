import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final theme = ShadTheme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => ref.read(analyticsProvider.notifier).fetchAnalytics(),
        color: Warna.primary,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(theme),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSmartAnalyticsButton(context, theme),
                    const SizedBox(height: 24),
                    analyticsAsync.when(
                      data: (state) =>
                          _buildAnalyticsContent(state, currencyFormat, theme),
                      loading: () => _buildLoadingState(theme),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ShadThemeData theme) {
    return SliverAppBar(
      expandedHeight: 0,
      toolbarHeight: 20,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        centerTitle: false,
        title: const Text(''),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: theme.colorScheme.border.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildSmartAnalyticsButton(BuildContext context, ShadThemeData theme) {
    return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Warna.primary, Warna.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Warna.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/reports/smart'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        TablerIcons.sparkles,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Analitik',
                            style: theme.textTheme.h4.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Dapatkan prediksi & saran stok otomatis',
                            style: theme.textTheme.muted.copyWith(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(TablerIcons.chevron_right, color: Colors.black),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildAnalyticsContent(
    AnalyticsState state,
    NumberFormat format,
    ShadThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid(state, format, theme),
        const SizedBox(height: 32),
        Text(
          'TREN PENJUALAN (7 HARI)',
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.mutedForeground,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 24),
        _buildSalesChart(state, theme),
        const SizedBox(height: 40),
        Text(
          'PRODUK TERLARIS',
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.mutedForeground,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        ...state.topProducts.map((p) => _buildProductItem(p, format, theme)),
        const SizedBox(height: 85),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatsGrid(
    AnalyticsState state,
    NumberFormat format,
    ShadThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Omzet',
            format.format(state.totalRevenue),
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Transaksi',
            state.totalTransactions.toString(),
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.h4.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 24,
            decoration: BoxDecoration(
              color: Warna.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(AnalyticsState state, ShadThemeData theme) {
    if (state.dailySales.isEmpty) return const SizedBox(height: 200);

    final maxY = state.dailySales.fold<double>(
      0,
      (max, e) => e['amount'] > max ? (e['amount'] as num).toDouble() : max,
    );

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
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
                getTitlesWidget: (val, meta) {
                  if (val.toInt() >= 0 &&
                      val.toInt() < state.dailySales.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        state.dailySales[val.toInt()]['date'],
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: state.dailySales.asMap().entries.map((e) {
                return FlSpot(
                  e.key.toDouble(),
                  (e.value['amount'] as num).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Warna.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Warna.primary.withOpacity(0.3),
                    Warna.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: maxY * 1.2,
        ),
      ),
    );
  }

  Widget _buildProductItem(
    Map<String, dynamic> p,
    NumberFormat format,
    ShadThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Terjual ${p['quantity']} unit',
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.8, // Placeholder factor
              child: Container(
                decoration: BoxDecoration(
                  color: Warna.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ShadThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.muted.withOpacity(0.5),
      highlightColor: theme.colorScheme.muted.withOpacity(0.2),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
