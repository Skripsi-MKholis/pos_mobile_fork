import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/ads/banner_ad_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
      locale: Localizations.localeOf(context).toString() == 'en'
          ? 'en_US'
          : 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
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
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n, theme),
            const SizedBox(height: 24),
            if (isAdmin) ...[
              _buildTimeFilter(ref, l10n, theme),
              const SizedBox(height: 16),
            ],
            _buildStatsGrid(
              context,
              l10n,
              analyticsAsync,
              productsAsync,
              currencyFormat,
              theme,
              isAdmin,
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              _buildSalesPerformanceCard(analyticsAsync, l10n, theme),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.quickAccess,
              style: theme.textTheme.muted.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAccessGrid(context, l10n, theme, ref, isAdmin),
            const Center(
              child: BannerAdWidget(padding: EdgeInsets.only(top: 24)),
            ),
            const SizedBox(height: 85),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(
    BuildContext context,
    AppLocalizations l10n,
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
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildAccessCard(
          theme,
          TablerIcons.cash,
          l10n.transaction,
          l10n.openNewCashier,
          onTap: () => context.go('/pos'),
        ),
        if (isAdmin)
          _buildAccessCard(
            theme,
            TablerIcons.package,
            l10n.product,
            l10n.manageProductStock,
            onTap: () => context.push('/products'),
          ),
        if (hasTables)
          _buildAccessCard(
            theme,
            TablerIcons.armchair,
            l10n.tableManagement,
            l10n.setupTableLayout,
            onTap: () => context.push('/tables'),
          ),
        if (hasKds)
          _buildAccessCard(
            theme,
            TablerIcons.device_desktop,
            l10n.kitchenMonitor,
            l10n.kdsDisplay,
            onTap: () => context.push('/kds'),
          ),
        if (isAdmin) ...[
          _buildAccessCard(
            theme,
            TablerIcons.chart_dots,
            l10n.reports,
            l10n.performanceAnalysis,
            onTap: () => context.go('/reports'),
          ),
          _buildAccessCard(
            theme,
            TablerIcons.settings,
            l10n.settings,
            l10n.appConfiguration,
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
    AppLocalizations l10n,
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

    String revenueLabel = l10n.revenueToday;
    String txLabel = l10n.transactionsCompleted;

    switch (range) {
      case AnalyticsTimeRange.today:
        revenueLabel = l10n.revenueToday;
        txLabel = l10n.transactionsToday;
        break;
      case AnalyticsTimeRange.week:
        revenueLabel = l10n.revenueThisWeek;
        txLabel = l10n.transactionsThisWeek;
        break;
      case AnalyticsTimeRange.month:
        revenueLabel = l10n.revenueThisMonth;
        txLabel = l10n.transactionsThisMonth;
        break;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
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
          l10n.lowStock,
          lowStockCount.toString(),
          TablerIcons.package,
          theme,
          accentColor: const Color(0xFFFF6B00),
          isLoading: isProductsLoading,
          onTap: () => context.push('/stock'),
        ),
        _buildStatCard(
          l10n.activeProducts,
          (products?.length ?? 0).toString(),
          TablerIcons.box,
          theme,
          isLoading: isProductsLoading,
          onTap: () => context.push('/products'),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardHeader,
          style: theme.textTheme.muted.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.performanceSummary,
          style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeFilter(
    WidgetRef ref,
    AppLocalizations l10n,
    ShadThemeData theme,
  ) {
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
            l10n.today,
            AnalyticsTimeRange.today,
            currentRange == AnalyticsTimeRange.today,
          ),
          _buildFilterChip(
            ref,
            l10n.thisWeek,
            AnalyticsTimeRange.week,
            currentRange == AnalyticsTimeRange.week,
          ),
          _buildFilterChip(
            ref,
            l10n.thisMonth,
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
    AppLocalizations l10n,
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
                    l10n.salesPerformance,
                    style: theme.textTheme.h4.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    l10n.revenueTrend7Days,
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
                      ? (state.dailySales.isNotEmpty
                            ? _buildDashboardChart(state, theme)
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      TablerIcons.chart_line,
                                      size: 32,
                                      color: theme.colorScheme.mutedForeground
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Belum ada data penjualan 7 hari terakhir',
                                      style: theme.textTheme.muted.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
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
