import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/models/stock_history.dart';
import 'package:pos_mobile/features/product/providers/stock_history_provider.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum DateRangeFilter {
  all,
  today,
  yesterday,
  last7Days,
  last30Days,
  custom,
}

enum HistorySortOption {
  dateDesc, // Terbaru
  dateAsc,  // Terlama
  quantityDesc, // Perubahan Terbesar
}

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'sale', 'in', 'out'
  DateRangeFilter _dateFilter = DateRangeFilter.all;
  DateTimeRange? _customDateRange;
  HistorySortOption _sortOption = HistorySortOption.dateDesc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet(bool isId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isId ? 'Urutkan Riwayat' : 'Sort History',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _sortTile(
                  title: isId ? 'Waktu Terbaru (Terbaru di atas)' : 'Newest First',
                  subtitle: isId ? 'Urutkan dari mutasi paling akhir' : 'Most recent entries first',
                  selected: _sortOption == HistorySortOption.dateDesc,
                  onTap: () {
                    setState(() => _sortOption = HistorySortOption.dateDesc);
                    Navigator.pop(context);
                  },
                ),
                _sortTile(
                  title: isId ? 'Waktu Terlama (Kronologis)' : 'Oldest First',
                  subtitle: isId ? 'Urutkan dari mutasi awal' : 'Earliest entries first',
                  selected: _sortOption == HistorySortOption.dateAsc,
                  onTap: () {
                    setState(() => _sortOption = HistorySortOption.dateAsc);
                    Navigator.pop(context);
                  },
                ),
                _sortTile(
                  title: isId ? 'Jumlah Mutasi Terbesar' : 'Largest Quantity Change',
                  subtitle: isId ? 'Perubahan unit terbanyak' : 'Highest unit modifications',
                  selected: _sortOption == HistorySortOption.quantityDesc,
                  onTap: () {
                    setState(() => _sortOption = HistorySortOption.quantityDesc);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(TablerIcons.check, size: 18, color: Color(0xFF0F172A)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Warna.primary,
              onPrimary: Warna.black,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = DateRangeFilter.custom;
        _customDateRange = picked;
      });
    }
  }

  String _getDateFilterLabel(bool isId) {
    switch (_dateFilter) {
      case DateRangeFilter.all:
        return isId ? 'Semua Waktu' : 'All Time';
      case DateRangeFilter.today:
        return isId ? 'Hari Ini' : 'Today';
      case DateRangeFilter.yesterday:
        return isId ? 'Kemarin' : 'Yesterday';
      case DateRangeFilter.last7Days:
        return isId ? '7 Hari Terakhir' : 'Last 7 Days';
      case DateRangeFilter.last30Days:
        return isId ? '30 Hari Terakhir' : 'Last 30 Days';
      case DateRangeFilter.custom:
        if (_customDateRange != null) {
          final fmt = DateFormat('dd/MM');
          return '${fmt.format(_customDateRange!.start)} - ${fmt.format(_customDateRange!.end)}';
        }
        return isId ? 'Kustom' : 'Custom';
    }
  }

  bool _matchesDateFilter(DateTime createdAt) {
    if (_dateFilter == DateRangeFilter.all) return true;

    final now = DateTime.now();
    final itemDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);

    switch (_dateFilter) {
      case DateRangeFilter.today:
        return itemDate == today;
      case DateRangeFilter.yesterday:
        return itemDate == today.subtract(const Duration(days: 1));
      case DateRangeFilter.last7Days:
        return itemDate.isAfter(today.subtract(const Duration(days: 7)));
      case DateRangeFilter.last30Days:
        return itemDate.isAfter(today.subtract(const Duration(days: 30)));
      case DateRangeFilter.custom:
        if (_customDateRange == null) return true;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            createdAt.isBefore(end.add(const Duration(seconds: 1)));
      case DateRangeFilter.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(stockHistoryProvider);
    final theme = ShadTheme.of(context);
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isId ? 'Riwayat Stok' : 'Stock History',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isId
                  ? 'Audit mutasi & aktivitas stok produk'
                  : 'Audit stock movements & activities',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.chevron_left, size: 19, color: Color(0xFF334155)),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/stock');
            }
          },
        ),
        actions: [
          // Sort button in app bar for clean access
          IconButton(
            tooltip: isId ? 'Urutkan' : 'Sort',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _sortOption != HistorySortOption.dateDesc
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                TablerIcons.arrows_sort,
                size: 19,
                color: _sortOption != HistorySortOption.dateDesc
                    ? Colors.white
                    : const Color(0xFF334155),
              ),
            ),
            onPressed: () => _showSortBottomSheet(isId),
          ),
          const SizedBox(width: 8),
        ],
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: historyAsync.when(
          data: (allLogs) {
            // Count metrics for summary pills (global before filter)
            final totalCount = allLogs.length;
            final salesCount = allLogs.where((l) => l.changeType == 'sale').length;
            final inCount = allLogs.where((l) => l.quantityChange > 0).length;
            final outCount = allLogs.where((l) => l.quantityChange < 0 && l.changeType != 'sale').length;

            // 1. Filter logs
            final filteredLogs = allLogs.where((log) {
              final query = _searchQuery.toLowerCase().trim();
              final matchesSearch = query.isEmpty ||
                  log.productName.toLowerCase().contains(query);

              bool matchesType = true;
              if (_filterType == 'sale') {
                matchesType = log.changeType == 'sale';
              } else if (_filterType == 'in') {
                matchesType = log.quantityChange > 0;
              } else if (_filterType == 'out') {
                matchesType = log.quantityChange < 0 && log.changeType != 'sale';
              }

              final matchesDate = _matchesDateFilter(log.createdAt);

              return matchesSearch && matchesType && matchesDate;
            }).toList();

            // 2. Sort logs
            filteredLogs.sort((a, b) {
              switch (_sortOption) {
                case HistorySortOption.dateDesc:
                  return b.createdAt.compareTo(a.createdAt);
                case HistorySortOption.dateAsc:
                  return a.createdAt.compareTo(b.createdAt);
                case HistorySortOption.quantityDesc:
                  return b.quantityChange.abs().compareTo(a.quantityChange.abs());
              }
            });

            // 3. Group logs by date string if sorted by date
            final isGrouped = _sortOption == HistorySortOption.dateDesc ||
                _sortOption == HistorySortOption.dateAsc;
            final groupedLogs = isGrouped ? _groupLogsByDate(filteredLogs) : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Minimal Search Box with Integrated Date Range Trigger (Pinned)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: isId ? 'Cari riwayat produk...' : 'Search product...',
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                TablerIcons.search,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 40,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: const Icon(
                                        TablerIcons.x,
                                        size: 15,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  : null,
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 40,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Quick Date Filter Menu
                      _buildDateFilterDropdown(isId),
                    ],
                  ),
                ),

                // 2. Filter Status Pills (Horizontal Scrollable - Pinned)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill(
                          label: isId ? 'Semua' : 'All',
                          count: totalCount,
                          isSelected: _filterType == 'all',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _filterType = 'all');
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterPill(
                          label: isId ? 'Penjualan' : 'Sales',
                          count: salesCount,
                          isSelected: _filterType == 'sale',
                          badgeColor: const Color(0xFFEA580C),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _filterType = 'sale');
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterPill(
                          label: isId ? 'Stok Masuk' : 'Stock In',
                          count: inCount,
                          isSelected: _filterType == 'in',
                          badgeColor: const Color(0xFF16A34A),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _filterType = 'in');
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterPill(
                          label: isId ? 'Stok Keluar' : 'Stock Out',
                          count: outCount,
                          isSelected: _filterType == 'out',
                          badgeColor: const Color(0xFFE11D48),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _filterType = 'out');
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Active Filter Summary Indicator (shows when date or non-default sort is active - Pinned)
                if (_dateFilter != DateRangeFilter.all ||
                    _sortOption != HistorySortOption.dateDesc)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          isId
                              ? 'Menampilkan ${filteredLogs.length} hasil'
                              : 'Showing ${filteredLogs.length} results',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _dateFilter = DateRangeFilter.all;
                              _customDateRange = null;
                              _sortOption = HistorySortOption.dateDesc;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(TablerIcons.x, size: 13, color: Color(0xFFE11D48)),
                              const SizedBox(width: 2),
                              Text(
                                isId ? 'Hapus Filter Tanggal' : 'Clear Date Filter',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFE11D48),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3. Content List or Empty State (Only this part scrolls)
                Expanded(
                  child: RefreshIndicator(
                    color: Warna.primary,
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      await ref.read(stockHistoryProvider.notifier).syncStockHistory();
                    },
                    child: filteredLogs.isEmpty
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            child: SizedBox(
                              height: 350,
                              child: _buildEmptyState(isId, theme),
                            ),
                          )
                        : isGrouped && groupedLogs != null
                            ? ListView.builder(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: groupedLogs.keys.length,
                                itemBuilder: (context, index) {
                                  final groupKey = groupedLogs.keys.elementAt(index);
                                  final logsInGroup = groupedLogs[groupKey]!;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Minimal Date Header
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: index == 0 ? 2 : 12,
                                          bottom: 6,
                                          left: 2,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              groupKey,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF64748B),
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '(${logsInGroup.length})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Cards in this date group
                                      ...logsInGroup.map((log) => _buildHistoryCard(log, isId, theme)),
                                    ],
                                  );
                                },
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: filteredLogs.length,
                                itemBuilder: (context, index) {
                                  final log = filteredLogs[index];
                                  return _buildHistoryCard(log, isId, theme);
                                },
                              ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Warna.primary, strokeWidth: 2.5),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(TablerIcons.alert_circle, size: 40, color: Color(0xFFE11D48)),
                  const SizedBox(height: 12),
                  Text(
                    isId ? 'Gagal memuat riwayat stok' : 'Failed to load stock history',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    err.toString(),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Warna.primary,
                      foregroundColor: Warna.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => ref.invalidate(stockHistoryProvider),
                    icon: const Icon(TablerIcons.refresh, size: 16),
                    label: Text(isId ? 'Coba Lagi' : 'Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterDropdown(bool isId) {
    final isFiltered = _dateFilter != DateRangeFilter.all;

    return PopupMenuButton<DateRangeFilter>(
      tooltip: isId ? 'Filter Tanggal' : 'Filter Date',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      onSelected: (DateRangeFilter value) {
        if (value == DateRangeFilter.custom) {
          _pickCustomDateRange();
        } else {
          setState(() {
            _dateFilter = value;
            _customDateRange = null;
          });
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(DateRangeFilter.all, isId ? 'Semua Waktu' : 'All Time'),
        _buildPopupItem(DateRangeFilter.today, isId ? 'Hari Ini' : 'Today'),
        _buildPopupItem(DateRangeFilter.yesterday, isId ? 'Kemarin' : 'Yesterday'),
        _buildPopupItem(DateRangeFilter.last7Days, isId ? '7 Hari Terakhir' : 'Last 7 Days'),
        _buildPopupItem(DateRangeFilter.last30Days, isId ? '30 Hari Terakhir' : 'Last 30 Days'),
        const PopupMenuDivider(),
        _buildPopupItem(
          DateRangeFilter.custom,
          _dateFilter == DateRangeFilter.custom && _customDateRange != null
              ? _getDateFilterLabel(isId)
              : (isId ? 'Pilih Rentang Tanggal...' : 'Custom Date Range...'),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isFiltered ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFiltered ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.calendar,
              size: 15,
              color: isFiltered ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              _getDateFilterLabel(isId),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w500,
                color: isFiltered ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              TablerIcons.chevron_down,
              size: 13,
              color: isFiltered ? Colors.white70 : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<DateRangeFilter> _buildPopupItem(DateRangeFilter value, String label) {
    final isSelected = _dateFilter == value;
    return PopupMenuItem<DateRangeFilter>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
              ),
            ),
          ),
          if (isSelected)
            const Icon(TablerIcons.check, size: 16, color: Color(0xFF0F172A)),
        ],
      ),
    );
  }

  Map<String, List<StockHistoryLocal>> _groupLogsByDate(List<StockHistoryLocal> logs) {
    final Map<String, List<StockHistoryLocal>> map = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final isId = Localizations.localeOf(context).languageCode == 'id';

    final fullDateFormatter = DateFormat('EEEE, d MMM yyyy', isId ? 'id_ID' : 'en_US');

    for (var log in logs) {
      final date = DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day);
      String label;
      if (date == today) {
        label = isId ? 'Hari Ini' : 'Today';
      } else if (date == yesterday) {
        label = isId ? 'Kemarin' : 'Yesterday';
      } else {
        label = fullDateFormatter.format(date);
      }

      if (!map.containsKey(label)) {
        map[label] = [];
      }
      map[label]!.add(log);
    }

    return map;
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (badgeColor?.withValues(alpha: 0.12) ?? const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (badgeColor ?? const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(StockHistoryLocal log, bool isId, ShadThemeData theme) {
    final timeFormat = DateFormat('HH:mm');
    final isPositive = log.quantityChange > 0;

    const emeraldGreen = Color(0xFF16A34A);
    const lightEmerald = Color(0xFFF0FDF4);
    const borderEmerald = Color(0xFFBBF7D0);

    const roseRed = Color(0xFFE11D48);
    const lightRose = Color(0xFFFFF1F2);
    const borderRose = Color(0xFFFECDD3);

    const orangeColor = Color(0xFFEA580C);
    const lightOrange = Color(0xFFFFF7ED);
    const borderOrange = Color(0xFFFFEDD5);

    String changeTitle;
    IconData typeIcon;
    Color iconColor;
    Color pillBg;
    Color pillBorder;

    if (log.changeType == 'sale') {
      changeTitle = isId ? 'Penjualan' : 'Sale';
      typeIcon = TablerIcons.shopping_bag;
      iconColor = orangeColor;
      pillBg = lightOrange;
      pillBorder = borderOrange;
    } else if (log.changeType == 'manual_addition' || isPositive) {
      changeTitle = isId ? 'Tambah Stok' : 'Stock In';
      typeIcon = TablerIcons.arrow_up_right;
      iconColor = emeraldGreen;
      pillBg = lightEmerald;
      pillBorder = borderEmerald;
    } else {
      changeTitle = isId ? 'Kurang Stok' : 'Stock Out';
      typeIcon = TablerIcons.arrow_down_right;
      iconColor = roseRed;
      pillBg = lightRose;
      pillBorder = borderRose;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Product name & Quantity Change Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Change type icon avatar
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: pillBorder),
                ),
                child: Icon(typeIcon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 9),

              // Product Name and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          changeTitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('•', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                        const SizedBox(width: 5),
                        Text(
                          timeFormat.format(log.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('•', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                        const SizedBox(width: 5),
                        Text(
                          log.cashierId != null
                              ? (isId ? 'Kasir' : 'Cashier')
                              : (isId ? 'Sistem' : 'System'),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right side: delta quantity and transition
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isPositive ? lightEmerald : lightRose,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPositive ? borderEmerald : borderRose,
                      ),
                    ),
                    child: Text(
                      isPositive ? '+${log.quantityChange}' : '${log.quantityChange}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isPositive ? emeraldGreen : roseRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${log.oldStock} → ${log.newStock} pcs',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isId, ShadThemeData theme) {
    final isFiltered = _searchQuery.isNotEmpty ||
        _filterType != 'all' ||
        _dateFilter != DateRangeFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? TablerIcons.filter_off : TablerIcons.history,
                size: 34,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isFiltered
                  ? (isId ? 'Tidak ada riwayat yang cocok' : 'No matching records')
                  : (isId ? 'Belum Ada Riwayat' : 'No Stock History'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isFiltered
                  ? (isId
                      ? 'Coba ubah kata kunci atau rentang tanggal.'
                      : 'Try adjusting filters or date range.')
                  : (isId
                      ? 'Aktivitas mutasi stok akan tercatat di sini.'
                      : 'Stock adjustments will appear here.'),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterType = 'all';
                    _dateFilter = DateRangeFilter.all;
                    _customDateRange = null;
                    _sortOption = HistorySortOption.dateDesc;
                  });
                },
                child: Text(
                  isId ? 'Reset Semua Filter' : 'Reset All Filters',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
