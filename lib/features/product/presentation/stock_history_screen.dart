import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/models/stock_history.dart';
import 'package:pos_mobile/features/product/providers/stock_history_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'sale', 'manual'

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
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isId ? 'Riwayat Stok' : 'Stock History',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              isId 
                  ? 'Audit penyesuaian stok dan penjualan' 
                  : 'Audit stock adjustments and sales',
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.chevron_left, size: 20),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/stock');
            }
          },
        ),
        toolbarHeight: 80,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH & FILTER SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  ShadInput(
                    controller: _searchController,
                    placeholder: Text(isId ? 'Cari nama produk...' : 'Search product name...'),
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(TablerIcons.search, size: 18, color: Colors.grey),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(isId, theme),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // MAIN LIST
            Expanded(
              child: historyAsync.when(
                data: (logs) {
                  // Filter logs locally based on search query and category type
                  // Hoist invariant string conversion outside of the loop for performance
                  final lowerQuery = _searchQuery.toLowerCase();
                  final filteredLogs = logs.where((log) {
                    final matchesSearch = log.productName
                        .toLowerCase()
                        .contains(lowerQuery);
                        
                    final matchesType = _filterType == 'all' ||
                        (_filterType == 'sale' && log.changeType == 'sale') ||
                        (_filterType == 'manual' && log.changeType != 'sale');

                    return matchesSearch && matchesType;
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return _buildEmptyState(isId, theme);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      await ref
                          .read(stockHistoryProvider.notifier)
                          .syncStockHistory();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return _buildHistoryCard(log, isId, theme);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Warna.primary),
                ),
                error: (err, _) => Center(
                  child: Text(
                    isId ? 'Gagal memuat riwayat: $err' : 'Failed to load history: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isId, ShadThemeData theme) {
    final List<Map<String, String>> filters = [
      {'key': 'all', 'label': isId ? 'Semua' : 'All'},
      {'key': 'sale', 'label': isId ? 'Penjualan' : 'Sales'},
      {'key': 'manual', 'label': isId ? 'Penyesuaian Manual' : 'Manual Adjustments'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterType == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _filterType = f['key']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Warna.primary 
                      : theme.colorScheme.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Warna.primary : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Warna.black : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(StockHistoryLocal log, bool isId, ShadThemeData theme) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isPositive = log.quantityChange > 0;
    
    // Determine title / reason display
    String changeTitle = '';
    IconData icon = TablerIcons.adjustments;
    Color iconColor = Colors.grey;
    Color badgeColor = Colors.grey.shade100;
    Color textColor = Colors.black87;

    // Use compile-safe color constants
    const Color emeraldGreen = Color(0xFF10B981);
    const Color lightEmerald = Color(0xFFECFDF5);
    const Color roseRed = Color(0xFFF43F5E);
    const Color lightRose = Color(0xFFFFF1F2);
    const Color orangeColor = Color(0xFFF97316);
    const Color lightOrange = Color(0xFFFFF7ED);

    if (log.changeType == 'sale') {
      changeTitle = isId ? 'Penjualan' : 'Sale';
      icon = TablerIcons.shopping_bag;
      iconColor = orangeColor;
      badgeColor = lightOrange;
      textColor = orangeColor;
    } else if (log.changeType == 'manual_addition') {
      changeTitle = isId ? 'Tambah Manual' : 'Manual Addition';
      icon = TablerIcons.arrow_up;
      iconColor = emeraldGreen;
      badgeColor = lightEmerald;
      textColor = emeraldGreen;
    } else if (log.changeType == 'manual_reduction') {
      changeTitle = isId ? 'Kurang Manual' : 'Manual Reduction';
      icon = TablerIcons.arrow_down;
      iconColor = roseRed;
      badgeColor = lightRose;
      textColor = roseRed;
    } else {
      changeTitle = isId ? 'Penyesuaian Stok' : 'Stock Adjustment';
      icon = TablerIcons.settings;
      iconColor = Warna.primary;
      badgeColor = Warna.primary.withValues(alpha: 0.15);
      textColor = Warna.black;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER OF CARD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    log.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // QUANTITY ADJUSTMENT BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? lightEmerald : lightRose,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPositive ? '+${log.quantityChange}' : '${log.quantityChange}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isPositive ? emeraldGreen : roseRed,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // INTERMEDIATE DIVIDER OR DETAILS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LOG CATEGORY BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: 4),
                      Text(
                        changeTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // STOCK FLOW
                Text(
                  '${log.oldStock} → ${log.newStock} pcs',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: Colors.black12),
            ),

            // FOOTER INFO: CASHIER, TIME & SYNC STATE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cashier info & timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isId ? "Oleh" : "By"}: ${log.cashierId != null ? "Kasir" : (isId ? "Sistem" : "System")}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(log.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Sync indicator icon
                Tooltip(
                  message: log.isSynced 
                      ? (isId ? "Tersinkronisasi dengan Cloud" : "Synced with Cloud") 
                      : (isId ? "Menunggu Sinkronisasi" : "Pending Sync"),
                  child: Icon(
                    log.isSynced ? TablerIcons.circle_check : TablerIcons.refresh,
                    size: 18,
                    color: log.isSynced ? emeraldGreen : Colors.amber.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isId, ShadThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.history, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            isId ? 'Tidak Ada Riwayat' : 'No History Found',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            isId 
                ? 'Belum ada perubahan stok yang tercatat.' 
                : 'No stock changes have been logged yet.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
