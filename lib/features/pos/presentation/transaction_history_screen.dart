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

  @override
  void dispose() {
    _debouncer.dispose();
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
                    if (index == 0) {
                      final selectedDate = _selectedDate;
                      final summaryCount = ref.watch(
                        transactionSummaryProvider(
                          date: selectedDate == null
                              ? null
                              : DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                ),
                        ),
                      ).value?.transactionCount;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              summaryCount != null
                                  ? '${filtered.length} / $summaryCount data'
                                  : '${filtered.length} data',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Page Size Selector Pill
                                PopupMenuButton<int>(
                                  initialValue: state.pageSize,
                                  onSelected: (int newSize) {
                                    ref
                                        .read(transactionHistoryProvider.notifier)
                                        .setPageSize(newSize);
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  itemBuilder: (ctx) => [
                                    for (final size in [20, 50, 100, 200])
                                      PopupMenuItem<int>(
                                        value: size,
                                        height: 38,
                                        child: Row(
                                          children: [
                                            Text(
                                              '$size / hal',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: state.pageSize == size
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: state.pageSize == size
                                                    ? Warna.primary
                                                    : Colors.black87,
                                              ),
                                            ),
                                            if (state.pageSize == size) ...[
                                              const Spacer(),
                                              const Icon(
                                                TablerIcons.check,
                                                size: 14,
                                                color: Warna.primary,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${state.pageSize}/hal',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          TablerIcons.chevron_down,
                                          size: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Page Picker Pill
                                InkWell(
                                  onTap: state.isLoadingMore
                                      ? null
                                      : () => _showPagePickerDialog(
                                            context,
                                            state,
                                            summaryCount,
                                          ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Warna.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Warna.primary.withOpacity(0.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Hal ${state.page + 1}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Warna.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          TablerIcons.selector,
                                          size: 11,
                                          color: Warna.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    if (index == grouped.length + 1) {
                      final selectedDate = _selectedDate;
                      final summaryCount = ref.watch(
                        transactionSummaryProvider(
                          date: selectedDate == null
                              ? null
                              : DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                ),
                        ),
                      ).value?.transactionCount;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                        child: _buildPaginationBar(
                          state,
                          filtered.length,
                          summaryCount,
                        ),
                      );
                    }

                    final date = grouped.keys.elementAt(index - 1);
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.border.withOpacity(0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${dailyTransactions.length} transaksi',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                ),
                              ),
                            ],
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
                  }, childCount: grouped.length + 2),
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

  Widget _buildPaginationBar(
    TransactionHistoryState state,
    int currentItemCount,
    int? totalCount,
  ) {
    final theme = ShadTheme.of(context);
    final currentPage = state.page + 1;
    final hasPrev = state.page > 0;
    final hasNext = state.hasMore;
    final isLoading = state.isLoadingMore;

    final totalPages = (totalCount != null && totalCount > 0)
        ? (totalCount / state.pageSize).ceil()
        : null;

    final pageText = totalPages != null
        ? 'Hal $currentPage dari $totalPages'
        : 'Hal $currentPage';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // Info Ringkas Data
          Expanded(
            child: Text(
              totalCount != null
                  ? '$currentItemCount / $totalCount'
                  : '$currentItemCount data',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Tombol Prev (Icon Button Minimalis)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (!hasPrev || isLoading)
                  ? null
                  : () {
                      ref
                          .read(transactionHistoryProvider.notifier)
                          .goToPage(state.page - 1);
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (!hasPrev || isLoading) ? 0.3 : 1.0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Icon(TablerIcons.chevron_left, size: 16),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Indikator Halaman (Pill Minimalis - Bisa Diklik untuk Pilih Halaman)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () => _showPagePickerDialog(
                        context,
                        state,
                        totalCount,
                      ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Warna.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Warna.primary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pageText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            TablerIcons.selector,
                            size: 13,
                            color: Colors.black87,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Tombol Next (Icon Button Minimalis)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (!hasNext || isLoading)
                  ? null
                  : () {
                      ref
                          .read(transactionHistoryProvider.notifier)
                          .goToPage(state.page + 1);
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (!hasNext || isLoading) ? 0.3 : 1.0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Warna.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      TablerIcons.chevron_right,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPagePickerDialog(
    BuildContext context,
    TransactionHistoryState state,
    int? totalCount,
  ) {
    final currentPage = state.page + 1;
    final totalPages = (totalCount != null && totalCount > 0)
        ? (totalCount / state.pageSize).ceil()
        : (state.hasMore ? currentPage + 1 : currentPage);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Halaman',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalPages Total Halaman',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: totalPages,
                  itemBuilder: (context, i) {
                    final pageNum = i + 1;
                    final isCurrent = pageNum == currentPage;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          if (!isCurrent) {
                            ref
                                .read(transactionHistoryProvider.notifier)
                                .goToPage(i);
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent ? Warna.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? Warna.primary
                                  : Colors.grey.shade300,
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$pageNum',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isCurrent ? Colors.black : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: bottomInset > 0 ? bottomInset + 8 : 24),
            ],
          ),
        );
      },
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
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final theme = ShadTheme.of(context);
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 9.5,
              letterSpacing: 0.8,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            height: 3,
            width: 20,
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
    final statusList = [
      {'label': l10n.all, 'value': 'Semua'},
      {'label': l10n.success, 'value': 'Berhasil'},
      {'label': l10n.pending, 'value': 'Pending'},
      {'label': l10n.cancelled, 'value': 'Batal'},
    ];

    final currentStatusLabel = statusList.firstWhere(
      (s) => s['value'] == _filterStatus,
      orElse: () => {'label': l10n.all, 'value': 'Semua'},
    )['label']!;

    return Container(
      height: 112.0,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _searchController,
                    placeholder: Text(l10n.searchTransaction),
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        TablerIcons.search,
                        size: 18,
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
                // Dropdown Status Filter (Semua, Berhasil, Pending, Batal)
                SizedBox(
                  height: 42,
                  child: PopupMenuButton<String>(
                    tooltip: 'Filter Status',
                    onSelected: (val) {
                      setState(() => _filterStatus = val);
                      _applyFilters();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.border.withOpacity(0.3),
                      ),
                    ),
                    color: Colors.white,
                    elevation: 4,
                    itemBuilder: (context) => statusList.map((status) {
                      final isSelected = _filterStatus == status['value'];
                      return PopupMenuItem<String>(
                        value: status['value'],
                        child: Row(
                          children: [
                            Text(
                              status['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? Colors.black : Colors.grey[700],
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Icon(TablerIcons.check, size: 16, color: Warna.primary),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _filterStatus != 'Semua'
                            ? Warna.primary.withOpacity(0.15)
                            : theme.colorScheme.muted.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _filterStatus != 'Semua'
                              ? Warna.primary
                              : theme.colorScheme.border.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentStatusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _filterStatus != 'Semua'
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _filterStatus != 'Semua'
                                  ? Colors.black
                                  : theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            TablerIcons.chevron_down,
                            size: 14,
                            color: _filterStatus != 'Semua'
                                ? Colors.black
                                : theme.colorScheme.mutedForeground,
                          ),
                        ],
                      ),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.border.withOpacity(0.5),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _sortOrder == 'desc'
                            ? TablerIcons.sort_descending
                            : TablerIcons.sort_ascending,
                        size: 18,
                        color: Warna.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Filter Tanggal di bawah search bar
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
              '/transaction-detail',
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
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => 112.0;

  @override
  double get minExtent => 112.0;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
