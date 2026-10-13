import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart';
import 'package:shimmer/shimmer.dart';

/// Halaman Laporan Keuntungan & HPP (Harga Pokok Penjualan)
/// Didedikasikan khusus untuk kalkulasi laba kotor, HPP produk, margin keuntungan, dan efisiensi biaya.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  AnalyticsTimeRange _selectedTimeRange = AnalyticsTimeRange.month;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(analyticsProvider.notifier).fetchAnalytics(_selectedTimeRange);
        ref.read(productNotifierProvider.notifier).syncProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final productsAsync = ref.watch(productNotifierProvider);
    final theme = ShadTheme.of(context);
    final currentLocale = Localizations.localeOf(context).toString();
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';

    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          isIndonesian ? 'Laba & HPP Toko' : 'Profit & COGS',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(analyticsProvider.notifier).fetchAnalytics(_selectedTimeRange);
          await ref.read(productNotifierProvider.notifier).syncProducts();
        },
        color: Warna.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Pengantar Fitur
              _buildHeaderBanner(isIndonesian, theme),
              const SizedBox(height: 20),

            // Filter Periode
            _buildTimeFilter(theme, isIndonesian),
            const SizedBox(height: 20),

            // Konten Perhitungan Laba & HPP
            analyticsAsync.when(
              data: (state) => _buildProfitAndCogsContent(
                state,
                productsAsync,
                currencyFormat,
                theme,
                isIndonesian,
              ),
              loading: () => _buildLoadingSkeleton(theme),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    isIndonesian
                        ? 'Gagal memuat kalkulasi: $err'
                        : 'Failed to load calculations: $err',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isIndonesian, ShadThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Warna.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.calculator,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isIndonesian ? 'Kalkulator Laba & HPP' : 'Profit & COGS Report',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Warna.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Warna.primary, width: 0.8),
                      ),
                      child: const Text(
                        'TOKO',
                        style: TextStyle(
                          color: Warna.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isIndonesian
                      ? 'Analisis Harga Pokok Penjualan (HPP), laba kotor, dan marjin keuntungan tokomu.'
                      : 'Analyze Cost of Goods Sold (COGS), gross profit, and your store margins.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(ShadThemeData theme, bool isIndonesian) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            isIndonesian ? 'Hari Ini' : 'Today',
            AnalyticsTimeRange.today,
          ),
          _buildFilterChip(
            isIndonesian ? 'Minggu Ini' : 'This Week',
            AnalyticsTimeRange.week,
          ),
          _buildFilterChip(
            isIndonesian ? 'Bulan Ini' : 'This Month',
            AnalyticsTimeRange.month,
          ),
          _buildFilterChip(
            isIndonesian ? 'Semua' : 'All Time',
            AnalyticsTimeRange.lifetime,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AnalyticsTimeRange range) {
    final isSelected = _selectedTimeRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTimeRange != range) {
            setState(() => _selectedTimeRange = range);
            ref.read(analyticsProvider.notifier).fetchAnalytics(range);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
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
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitAndCogsContent(
    AnalyticsState state,
    AsyncValue<List<dynamic>> productsAsync,
    NumberFormat format,
    ShadThemeData theme,
    bool isIndonesian,
  ) {
    final products = productsAsync.value ?? [];

    // Map nama produk -> modalPrice / HPP
    final Map<String, double> productCostMap = {};
    for (final p in products) {
      final name = (p.name as String).toLowerCase();
      final modal = (p.modalPrice as num?)?.toDouble() ?? 0.0;
      productCostMap[name] = modal;
    }

    // Hitung Estimasi Total HPP dari produk terjual di periode ini
    double estimatedCogs = 0.0;
    int itemsWithoutCostCount = 0;

    for (final item in state.topProducts) {
      final name = (item['name'] as String? ?? '').toLowerCase();
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      final cost = productCostMap[name];

      if (cost != null && cost > 0) {
        estimatedCogs += (cost * qty);
      } else {
        itemsWithoutCostCount += qty;
      }
    }

    final double totalRevenue = state.totalRevenue;
    final double grossProfit = totalRevenue - estimatedCogs;
    final double profitMargin = totalRevenue > 0
        ? (grossProfit / totalRevenue) * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ringkasan Kartu Profit & HPP
        _buildProfitSummaryGrid(
          totalRevenue: totalRevenue,
          estimatedCogs: estimatedCogs,
          grossProfit: grossProfit,
          profitMargin: profitMargin,
          format: format,
          theme: theme,
          isIndonesian: isIndonesian,
        ),
        const SizedBox(height: 20),

        // Kartu Insight & Edukasi Margin
        _buildMarginInsightCard(
          profitMargin: profitMargin,
          isIndonesian: isIndonesian,
          theme: theme,
        ),
        const SizedBox(height: 20),

        // Rincian HPP Per Produk Terlaris
        _buildProductCogsTable(
          topProducts: state.topProducts,
          productCostMap: productCostMap,
          format: format,
          theme: theme,
          isIndonesian: isIndonesian,
        ),
        const SizedBox(height: 20),

        // Peringatan jika ada produk belum memiliki modal_price
        if (itemsWithoutCostCount > 0)
          _buildMissingCostWarning(
            itemsWithoutCostCount,
            isIndonesian,
          ),

        const SizedBox(height: 100), // Ruang aman floating bottom navbar
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _buildProfitSummaryGrid({
    required double totalRevenue,
    required double estimatedCogs,
    required double grossProfit,
    required double profitMargin,
    required NumberFormat format,
    required ShadThemeData theme,
    required bool isIndonesian,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      padding: EdgeInsets.zero,
      children: [
        _buildMetricCard(
          title: isIndonesian ? 'ESTIMASI LABA KOTOR' : 'GROSS PROFIT',
          value: format.format(grossProfit),
          subtitle: isIndonesian ? 'Omzet - Total HPP' : 'Revenue - COGS',
          icon: TablerIcons.chart_pie,
          color: Colors.green.shade600,
          theme: theme,
        ),
        _buildMetricCard(
          title: isIndonesian ? 'ESTIMASI TOTAL HPP' : 'TOTAL COGS',
          value: format.format(estimatedCogs),
          subtitle: isIndonesian ? 'Modal pokok barang terjual' : 'Cost of sold inventory',
          icon: TablerIcons.shopping_bag,
          color: Colors.orange.shade700,
          theme: theme,
        ),
        _buildMetricCard(
          title: isIndonesian ? 'MARGIN KEUNTUNGAN' : 'PROFIT MARGIN',
          value: '${profitMargin.toStringAsFixed(1)}%',
          subtitle: isIndonesian ? 'Rasio laba terhadap omzet' : 'Profit to revenue ratio',
          icon: TablerIcons.percentage,
          color: Colors.blue.shade600,
          theme: theme,
        ),
        _buildMetricCard(
          title: isIndonesian ? 'TOTAL PENDAPATAN' : 'TOTAL REVENUE',
          value: format.format(totalRevenue),
          subtitle: isIndonesian ? 'Total penjualan kotor' : 'Gross sales revenue',
          icon: TablerIcons.wallet,
          color: Warna.primary,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ShadThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  title,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[600],
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMarginInsightCard({
    required double profitMargin,
    required bool isIndonesian,
    required ShadThemeData theme,
  }) {
    final bool isHealthy = profitMargin >= 25.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHealthy ? Colors.green.shade200 : Colors.amber.shade300,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHealthy ? TablerIcons.circle_check : TablerIcons.alert_circle,
            color: isHealthy ? Colors.green.shade700 : Colors.amber.shade800,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIndonesian
                      ? (isHealthy ? 'Kesehatan Margin Baik' : 'Evaluasi Margin Keuntungan')
                      : (isHealthy ? 'Healthy Profit Margin' : 'Margin Review Recommended'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isHealthy ? Colors.green.shade900 : Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isIndonesian
                      ? (isHealthy
                          ? 'Marjin keuntungan tokomu berada di angka ${profitMargin.toStringAsFixed(1)}%. Strategi penetapan harga saat ini sehat dan efisien.'
                          : 'Marjin keuntungan tokomu saat ini ${profitMargin.toStringAsFixed(1)}%. Pertimbangkan meninjau harga modal produk atau harga jual untuk hasil optimal.')
                      : (isHealthy
                          ? 'Your store margin is ${profitMargin.toStringAsFixed(1)}%. Pricing strategy is sound and profitable.'
                          : 'Current margin is ${profitMargin.toStringAsFixed(1)}%. Consider adjusting wholesale cost or prices.'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isHealthy ? Colors.green.shade800 : Colors.amber.shade900,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCogsTable({
    required List<Map<String, dynamic>> topProducts,
    required Map<String, double> productCostMap,
    required NumberFormat format,
    required ShadThemeData theme,
    required bool isIndonesian,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIndonesian ? 'Rincian HPP Barang Terjual' : 'COGS Breakdown by Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isIndonesian
                          ? 'Perbandingan harga pokok & laba per barang'
                          : 'Cost price vs profit per item sold',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Icon(TablerIcons.receipt_tax, color: Warna.primary, size: 20),
              ],
            ),
          ),
          const Divider(height: 1),
          if (topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  isIndonesian ? 'Belum ada data barang terjual' : 'No sold items data',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade100,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = topProducts[index];
                final name = item['name'] as String? ?? 'Barang';
                final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                final cost = productCostMap[name.toLowerCase()] ?? 0.0;
                final totalItemCogs = cost * qty;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cost > 0
                                  ? 'HPP Satuan: ${format.format(cost)} \u2022 Qty: $qty'
                                  : 'HPP belum diatur \u2022 Qty: $qty',
                              style: TextStyle(
                                fontSize: 10,
                                color: cost > 0 ? Colors.grey[600] : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            format.format(totalItemCogs),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: cost > 0 ? Colors.black87 : Colors.grey[400],
                            ),
                          ),
                          Text(
                            isIndonesian ? 'Total HPP' : 'Total Cost',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMissingCostWarning(int count, bool isIndonesian) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.info_circle, size: 20, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isIndonesian
                  ? 'Terdapat $count unit barang terjual yang belum diisi Harga Modal (HPP). Lengkapi harga modal pada katalog produk untuk kalkulasi keuntungan yang 100% akurat.'
                  : '$count units sold do not have a cost price set. Complete cost prices in your product catalog for 100% accuracy.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(ShadThemeData theme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: List.generate(
              4,
              (index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 220,
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
