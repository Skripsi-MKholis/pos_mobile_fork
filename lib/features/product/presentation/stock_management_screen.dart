import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/restock_suggestion_card.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

enum StockFilterStatus { all, outOfStock, lowStock, inStock }
enum StockSortOption { nameAsc, nameDesc, stockAsc, stockDesc }

class StockManagementScreen extends ConsumerStatefulWidget {
  const StockManagementScreen({super.key});

  @override
  ConsumerState<StockManagementScreen> createState() =>
      _StockManagementScreenState();
}

class _StockManagementScreenState extends ConsumerState<StockManagementScreen> {
  // Optimization: Debouncer prevents expensive UI rebuilds and local filtering on every keystroke.
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  StockFilterStatus _selectedStatus = StockFilterStatus.all;
  StockSortOption _selectedSort = StockSortOption.stockAsc;

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openStockEditModal(
    BuildContext context,
    Product product, {
    int? initialStock,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockEditSheet(
        product: product,
        initialStock: initialStock,
        onSave: (newStock) => _updateStock(product, newStock),
      ),
    );
  }

  Future<void> _updateStock(Product product, int newStock) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final oldStock = product.stockQuantity;
      await ref
          .read(productNotifierProvider.notifier)
          .updateStock(product.supabaseId, newStock);

      // Log to Firebase Analytics
      try {
        final diff = newStock - oldStock;
        if (diff != 0) {
          final adjustmentType = diff > 0 ? 'tambah' : 'kurang';
          await AnalyticsService.instance.logStockAdjustment(
            productName: product.name,
            adjustmentType: adjustmentType,
            quantity: diff.abs().toDouble(),
          );
        }
      } catch (_) {}

      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.stockUpdated(product.name, newStock),
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.stockUpdateFailed(e.toString()),
          status: ToastStatus.error,
        );
      }
    }
  }

  void _quickStepStock(Product product, int delta) {
    HapticFeedback.lightImpact();
    final newStock = (product.stockQuantity + delta).clamp(0, 999999);
    if (newStock != product.stockQuantity) {
      _updateStock(product, newStock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    final locale = Localizations.localeOf(context);
    final format = NumberFormat.currency(
      locale: locale.toString(),
      symbol: locale.languageCode == 'id' ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.manageStock,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              l10n.monitorAndUpdateStock,
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
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
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: isId ? 'Riwayat Stok' : 'Stock History',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.history, size: 20),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/stock/history');
            },
          ),
          const SizedBox(width: 16),
        ],
        toolbarHeight: 76,
      ),
      body: SafeArea(
        child: productsAsync.when(
          data: (allProducts) {
            // Metrics Calculation
            final totalCount = allProducts.length;
            final outOfStockCount =
                allProducts.where((p) => p.stockQuantity == 0).length;
            final lowStockCount = allProducts
                .where((p) => p.stockQuantity > 0 && p.stockQuantity <= 10)
                .length;
            final inStockCount =
                allProducts.where((p) => p.stockQuantity > 10).length;

            // Filtering
            var filteredProducts = allProducts.where((p) {
              final query = _searchQuery.toLowerCase().trim();
              final matchesSearch = query.isEmpty ||
                  p.name.toLowerCase().contains(query) ||
                  (p.sku?.toLowerCase().contains(query) ?? false);

              final matchesCategory = _selectedCategory == null ||
                  p.categoryId == _selectedCategory;

              bool matchesStatus = true;
              switch (_selectedStatus) {
                case StockFilterStatus.all:
                  matchesStatus = true;
                  break;
                case StockFilterStatus.outOfStock:
                  matchesStatus = p.stockQuantity == 0;
                  break;
                case StockFilterStatus.lowStock:
                  matchesStatus =
                      p.stockQuantity > 0 && p.stockQuantity <= 10;
                  break;
                case StockFilterStatus.inStock:
                  matchesStatus = p.stockQuantity > 10;
                  break;
              }

              return matchesSearch && matchesCategory && matchesStatus;
            }).toList();

            // Sorting
            filteredProducts.sort((a, b) {
              switch (_selectedSort) {
                case StockSortOption.stockAsc:
                  final cmp = a.stockQuantity.compareTo(b.stockQuantity);
                  return cmp != 0 ? cmp : a.name.compareTo(b.name);
                case StockSortOption.stockDesc:
                  final cmp = b.stockQuantity.compareTo(a.stockQuantity);
                  return cmp != 0 ? cmp : a.name.compareTo(b.name);
                case StockSortOption.nameAsc:
                  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                case StockSortOption.nameDesc:
                  return b.name.toLowerCase().compareTo(a.name.toLowerCase());
              }
            });

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(productNotifierProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // 1. Search Bar & Filter Action Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          // Search field
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: l10n.searchNameOrSku,
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
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
                                            color: Colors.grey,
                                          ),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) => _debouncer.run(
                                  () => setState(() => _searchQuery = value),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Sort Button
                          PopupMenuButton<StockSortOption>(
                            tooltip: isId ? 'Urutkan' : 'Sort by',
                            initialValue: _selectedSort,
                            onSelected: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSort = val);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    TablerIcons.arrows_sort,
                                    size: 17,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getSortShortLabel(_selectedSort, isId),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: StockSortOption.stockAsc,
                                child: Text(
                                  isId ? 'Stok Terendah' : 'Lowest Stock',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              PopupMenuItem(
                                value: StockSortOption.stockDesc,
                                child: Text(
                                  isId ? 'Stok Terbanyak' : 'Highest Stock',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              PopupMenuItem(
                                value: StockSortOption.nameAsc,
                                child: Text(
                                  isId ? 'Nama (A-Z)' : 'Name (A-Z)',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Minimalist Horizontal Filter Chips (Category + Status)
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          // Status Filter Pills
                          _buildSimpleChip(
                            label: isId ? 'Semua ($totalCount)' : 'All ($totalCount)',
                            isSelected: _selectedStatus == StockFilterStatus.all,
                            onTap: () => setState(
                              () => _selectedStatus = StockFilterStatus.all,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (outOfStockCount > 0) ...[
                            _buildSimpleChip(
                              label: isId
                                  ? 'Habis ($outOfStockCount)'
                                  : 'Empty ($outOfStockCount)',
                              isSelected:
                                  _selectedStatus == StockFilterStatus.outOfStock,
                              activeColor: const Color(0xFFEF4444),
                              onTap: () => setState(
                                () => _selectedStatus =
                                    _selectedStatus == StockFilterStatus.outOfStock
                                        ? StockFilterStatus.all
                                        : StockFilterStatus.outOfStock,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (lowStockCount > 0) ...[
                            _buildSimpleChip(
                              label: isId
                                  ? 'Menipis ($lowStockCount)'
                                  : 'Low ($lowStockCount)',
                              isSelected:
                                  _selectedStatus == StockFilterStatus.lowStock,
                              activeColor: const Color(0xFFF59E0B),
                              onTap: () => setState(
                                () => _selectedStatus =
                                    _selectedStatus == StockFilterStatus.lowStock
                                        ? StockFilterStatus.all
                                        : StockFilterStatus.lowStock,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          _buildSimpleChip(
                            label: isId
                                ? 'Aman ($inStockCount)'
                                : 'Safe ($inStockCount)',
                            isSelected: _selectedStatus == StockFilterStatus.inStock,
                            activeColor: const Color(0xFF10B981),
                            onTap: () => setState(
                              () => _selectedStatus =
                                  _selectedStatus == StockFilterStatus.inStock
                                      ? StockFilterStatus.all
                                      : StockFilterStatus.inStock,
                            ),
                          ),

                          // Category separator & category chips
                          categoriesAsync.when(
                            data: (categories) {
                              if (categories.isEmpty) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    height: 16,
                                    width: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  ...categories.map((c) {
                                    final isCatSelected =
                                        _selectedCategory == c.supabaseId;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: _buildSimpleChip(
                                        label: c.name,
                                        isSelected: isCatSelected,
                                        onTap: () => setState(() {
                                          _selectedCategory = isCatSelected
                                              ? null
                                              : c.supabaseId;
                                        }),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Smart Restock Suggestion (Minimal & compact)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RestockSuggestionCard(
                        onApply: (product, suggestedStock) => _openStockEditModal(
                          context,
                          product,
                          initialStock: suggestedStock,
                        ),
                      ),
                    ),
                  ),

                  // Status filter notification bar (if filtered)
                  if (_searchQuery.isNotEmpty ||
                      _selectedCategory != null ||
                      _selectedStatus != StockFilterStatus.all)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                        child: Row(
                          children: [
                            Text(
                              isId
                                  ? '${filteredProducts.length} produk ditemukan'
                                  : '${filteredProducts.length} products found',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = null;
                                  _selectedStatus = StockFilterStatus.all;
                                });
                              },
                              child: Text(
                                l10n.resetFilter,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4D7C0F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 4. Clean List of Products or Empty View
                  if (filteredProducts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        context,
                        theme,
                        l10n,
                        hasActiveFilter: _searchQuery.isNotEmpty ||
                            _selectedCategory != null ||
                            _selectedStatus != StockFilterStatus.all,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = filteredProducts[index];
                            return _buildMinimalProductCard(
                              context,
                              product: product,
                              theme: theme,
                              l10n: l10n,
                              format: format,
                              isId: isId,
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(TablerIcons.alert_triangle, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ShadButton.outline(
                    onPressed: () => ref.invalidate(productNotifierProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSortShortLabel(StockSortOption sort, bool isId) {
    switch (sort) {
      case StockSortOption.stockAsc:
        return isId ? 'Stok Terendah' : 'Lowest Stock';
      case StockSortOption.stockDesc:
        return isId ? 'Stok Terbanyak' : 'Highest Stock';
      case StockSortOption.nameAsc:
        return 'A-Z';
      case StockSortOption.nameDesc:
        return 'Z-A';
    }
  }

  Widget _buildSimpleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? const Color(0xFF0F172A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalProductCard(
    BuildContext context, {
    required Product product,
    required ShadThemeData theme,
    required AppLocalizations l10n,
    required NumberFormat format,
    required bool isId,
  }) {
    final isOut = product.stockQuantity == 0;
    final isLow = product.stockQuantity > 0 && product.stockQuantity <= 10;

    final badgeColor = isOut
        ? const Color(0xFFEF4444)
        : (isLow ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
    final badgeBg = isOut
        ? const Color(0xFFFEF2F2)
        : (isLow ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOut
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openStockEditModal(context, product),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Product Thumbnail
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            maxHeightDiskCache: 100,
                            maxWidthDiskCache: 100,
                            placeholder: (context, url) => Container(color: Colors.white),
                            errorWidget: (context, url, error) => const Icon(
                              TablerIcons.package_off,
                              size: 20,
                              color: Colors.grey,
                            ),
                          )
                        : (product.localImagePath != null
                            ? Image.file(
                                File(product.localImagePath!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                TablerIcons.package,
                                size: 20,
                                color: Color(0xFF94A3B8),
                              )),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Price / SKU
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            format.format(product.price),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          if (product.sku != null &&
                              product.sku!.trim().isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.sku!,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Forecast Badge if any
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: StockForecastBadge(
                          productSupabaseId: product.supabaseId,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Minus & Plus Steppers
                Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: product.stockQuantity > 0
                        ? () => _quickStepStock(product, -1)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        TablerIcons.minus,
                        size: 14,
                        color: product.stockQuantity > 0
                            ? const Color(0xFF334155)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Stock Count Pill (Tap to open modal)
                Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    product.stockQuantity.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Quick Plus Stepper
                Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _quickStepStock(product, 1),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        TablerIcons.plus,
                        size: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ShadThemeData theme,
    AppLocalizations l10n, {
    required bool hasActiveFilter,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Warna.primary.withValues(alpha: 0.22),
                    Warna.primary.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Warna.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Warna.primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  hasActiveFilter
                      ? TablerIcons.package_off
                      : TablerIcons.package,
                  size: 42,
                  color: Warna.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasActiveFilter ? l10n.productNotFound : l10n.noProductsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                hasActiveFilter
                    ? l10n.productNotFoundDesc
                    : l10n.noProductsYetDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.muted.copyWith(
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasActiveFilter) ...[
                    ShadButton.outline(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedCategory = null;
                          _selectedStatus = StockFilterStatus.all;
                        });
                      },
                      leading: const Icon(
                        TablerIcons.filter_off,
                        size: 18,
                      ),
                      child: Text(
                        l10n.resetFilter,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  ShadButton(
                    backgroundColor: Warna.primary,
                    foregroundColor: Colors.black,
                    onPressed: () => context.push('/products/add'),
                    leading: const Icon(
                      TablerIcons.plus,
                      size: 18,
                      color: Colors.black,
                    ),
                    child: Text(
                      l10n.addProduct,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockEditSheet extends StatefulWidget {
  final Product product;
  final Function(int) onSave;

  /// Nilai awal kolom stok. Dipakai saran belanja berbasis prediksi agar
  /// pengguna tinggal mengonfirmasi; stok tidak pernah berubah otomatis.
  final int? initialStock;

  const _StockEditSheet({
    required this.product,
    required this.onSave,
    this.initialStock,
  });

  @override
  State<_StockEditSheet> createState() => _StockEditSheetState();
}

class _StockEditSheetState extends State<_StockEditSheet> {
  late TextEditingController _controller;
  late int _currentStock;

  @override
  void initState() {
    super.initState();
    _currentStock = widget.initialStock ?? widget.product.stockQuantity;
    _controller = TextEditingController(text: _currentStock.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateLocalStock(int newValue) {
    if (newValue < 0) newValue = 0; // Stock cannot be negative
    setState(() {
      _currentStock = newValue;
      _controller.text = _currentStock.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final locale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: locale.startsWith('id') ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    final diff = _currentStock - widget.product.stockQuantity;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isId ? 'Kelola Stok Produk' : 'Adjust Product Stock',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(TablerIcons.x, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product details Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.border.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            maxHeightDiskCache: 120,
                            maxWidthDiskCache: 120,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade200,
                              highlightColor: Colors.grey.shade50,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                TablerIcons.package_off,
                                color: Colors.grey,
                                size: 22,
                              ),
                            ),
                          )
                        : (widget.product.localImagePath != null
                            ? Image.file(
                                File(widget.product.localImagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : const Icon(
                                TablerIcons.package,
                                color: Color(0xFF94A3B8),
                                size: 22,
                              )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currencyFormat.format(widget.product.price),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Current stock badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isId ? 'Stok Lama' : 'Previous',
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.product.stockQuantity.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stock Counter Controls & Live Delta Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus 1
              Material(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _updateLocalStock(_currentStock - 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(TablerIcons.minus, size: 22, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Stock input
              SizedBox(
                width: 110,
                child: ShadInput(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: ShadDecoration(
                    border: ShadBorder.all(
                      color: theme.colorScheme.border,
                      radius: BorderRadius.circular(14),
                    ),
                    color: const Color(0xFFF8FAFC),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val) ?? 0;
                    setState(() {
                      _currentStock = parsed;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Plus 1 Button
              Material(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _updateLocalStock(_currentStock + 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(TablerIcons.plus, size: 22, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Difference Pill
          if (diff != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: diff > 0
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: diff > 0
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                diff > 0
                    ? '+ $diff unit (${isId ? "Penambahan stok" : "Stock addition"})'
                    : '$diff unit (${isId ? "Pengurangan stok" : "Stock reduction"})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: diff > 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            )
          else
            Text(
              isId ? 'Stok tidak berubah' : 'No stock change',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),

          const SizedBox(height: 16),

          // Quick stock adjuster chips
          Wrap(
            spacing: 8,
            children: [
              _adjustChip('-10', -10),
              _adjustChip('-5', -5),
              _adjustChip('+5', 5),
              _adjustChip('+10', 10),
              _adjustChip('+25', 25),
              _adjustChip('+50', 50),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons: Cancel & Save
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  size: ShadButtonSize.lg,
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  backgroundColor: Warna.primary,
                  hoverBackgroundColor: Warna.primary.withValues(alpha: 0.8),
                  foregroundColor: Colors.black,
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSave(_currentStock);
                  },
                  child: Text(
                    l10n.save,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adjustChip(String label, int value) {
    final isAdd = value > 0;
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isAdd ? const Color(0xFF1E293B) : const Color(0xFFDC2626),
        ),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      onPressed: () {
        HapticFeedback.lightImpact();
        _updateLocalStock(_currentStock + value);
      },
    );
  }
}
