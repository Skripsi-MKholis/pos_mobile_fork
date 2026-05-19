import 'dart:io';
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
                      data: (state) => _buildAnalyticsContent(
                        context,
                        state,
                        productsAsync,
                        currencyFormat,
                        theme,
                      ),
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
                onTap: () => context.push('/smart-analytics'),
                borderRadius: BorderRadius.circular(22.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
        )
        .animate(onPlay: (c) => c.repeat())
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
        _buildStatsGrid(
          context,
          state,
          productsAsync,
          format,
          theme,
          revenueLabel,
          txLabel,
        ),
        const SizedBox(height: 16),
        _buildSalesChartCard(state, format, theme, trendLabel),
        const SizedBox(height: 20),
        _buildTopProductsCard(state, format, theme, productsAsync),
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
      padding: EdgeInsets.zero,
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
          onTap: () => context.go('/stock'),
        ),
        _buildStatCard(
          'Produk Aktif',
          (products?.length ?? 0).toString(),
          TablerIcons.box,
          theme,
          isLoading: isProductsLoading,
          onTap: () => context.go('/products'),
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

  Widget _buildSalesChartCard(
    AnalyticsState state,
    NumberFormat format,
    ShadThemeData theme,
    String trendLabel,
  ) {
    if (state.dailySales.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: const Center(child: Text('Tidak ada data penjualan')),
      );
    }

    final maxY = state.dailySales.fold<double>(
      0,
      (max, e) => e['amount'] > max ? (e['amount'] as num).toDouble() : max,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Warna.primary, Warna.primary.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    TablerIcons.presentation_analytics,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tren Penjualan',
                        style: theme.textTheme.h4.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trendLabel
                            .replaceAll('TREN PENJUALAN (', '')
                            .replaceAll(')', ''),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.mutedForeground,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(TablerIcons.trending_up, color: Warna.primary, size: 20),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(
              top: 24,
              bottom: 16,
              left: 16,
              right: 24,
            ),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Colors.black.withOpacity(0.85),
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            format.format(spot.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade100,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 28,
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
                      barWidth: 4.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 3.5,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: Warna.primary,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Warna.primary.withOpacity(0.25),
                            Warna.primary.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxY == 0 ? 1000 : maxY * 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard(
    AnalyticsState state,
    NumberFormat format,
    ShadThemeData theme,
    AsyncValue<List<dynamic>> productsAsync,
  ) {
    if (state.topProducts.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: const Center(child: Text('Belum ada data produk terjual')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Produk Terlaris',
                      style: theme.textTheme.h4.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Volume penjualan tertinggi',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Icon(TablerIcons.crown, color: Warna.primary, size: 20),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.topProducts.length,
            padding: const EdgeInsets.only(bottom: 16),
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final p = state.topProducts[index];
              return _buildProductRow(
                p,
                index + 1,
                format,
                theme,
                productsAsync,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(
    Map<String, dynamic> p,
    int rank,
    NumberFormat format,
    ShadThemeData theme,
    AsyncValue<List<dynamic>> productsAsync,
  ) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Warna.primary;
    } else if (rank == 2) {
      rankColor = Warna.primary.withOpacity(0.8);
    } else if (rank == 3) {
      rankColor = Warna.primary.withOpacity(0.6);
    } else {
      rankColor = theme.colorScheme.mutedForeground.withOpacity(0.4);
    }

    final qty = (p['quantity'] as num).toInt();
    final productName = p['name'] as String? ?? '';
    final products = productsAsync.value;
    dynamic product;
    if (products != null) {
      for (final prod in products) {
        if (prod.name.toLowerCase() == productName.toLowerCase()) {
          product = prod;
          break;
        }
      }
    }

    final imageUrl = product?.imageUrl;
    final localImagePath = product?.localImagePath;
    final sku = product?.sku;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Elegant rank text
          Container(
            width: 24,
            alignment: Alignment.centerLeft,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Product Thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : (localImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(localImagePath)),
                            fit: BoxFit.cover,
                          )
                        : null),
            ),
            child: (imageUrl == null && localImagePath == null)
                ? Icon(
                    TablerIcons.package,
                    color: theme.colorScheme.mutedForeground.withOpacity(0.4),
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Product Name and SKU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sku != null && sku.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sku,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.mutedForeground,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Minimalist Qty Terjual
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$qty',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.foreground,
                ),
              ),
              Text(
                'terjual',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
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
