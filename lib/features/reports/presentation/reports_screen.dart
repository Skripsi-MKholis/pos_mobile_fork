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
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:shimmer/shimmer.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final productsAsync = ref.watch(productNotifierProvider);
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
                    _buildTimeFilter(ref, theme),
                    const SizedBox(height: 24),
                    analyticsAsync.when(
                      data: (state) =>
                          _buildAnalyticsContent(context, state, productsAsync, currencyFormat, theme),
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
      padding: const EdgeInsets.all(1.5), // Border thickness
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4285F4), // Google Blue
            Color(0xFF9B72CB), // Purple
            Color(0xFFD96570), // Red/Pink
            Color(0xFFF4AF5F), // Yellow/Orange
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/reports/smart'),
            borderRadius: BorderRadius.circular(22.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF4285F4),
                        Color(0xFF9B72CB),
                        Color(0xFFD96570),
                      ],
                    ).createShader(bounds),
                    child: const Icon(
                      TablerIcons.sparkles,
                      color: Colors.white,
                      size: 24,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Prediksi stok & tren dengan AI',
                          style: theme.textTheme.muted.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    TablerIcons.chevron_right,
                    color: theme.colorScheme.mutedForeground,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(duration: 3.seconds, color: Colors.blue.withOpacity(0.05));
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    AnalyticsState state,
    AsyncValue<List<dynamic>> productsAsync,
    NumberFormat format,
    ShadThemeData theme,
  ) {
    String revenueLabel = 'Omzet Hari Ini';
    String txLabel = 'Transaksi Hari Ini';
    String trendLabel = 'TREN PENJUALAN (HARI INI)';

    switch (state.timeRange) {
      case AnalyticsTimeRange.today:
        revenueLabel = 'Omzet Hari Ini';
        txLabel = 'Transaksi Hari Ini';
        trendLabel = 'TREN PENJUALAN (HARI INI)';
        break;
      case AnalyticsTimeRange.week:
        revenueLabel = 'Omzet Minggu Ini';
        txLabel = 'Transaksi Minggu Ini';
        trendLabel = 'TREN PENJUALAN (7 HARI)';
        break;
      case AnalyticsTimeRange.month:
        revenueLabel = 'Omzet Bulan Ini';
        txLabel = 'Transaksi Bulan Ini';
        trendLabel = 'TREN PENJUALAN (BULAN INI)';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid(context, state, productsAsync, format, theme, revenueLabel, txLabel),
        const SizedBox(height: 32),
        Text(
          trendLabel,
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
    BuildContext context,
    AnalyticsState state,
    AsyncValue<List<dynamic>> productsAsync,
    NumberFormat format,
    ShadThemeData theme,
    String revenueLabel,
    String txLabel,
  ) {
    final products = productsAsync.value;
    final isLoading = state.isLoading;
    final isProductsLoading = productsAsync.isLoading;

    final lowStockCount = products == null
        ? 0
        : products.where((p) => (p.stockQuantity ?? 0) <= 5).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          revenueLabel,
          format.format(state.totalRevenue),
          TablerIcons.wallet,
          theme,
          accentColor: theme.colorScheme.primary,
          isLoading: isLoading,
        ),
        _buildStatCard(
          txLabel,
          state.totalTransactions.toString(),
          TablerIcons.shopping_cart,
          theme,
          isLoading: isLoading,
        ),
        _buildStatCard(
          'Stok Rendah',
          lowStockCount.toString(),
          TablerIcons.package,
          theme,
          accentColor: const Color(0xFFFF6B00),
          isLoading: isProductsLoading,
          onTap: () => context.go('/inventory'),
        ),
        _buildStatCard(
          'Produk Aktif',
          (products?.length ?? 0).toString(),
          TablerIcons.box,
          theme,
          isLoading: isProductsLoading,
          onTap: () => context.go('/inventory'),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    ShadThemeData theme, {
    Color? accentColor,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.muted.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    icon,
                    size: 14,
                    color: accentColor ?? theme.colorScheme.mutedForeground,
                  ),
                ],
              ),
              const Spacer(),
              if (isLoading)
                Shimmer.fromColors(
                  baseColor: theme.colorScheme.muted.withOpacity(0.5),
                  highlightColor: theme.colorScheme.muted.withOpacity(0.2),
                  child: Container(
                    height: 24,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor ?? theme.colorScheme.foreground,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    TablerIcons.chart_arrows_vertical,
                    size: 10,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Real-time data',
                    style: TextStyle(
                      fontSize: 8,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildTimeFilter(WidgetRef ref, ShadThemeData theme) {
    final analytics = ref.watch(analyticsProvider).value;
    final currentRange = analytics?.timeRange ?? AnalyticsTimeRange.week;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            ref,
            'Hari Ini',
            AnalyticsTimeRange.today,
            currentRange == AnalyticsTimeRange.today,
          ),
          _buildFilterChip(
            ref,
            'Minggu Ini',
            AnalyticsTimeRange.week,
            currentRange == AnalyticsTimeRange.week,
          ),
          _buildFilterChip(
            ref,
            'Bulan Ini',
            AnalyticsTimeRange.month,
            currentRange == AnalyticsTimeRange.month,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref,
    String label,
    AnalyticsTimeRange range,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(analyticsProvider.notifier).fetchAnalytics(range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
