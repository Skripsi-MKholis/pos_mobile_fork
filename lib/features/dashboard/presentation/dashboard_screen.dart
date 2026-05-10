import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final analyticsAsync = ref.watch(analyticsProvider);
    final productsAsync = ref.watch(productNotifierProvider);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(analyticsProvider.notifier).fetchAnalytics();
            ref.read(productNotifierProvider.notifier).syncProducts();
          },
          color: Warna.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(
                  analyticsAsync,
                  productsAsync,
                  currencyFormat,
                  theme,
                ),
                const SizedBox(height: 24),
                _buildSalesPerformanceCard(analyticsAsync, theme),
                const SizedBox(height: 24),
              Text(
                'AKSES CEPAT',
                style: theme.textTheme.muted.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
                const SizedBox(height: 16),
                _buildQuickAccessGrid(context, theme),
                const SizedBox(height: 85),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, ShadThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildAccessCard(
          theme,
          TablerIcons.cash,
          'Transaksi',
          'Buka kasir baru',
          onTap: () => context.go('/pos'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.package,
          'Produk',
          'Kelola stok barang',
          onTap: () => context.push('/products'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.chart_dots,
          'Laporan',
          'Analisis performa',
          onTap: () => context.go('/reports'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.settings,
          'Pengaturan',
          'Konfigurasi aplikasi',
          onTap: () => context.go('/settings'),
        ),
      ],
    );
  }

  Widget _buildAccessCard(
    ShadThemeData theme,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    TablerIcons.arrow_right,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.foreground,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    AsyncValue<AnalyticsState> analyticsAsync,
    AsyncValue<List<dynamic>> productsAsync,
    NumberFormat format,
    ShadThemeData theme,
  ) {
    final analytics = analyticsAsync.value;
    final products = productsAsync.value;
    final isLoading = analyticsAsync.isLoading;
    final isProductsLoading = productsAsync.isLoading;

    final lowStockCount = products == null
        ? 0
        : products.where((p) => (p.stockQuantity ?? 0) <= 5).length;
    final todayRevenue = analytics == null
        ? 0
        : (analytics.dailySales.isEmpty
            ? 0
            : analytics.dailySales.last['amount']);
    final totalTransactions = analytics == null ? 0 : analytics.totalTransactions;
    final totalRevenue = analytics == null ? 0 : analytics.totalRevenue;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Omzet Hari Ini',
          format.format(todayRevenue),
          TablerIcons.wallet,
          theme,
          accentColor: theme.colorScheme.primary,
          isLoading: isLoading,
        ),
        _buildStatCard(
          'Transaksi Selesai',
          totalTransactions.toString(),
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
        ),
        _buildStatCard(
          'Estimasi Laba Kotor',
          format.format(totalRevenue * 0.3),
          TablerIcons.chart_line,
          theme,
          accentColor: Colors.teal,
          isLoading: isLoading,
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
  }) {
    return ShadCard(
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
              style: TextStyle(
                fontSize: 20,
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
    );
  }

  Widget _buildSalesPerformanceCard(
    AsyncValue<AnalyticsState> analyticsAsync,
    ShadThemeData theme,
  ) {
    final state = analyticsAsync.value;
    final isLoading = analyticsAsync.isLoading;

    return ShadCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performa Penjualan',
                    style: theme.textTheme.h4.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Tren omzet 7 hari terakhir',
                    style: theme.textTheme.muted.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const Icon(TablerIcons.trending_up, color: Warna.success),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: isLoading
                ? _buildChartSkeleton(theme)
                : (state != null ? _buildDashboardChart(state, theme) : const SizedBox()),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardChart(AnalyticsState state, ShadThemeData theme) {
    if (state.dailySales.isEmpty) return const SizedBox();

    final maxY = state.dailySales.fold<double>(
      0,
      (max, e) => e['amount'] > max ? (e['amount'] as num).toDouble() : max,
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.0),
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
    ).animate().fadeIn(duration: 800.ms);
  }
  Widget _buildStatsSkeleton(ShadThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(
        4,
        (index) => Shimmer.fromColors(
          baseColor: theme.colorScheme.muted.withOpacity(0.5),
          highlightColor: theme.colorScheme.muted.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSkeleton(ShadThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.muted.withOpacity(0.5),
      highlightColor: theme.colorScheme.muted.withOpacity(0.2),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
