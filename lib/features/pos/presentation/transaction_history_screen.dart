import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/features/pos/providers/transaction_history_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/ads/banner_ad_widget.dart';
import 'package:pos_mobile/core/guards/feature_guard.dart';
import 'package:pos_mobile/features/reports/providers/analytics_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  // 0: Riwayat Transaksi, 1: Tren & Produk Terlaris
  int _activeSegmentIndex = 0;

  // Optimization: Debouncer prevents expensive UI rebuilds and local filtering on every keystroke.
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String _searchQuery = '';
  String _filterStatus = 'Semua';
  String _sortOrder = 'desc'; // 'desc' for newest, 'asc' for oldest
  String _dateFilter = 'Semua'; // 'Semua', 'Hari Ini', 'Kemarin', 'Custom'
  DateTime? _customDate;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (mounted) {
        ref.read(transactionHistoryProvider.notifier).refresh();
      }
    });
  }

  /// Tanggal terpilih untuk filter server-side (null = semua tanggal).
  DateTime? get _selectedDate {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'Hari Ini':
        return now;
      case 'Kemarin':
        return now.subtract(const Duration(days: 1));
      case 'Custom':
        return _customDate;
      default:
        return null;
    }
  }

  void _applyFilters() {
    ref.read(transactionHistoryProvider.notifier).applyFilters(
          date: _selectedDate,
          status: _filterStatus,
        );
  }

  void _onScroll() {
    if (_activeSegmentIndex == 0 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(transactionHistoryProvider.notifier).fetchMore();
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transactionHistoryProvider);
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('HH:mm');
    final dateFullFormat = DateFormat('dd MMM yyyy');

    return RefreshIndicator(
      onRefresh: () async {
        if (_activeSegmentIndex == 0) {
          ref.invalidate(transactionSummaryProvider);
          await ref.read(transactionHistoryProvider.notifier).refresh();
        } else {
          await ref.read(analyticsProvider.notifier).fetchAnalytics();
        }
      },
      color: Warna.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Banner Smart Analytics (AI) - disembunyikan sementara sesuai preferensi pengguna
          /*
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildSmartAnalyticsButton(context, ref, theme),
            ),
          ),
          */

          // Segment Switcher: Riwayat Transaksi vs Tren & Produk Terlaris
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildSegmentSwitcher(isIndonesian),
            ),
          ),

          // KONTEN TAB 1: RIWAYAT TRANSAKSI
          if (_activeSegmentIndex == 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateChip(l10n.all, 'Semua'),
                          _buildDateChip(l10n.today, 'Hari Ini'),
                          _buildDateChip(l10n.yesterday, 'Kemarin'),
                          _buildDateChip(
                            _dateFilter == 'Custom' && _customDate != null
                                ? DateFormat('dd MMM').format(_customDate!)
                                : l10n.selectDate,
                            'Custom',
                            isCalendar: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCards(currencyFormat),
                    const Center(
                      child: BannerAdWidget(padding: EdgeInsets.only(top: 16)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(child: _buildFilters(theme)),
            ),
            historyAsync.when(
              data: (state) {
                final transactions = [...state.transactions];

                // Apply Sort
                transactions.sort((a, b) {
                  final dateA = DateTime.parse(a['created_at']).toLocal();
                  final dateB = DateTime.parse(b['created_at']).toLocal();
                  return _sortOrder == 'desc'
                      ? dateB.compareTo(dateA)
                      : dateA.compareTo(dateB);
                });

                // Filter tanggal & status sudah dilakukan di server (provider);
                // di sini hanya pencarian teks atas halaman yang sudah dimuat.
                final filtered = transactions.where((tx) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return tx['id'].toString().toLowerCase().contains(q) ||
                      tx['payment_method'].toString().toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty && !state.isLoadingMore) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(theme),
                  );
                }

                // Group by date
                final Map<String, List<Map<String, dynamic>>> grouped = {};
                for (var tx in filtered) {
                  final dateStr = dateFullFormat.format(
                    DateTime.parse(tx['created_at']).toLocal(),
                  );
                  grouped.putIfAbsent(dateStr, () => []).add(tx);
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == grouped.length) {
                      return state.isLoadingMore
                          ? _buildLoadingIndicator()
                          : const SizedBox(height: 110); // Jarak aman agar item paling bawah tidak tertutup floating bottom bar
                    }

                    final date = grouped.keys.elementAt(index);
                    final dailyTransactions = grouped[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.muted.withOpacity(0.3),
                          ),
                          child: Text(
                            date == dateFullFormat.format(DateTime.now())
                                ? l10n.today.toUpperCase()
                                : date.toUpperCase(),
                            style: theme.textTheme.small.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.mutedForeground,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        ...dailyTransactions.map(
                          (tx) => _buildTransactionCard(
                            tx,
                            currencyFormat,
                            dateFormat,
                            theme,
                          ),
                        ),
                      ],
                    );
                  }, childCount: grouped.length + 1),
                );
              },
              loading: () => _buildSkeleton(theme),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    l10n.failedToLoad(err.toString()),
                    style: theme.textTheme.muted,
                  ),
                ),
              ),
            ),
          ] else ...[
            // KONTEN TAB 2: TREN GRAFIK & PRODUK TERLARIS (ANALYTICS)
            SliverToBoxAdapter(
              child: _buildAnalyticsTabView(
                context,
                theme,
                currencyFormat,
                l10n,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentSwitcher(bool isIndonesian) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeSegmentIndex != 0) {
                  setState(() => _activeSegmentIndex = 0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSegmentIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeSegmentIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      TablerIcons.receipt,
                      size: 16,
                      color: _activeSegmentIndex == 0 ? Warna.primary : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isIndonesian ? 'Daftar Transaksi' : 'Transactions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _activeSegmentIndex == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _activeSegmentIndex == 0 ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeSegmentIndex != 1) {
                  setState(() => _activeSegmentIndex = 1);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSegmentIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeSegmentIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      TablerIcons.chart_dots,
                      size: 16,
                      color: _activeSegmentIndex == 1 ? Warna.primary : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isIndonesian ? 'Tren & Terlaris' : 'Trends & Top Items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _activeSegmentIndex == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _activeSegmentIndex == 1 ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTabView(
    BuildContext context,
    ShadThemeData theme,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final productsAsync = ref.watch(productNotifierProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsTimeFilter(context, ref, theme),
          const SizedBox(height: 16),
          analyticsAsync.when(
            data: (state) {
              String trendLabel = l10n.salesTrendToday;
              switch (state.timeRange) {
                case AnalyticsTimeRange.today:
                  trendLabel = l10n.salesTrendToday;
                  break;
                case AnalyticsTimeRange.week:
                  trendLabel = l10n.salesTrend7Days;
                  break;
                case AnalyticsTimeRange.month:
                  trendLabel = l10n.salesTrendThisMonth;
                  break;
                case AnalyticsTimeRange.lifetime:
                  trendLabel = l10n.salesTrendAllTime;
                  break;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSalesChartCard(
                    context,
                    state,
                    currencyFormat,
                    theme,
                    trendLabel,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: BannerAdWidget(padding: EdgeInsets.symmetric(vertical: 4)),
                  ),
                  const SizedBox(height: 16),
                  _buildTopProductsCard(
                    context,
                    state,
                    currencyFormat,
                    theme,
                    productsAsync,
                  ),
                  const SizedBox(height: 100), // Spasi aman agar tidak tertutup floating bottom bar
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
            },
            loading: () => _buildAnalyticsSkeleton(theme),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(l10n.failedToLoad(err.toString())),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTimeFilter(
    BuildContext context,
    WidgetRef ref,
    ShadThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
          _buildAnalyticsFilterChip(
            ref,
            l10n.today,
            AnalyticsTimeRange.today,
            currentRange == AnalyticsTimeRange.today,
          ),
          _buildAnalyticsFilterChip(
            ref,
            l10n.thisWeek,
            AnalyticsTimeRange.week,
            currentRange == AnalyticsTimeRange.week,
          ),
          _buildAnalyticsFilterChip(
            ref,
            l10n.thisMonth,
            AnalyticsTimeRange.month,
            currentRange == AnalyticsTimeRange.month,
          ),
          _buildAnalyticsFilterChip(
            ref,
            l10n.allTime,
            AnalyticsTimeRange.lifetime,
            currentRange == AnalyticsTimeRange.lifetime,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsFilterChip(
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

  Widget _buildAnalyticsSkeleton(ShadThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.muted.withOpacity(0.5),
      highlightColor: theme.colorScheme.muted.withOpacity(0.2),
      child: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
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

  Widget _buildSalesChartCard(
    BuildContext context,
    AnalyticsState state,
    NumberFormat format,
    ShadThemeData theme,
    String trendLabel,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (state.dailySales.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Center(child: Text(l10n.noSalesData)),
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
                        l10n.salesTrend,
                        style: theme.textTheme.h4.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trendLabel
                            .replaceAll('TREN PENJUALAN (', '')
                            .replaceAll('SALES TREND (', '')
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
    BuildContext context,
    AnalyticsState state,
    NumberFormat format,
    ShadThemeData theme,
    AsyncValue<List<dynamic>> productsAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (state.topProducts.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Center(child: Text(l10n.noTopProductsData)),
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
                      l10n.topProducts,
                      style: theme.textTheme.h4.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.highestSalesVolume,
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
                context,
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
    BuildContext context,
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      maxHeightDiskCache: 100,
                      maxWidthDiskCache: 100,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: theme.colorScheme.muted.withOpacity(0.5),
                        highlightColor: theme.colorScheme.muted.withOpacity(0.2),
                        child: Container(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        TablerIcons.package_off,
                        color: theme.colorScheme.mutedForeground.withOpacity(0.4),
                        size: 18,
                      ),
                    )
                  : (localImagePath != null
                      ? Image.file(
                          File(localImagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Icon(
                          TablerIcons.package,
                          color: theme.colorScheme.mutedForeground.withOpacity(0.4),
                          size: 18,
                        )),
            ),
          ),
          const SizedBox(width: 12),
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
                AppLocalizations.of(context)!.sold,
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

  // Note: Tombol Smart Analytics disimpan untuk penggunaan masa depan
  /*
  Widget _buildSmartAnalyticsButton(
    BuildContext context,
    WidgetRef ref,
    ShadThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isLocked = !ref.watch(
      canAccessFeatureProvider(AppFeature.smartAnalytics),
    );

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(18.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isLocked) {
                showFeatureLockedDialog(context, AppFeature.smartAnalytics);
                return;
              }
              context.push('/smart-analytics');
            },
            borderRadius: BorderRadius.circular(18.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
                    child: Icon(
                      isLocked ? TablerIcons.lock : TablerIcons.sparkles,
                      color: Colors.white,
                      size: 22,
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
                              l10n.smartAnalytics,
                              style: theme.textTheme.h4.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(TablerIcons.lock, size: 9, color: Colors.amber),
                                    SizedBox(width: 2),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          l10n.smartAnalyticsDesc,
                          style: theme.textTheme.muted.copyWith(
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isLocked ? TablerIcons.lock : TablerIcons.chevron_right,
                    color: isLocked ? Colors.amber : theme.colorScheme.mutedForeground,
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
  */

  Widget _buildEmptyState(ShadThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.receipt_off,
            size: 48,
            color: theme.colorScheme.mutedForeground.withOpacity(0.5),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTransactions,
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Warna.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(ShadThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: theme.colorScheme.muted.withOpacity(0.5),
            highlightColor: theme.colorScheme.muted.withOpacity(0.2),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        childCount: 8,
      ),
    );
  }

  Widget _buildSummaryCards(NumberFormat format) {
    // Omzet & jumlah transaksi diagregasi di server (RPC), bukan dari list
    // paginasi — akurat untuk seluruh data tanpa mengunduh semua baris.
    final selectedDate = _selectedDate;
    final summaryAsync = ref.watch(
      transactionSummaryProvider(
        date: selectedDate == null
            ? null
            : DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
      ),
    );

    return summaryAsync.when(
      data: (summary) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.revenue,
                format.format(summary.totalRevenue),
                Warna.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context)!.transaction,
                NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toString(),
                ).format(summary.transactionCount),
                Colors.blue,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(child: _buildStatSkeleton()),
          const SizedBox(width: 12),
          Expanded(child: _buildStatSkeleton()),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final theme = ShadTheme.of(context);
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            height: 4,
            width: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ShadThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: _searchController,
                  placeholder: Text(l10n.searchTransaction),
                  leading: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      TablerIcons.search,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                  onChanged: (val) =>
                      _debouncer.run(() => setState(() => _searchQuery = val)),
                  decoration: ShadDecoration(
                    border: ShadBorder.all(
                      color: theme.colorScheme.border.withOpacity(0.5),
                      width: 1,
                    ),
                    color: theme.colorScheme.muted.withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.border.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    _sortOrder == 'desc'
                        ? TablerIcons.sort_descending
                        : TablerIcons.sort_ascending,
                    size: 20,
                    color: Warna.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  [
                    {'label': l10n.all, 'value': 'Semua'},
                    {'label': l10n.success, 'value': 'Berhasil'},
                    {'label': l10n.pending, 'value': 'Pending'},
                    {'label': l10n.cancelled, 'value': 'Batal'},
                  ].map((status) {
                    final isSelected = _filterStatus == status['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _filterStatus = status['value']!);
                          _applyFilters();
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Warna.primary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Warna.primary
                                  : theme.colorScheme.border,
                            ),
                          ),
                          child: Text(
                            status['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : theme.colorScheme.mutedForeground,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, String value, {bool isCalendar = false}) {
    final isSelected = _dateFilter == value;
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () async {
          if (isCalendar) {
            final picked = await showDatePicker(
              context: context,
              initialDate: _customDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Warna.primary,
                      onPrimary: Colors.black,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _dateFilter = 'Custom';
                _customDate = picked;
              });
              _applyFilters();
            }
          } else {
            setState(() {
              _dateFilter = value;
              if (value != 'Custom') _customDate = null;
            });
            _applyFilters();
          }
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.black : theme.colorScheme.border,
            ),
          ),
          child: Row(
            children: [
              if (isCalendar) ...[
                Icon(
                  TablerIcons.calendar,
                  size: 14,
                  color: isSelected
                      ? Warna.primary
                      : theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.mutedForeground,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> tx,
    NumberFormat format,
    DateFormat timeFormat,
    ShadThemeData theme,
  ) {
    final cardL10n = AppLocalizations.of(context)!;
    final status = tx['status'] ?? 'Berhasil';
    final paymentMethodRaw = tx['payment_method'] ?? 'Tunai';
    final paymentMethod = paymentMethodRaw == 'Tunai'
        ? cardL10n.cash
        : paymentMethodRaw;
    final items = tx['transaction_items'] as List? ?? [];

    final displayStatus = status == 'Berhasil'
        ? cardL10n.success
        : (status == 'Pending' ? cardL10n.pending : cardL10n.cancelled);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(
              '/receipt',
              extra: {'transaction': tx, 'items': items},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.border.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${tx['id'].toString().substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${timeFormat.format(DateTime.parse(tx['created_at']).toLocal())} \u2022 $paymentMethod',
                        style: theme.textTheme.muted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(tx['total_amount']),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayStatus.toUpperCase(),
                      style: TextStyle(
                        color: status == 'Berhasil'
                            ? Warna.primary.withOpacity(0.8)
                            : (status == 'Pending'
                                  ? Colors.orange
                                  : Colors.red),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 130;

  @override
  double get minExtent => 130;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return true;
  }
}
