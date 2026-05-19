import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final analyticsAsync = ref.watch(analyticsProvider);
    final productsAsync = ref.watch(productNotifierProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin = role?.toLowerCase() == 'owner';

    // Auto switch to 'today' for Kasir if not already
    if (!isAdmin) {
      final analytics = analyticsAsync.value;
      if (analytics != null &&
          analytics.timeRange != AnalyticsTimeRange.today) {
        Future.microtask(
          () => ref
              .read(analyticsProvider.notifier)
              .fetchAnalytics(AnalyticsTimeRange.today),
        );
      }
    }

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
            ref
                .read(analyticsProvider.notifier)
                .fetchAnalytics(
                  isAdmin ? AnalyticsTimeRange.week : AnalyticsTimeRange.today,
                );
            ref.read(productNotifierProvider.notifier).syncProducts();
          },
          color: Warna.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                if (isAdmin) ...[
                  _buildTimeFilter(ref, theme),
                  const SizedBox(height: 16),
                ],
                _buildStatsGrid(
                  context,
                  analyticsAsync,
                  productsAsync,
                  currencyFormat,
                  theme,
                  isAdmin,
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  _buildSalesPerformanceCard(analyticsAsync, theme),
                ],
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
                _buildQuickAccessGrid(context, theme, ref, isAdmin),
                const SizedBox(height: 85),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(
    BuildContext context,
    ShadThemeData theme,
    WidgetRef ref,
    bool isAdmin,
  ) {
    final activeStoreAsync = ref.watch(activeStoreProvider);
    final activeStore = activeStoreAsync.value;
    final settings = activeStore?['settings'] as Map<String, dynamic>?;
    final features = settings?['features'] as Map<String, dynamic>?;

    const hasTables = false; // Sembunyikan untuk sementara waktu
    final hasKds = features?['kds'] == true;

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
        if (isAdmin)
          _buildAccessCard(
            theme,
            TablerIcons.package,
            'Produk',
            'Kelola stok barang',
            onTap: () => context.push('/products'),
          ),
        if (hasTables)
          _buildAccessCard(
            theme,
            TablerIcons.armchair,
            'Manajemen Meja',
            'Atur layout meja',
            onTap: () => context.push('/tables'),
          ),
        if (hasKds)
          _buildAccessCard(
            theme,
            TablerIcons.device_desktop,
            'Monitor Dapur',
            'KDS Display',
            onTap: () => context.push('/kds'),
          ),
        if (isAdmin) ...[
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
    BuildContext context,
    AsyncValue<AnalyticsState> analyticsAsync,
    AsyncValue<List<dynamic>> productsAsync,
    NumberFormat format,
    ShadThemeData theme,
    bool isAdmin,
  ) {
    final analytics = analyticsAsync.value;
    final products = productsAsync.value;
    final isLoading = analyticsAsync.isLoading;
    final isProductsLoading = productsAsync.isLoading;

    final lowStockCount = products == null
        ? 0
        : products.where((p) => (p.stockQuantity ?? 0) <= 5).length;
    final totalTransactions = analytics == null
        ? 0
        : analytics.totalTransactions;
    final totalRevenue = analytics == null ? 0 : analytics.totalRevenue;

    final range = analytics?.timeRange ?? AnalyticsTimeRange.week;

    String revenueLabel = 'Omzet Hari Ini';
    String txLabel = 'Transaksi Selesai';

    switch (range) {
      case AnalyticsTimeRange.today:
        revenueLabel = 'Omzet Hari Ini';
        txLabel = 'Transaksi Hari Ini';
        break;
      case AnalyticsTimeRange.week:
        revenueLabel = 'Omzet Minggu Ini';
        txLabel = 'Transaksi Minggu Ini';
        break;
      case AnalyticsTimeRange.month:
        revenueLabel = 'Omzet Bulan Ini';
        txLabel = 'Transaksi Bulan Ini';
        break;
    }

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
          format.format(totalRevenue),
          TablerIcons.wallet,
          theme,
          accentColor: theme.colorScheme.primary,
          isLoading: isLoading,
        ),
        _buildStatCard(
          txLabel,
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
          onTap: () => context.push('/stock'),
        ),
        _buildStatCard(
          'Produk Aktif',
          (products?.length ?? 0).toString(),
          TablerIcons.box,
          theme,
          isLoading: isProductsLoading,
          onTap: () => context.push('/products'),
        ),
      ],
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DASHBOARD',
          style: theme.textTheme.muted.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ringkasan Performa',
          style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeFilter(WidgetRef ref, ShadThemeData theme) {
    final analytics = ref.watch(analyticsProvider).value;
    final currentRange = analytics?.timeRange ?? AnalyticsTimeRange.week;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                  baseColor: theme.colorScheme.muted.withValues(alpha: 0.5),
                  highlightColor: theme.colorScheme.muted.withValues(
                    alpha: 0.2,
                  ),
                  child: Container(
                    height: 24,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
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
                : (state != null
                      ? _buildDashboardChart(state, theme)
                      : const SizedBox()),
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
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
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
          baseColor: theme.colorScheme.muted.withValues(alpha: 0.5),
          highlightColor: theme.colorScheme.muted.withValues(alpha: 0.2),
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
      baseColor: theme.colorScheme.muted.withValues(alpha: 0.5),
      highlightColor: theme.colorScheme.muted.withValues(alpha: 0.2),
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
