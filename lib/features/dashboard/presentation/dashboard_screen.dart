import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/today_forecast_card.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart';
import 'package:pos_mobile/features/reports/providers/forecast_provider.dart';
import 'package:pos_mobile/features/reports/providers/today_revenue_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/ads/banner_ad_widget.dart';
import 'package:pos_mobile/core/guards/feature_guard.dart';
import 'package:pos_mobile/features/settings/providers/subscription_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final analyticsAsync = ref.watch(analyticsProvider);
    final productsAsync = ref.watch(productNotifierProvider);

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
            .fetchAnalytics(AnalyticsTimeRange.week);
        ref.read(productNotifierProvider.notifier).syncProducts();
        // Menyegarkan pembacaan prediksi tersimpan (bukan memanggil model).
        ref.invalidate(forecastProvider);
        ref.invalidate(todayRevenueProvider);
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
            const SizedBox(height: 16),
            _buildExpiringBanner(context, ref, theme, l10n),
            const SizedBox(height: 8),
            _buildTimeFilter(ref, l10n, theme),
            const SizedBox(height: 16),
            _buildStatsGrid(
              context,
              l10n,
              analyticsAsync,
              productsAsync,
              currencyFormat,
              theme,
            ),
            // Note: Kartu Prediksi Smart Analytics di-hide sementara sesuai preferensi pengguna
            // const TodayForecastCard(),
            // const SizedBox(height: 16),
            const Center(
              child: BannerAdWidget(padding: EdgeInsets.symmetric(vertical: 4)),
            ),
            const SizedBox(height: 16),
            _buildSalesPerformanceCard(context, analyticsAsync, l10n, theme),
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
            _buildQuickAccessGrid(context, l10n, theme, ref),
            const SizedBox(height: 110), // Jarak aman agar tidak tertutup floating bottom bar
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
        _buildAccessCard(
          theme,
          TablerIcons.cash,
          l10n.transaction,
          l10n.openNewCashier,
          onTap: () => context.go('/pos'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.package,
          l10n.product,
          l10n.manageProductStock,
          onTap: () => context.push('/products'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.calculator,
          'Laba & HPP',
          'Analisis Keuntungan',
          onTap: () => context.push('/reports'),
        ),
        _buildAccessCard(
          theme,
          TablerIcons.settings,
          l10n.settings,
          l10n.appConfiguration,
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
      case AnalyticsTimeRange.lifetime:
        revenueLabel = l10n.revenueAllTime;
        txLabel = l10n.transactionsAllTime;
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
          _buildFilterChip(
            ref,
            l10n.allTime,
            AnalyticsTimeRange.lifetime,
            currentRange == AnalyticsTimeRange.lifetime,
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
                // FittedBox: nilai besar (mis. Rp 471.200.494) diskalakan
                // agar tetap satu baris dan tidak overflow di kartu grid.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor ?? theme.colorScheme.foreground,
                    ),
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
    BuildContext context,
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
          const SizedBox(height: 20),
          // Tombol menuju halaman Performa Penjualan lengkap
          Consumer(
            builder: (context, ref, _) {
              final canAccess = ref.watch(canAccessFeatureProvider(AppFeature.advancedReports));
              return SizedBox(
                width: double.infinity,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (!canAccess) {
                      showFeatureLockedDialog(context, AppFeature.advancedReports);
                    } else {
                      context.push('/sales-performance');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: canAccess
                          ? Warna.primary.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: !canAccess
                          ? Border.all(color: Colors.grey.withValues(alpha: 0.2))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!canAccess) ...[
                          const Icon(TablerIcons.lock, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          l10n.viewDetails,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: canAccess ? null : Colors.grey[700],
                          ),
                        ),
                        if (!canAccess) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Warna.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 4),
                          const Icon(TablerIcons.chevron_right, size: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
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

  Widget _buildExpiringBanner(
    BuildContext context,
    WidgetRef ref,
    ShadThemeData theme,
    AppLocalizations l10n,
  ) {
    final subInfo = ref.watch(currentSubscriptionProvider).value;
    if (subInfo == null || !subInfo.isExpiringSoon) {
      return const SizedBox.shrink();
    }

    final days = subInfo.remainingDays ?? 0;
    final textDays = days <= 0
        ? l10n.expiresToday
        : l10n.daysRemaining(days);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.clock_hour_4,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.subscriptionExpiringSoon,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.subscriptionExpiringDesc(subInfo.planName, textDays),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7F1D1D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/subscription-plans'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(l10n.renewNow),
          ),
        ],
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
