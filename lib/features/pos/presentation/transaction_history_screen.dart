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

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
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
    if (_scrollController.position.pixels >=
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
    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('HH:mm');
    final dateFullFormat = DateFormat('dd MMM yyyy');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionSummaryProvider);
        await ref.read(transactionHistoryProvider.notifier).refresh();
      },
      color: Warna.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
                    const SizedBox(height: 20),
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
                          : const SizedBox(height: 85);
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
      error: (_, __) => const SizedBox.shrink(),
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
          // FittedBox: nilai besar (mis. Rp 471.200.494) diskalakan agar
          // selalu muat satu baris sehingga kedua kartu tetap sejajar.
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
