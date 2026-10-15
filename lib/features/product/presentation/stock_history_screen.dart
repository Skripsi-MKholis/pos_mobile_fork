import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/models/stock_history.dart';
import 'package:pos_mobile/features/product/providers/stock_history_provider.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'sale', 'in', 'out'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: historyAsync.when(
          data: (allLogs) {
            // Count metrics for summary pills
            final totalCount = allLogs.length;
            final salesCount = allLogs.where((l) => l.changeType == 'sale').length;
            final inCount = allLogs.where((l) => l.quantityChange > 0).length;
            final outCount = allLogs.where((l) => l.quantityChange < 0 && l.changeType != 'sale').length;

            // Filter logs
            final filteredLogs = allLogs.where((log) {
              final query = _searchQuery.toLowerCase().trim();
              final matchesSearch = query.isEmpty ||
                  log.productName.toLowerCase().contains(query);

              bool matchesFilter = true;
              if (_filterType == 'sale') {
                matchesFilter = log.changeType == 'sale';
              } else if (_filterType == 'in') {
                matchesFilter = log.quantityChange > 0;
              } else if (_filterType == 'out') {
                matchesFilter = log.quantityChange < 0 && log.changeType != 'sale';
              }

              return matchesSearch && matchesFilter;
            }).toList();

            // Group logs by date string
            final groupedLogs = _groupLogsByDate(filteredLogs);

            return RefreshIndicator(
              color: Warna.primary,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await ref.read(stockHistoryProvider.notifier).syncStockHistory();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Search Box
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText: isId ? 'Cari riwayat nama produk...' : 'Search product history...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              TablerIcons.search,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(
                                      TablerIcons.x,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                        ),
                      ),
                    ),
                  ),

                  // 2. Filter Status Pills
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                            const SizedBox(width: 8),
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
                            const SizedBox(width: 8),
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
                            const SizedBox(width: 8),
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
                  ),

                  // 3. Content List or Empty State
                  if (filteredLogs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(isId, theme),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final groupKey = groupedLogs.keys.elementAt(index);
                            final logsInGroup = groupedLogs[groupKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header Section
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: index == 0 ? 4 : 14,
                                    bottom: 8,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        TablerIcons.calendar_time,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        groupKey,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF475569),
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${logsInGroup.length}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475569),
                                          ),
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
                          childCount: groupedLogs.keys.length,
                        ),
                      ),
                    ),
                ],
              ),
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

  Map<String, List<StockHistoryLocal>> _groupLogsByDate(List<StockHistoryLocal> logs) {
    final Map<String, List<StockHistoryLocal>> map = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final isId = Localizations.localeOf(context).languageCode == 'id';

    final fullDateFormatter = DateFormat('EEEE, d MMMM yyyy', isId ? 'id_ID' : 'en_US');

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (badgeColor?.withValues(alpha: 0.12) ?? const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
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

    // Compile-safe color tokens matching minimal palette
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Product name & Quantity Change Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Change type icon avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: pillBorder),
                ),
                child: Icon(typeIcon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),

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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            changeTitle,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeFormat.format(log.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
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

              // Delta pill (+10 / -5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? lightEmerald : lightRose,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPositive ? borderEmerald : borderRose,
                  ),
                ),
                child: Text(
                  isPositive ? '+${log.quantityChange}' : '${log.quantityChange}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? emeraldGreen : roseRed,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Stock flow (old -> new) and User/Cashier metadata
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stock transition: 20 -> 25 pcs
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Stok: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${log.oldStock}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(TablerIcons.arrow_narrow_right, size: 14, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      '${log.newStock} pcs',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),

                // Cashier info & sync dot
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      log.cashierId != null
                          ? (isId ? 'Kasir' : 'Cashier')
                          : (isId ? 'Sistem' : 'System'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: log.isSynced ? emeraldGreen : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isId, ShadThemeData theme) {
    final isFiltered = _searchQuery.isNotEmpty || _filterType != 'all';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? TablerIcons.filter_off : TablerIcons.history,
                size: 38,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isFiltered
                  ? (isId ? 'Tidak ada riwayat yang cocok' : 'No matching records')
                  : (isId ? 'Belum Ada Riwayat' : 'No Stock History'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? (isId
                      ? 'Coba ganti filter atau kata kunci pencarian Anda.'
                      : 'Try adjusting your filters or search query.')
                  : (isId
                      ? 'Aktivitas perubahan stok dan penjualan akan otomatis tercatat di sini.'
                      : 'Stock adjustments and sales will automatically appear here.'),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterType = 'all';
                  });
                },
                child: Text(
                  isId ? 'Reset Filter' : 'Reset Filters',
                  style: const TextStyle(
                    fontSize: 13,
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
