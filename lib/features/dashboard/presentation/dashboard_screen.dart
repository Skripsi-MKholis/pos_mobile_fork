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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Toko',
              style: theme.textTheme.h3.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: theme.textTheme.muted.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(analyticsProvider.notifier).fetchAnalytics();
          ref.read(productNotifierProvider.notifier).syncProducts();
        },
        color: Warna.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              const SizedBox(height: 32),
              _buildSalesPerformanceCard(analyticsAsync, theme),
              const SizedBox(height: 32),
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
              const SizedBox(height: 40),
            ],
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
          onTap: () => context.push('/pos'),
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
          onTap: () => context.push('/reports'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.settings,
          'Pengaturan',
          'Konfigurasi aplikasi',
          onTap: () => context.push('/settings'),
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
                  Icon(TablerIcons.arrow_right, size: 14, color: theme.colorScheme.mutedForeground),
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
              Text(subtitle, style: TextStyle(fontSize: 10, color: theme.colorScheme.mutedForeground)),
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
    return analyticsAsync.when(
      data: (analytics) {
        final lowStockCount = productsAsync.when(
          data: (products) =>
              products.where((p) => (p.stockQuantity ?? 0) <= 5).length,
          loading: () => 0,
          error: (_, __) => 0,
        );

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
              format.format(
                analytics.dailySales.isEmpty
                    ? 0
                    : analytics.dailySales.last['amount'],
              ),
              TablerIcons.wallet,
              theme,
              accentColor: theme.colorScheme.primary,
            ),
            _buildStatCard(
              'Transaksi Selesai',
              analytics.totalTransactions.toString(),
              TablerIcons.shopping_cart,
              theme,
            ),
            _buildStatCard(
              'Stok Rendah',
              lowStockCount.toString(),
              TablerIcons.package,
              theme,
              accentColor: const Color(0xFFFF6B00),
            ),
            _buildStatCard(
              'Estimasi Laba Kotor',
              format.format(
                analytics.totalRevenue * 0.3,
              ),
              TablerIcons.chart_line,
              theme,
              accentColor: Colors.teal,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error: $err'),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    ShadThemeData theme, {
    Color? accentColor,
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
    return analyticsAsync.when(
      data: (state) => ShadCard(
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
            SizedBox(height: 180, child: _buildDashboardChart(state, theme)),
          ],
        ),
      ),
      loading: () => Container(
        height: 250,
        color: theme.colorScheme.muted.withOpacity(0.1),
      ),
      error: (_, __) => const SizedBox.shrink(),
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
}
