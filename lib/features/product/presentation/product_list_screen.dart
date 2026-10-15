import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart'
    show DemandTrend;
import 'package:pos_mobile/features/reports/presentation/widgets/recommendation_style.dart'
    show DemandTrendStyle;
import 'package:pos_mobile/features/reports/providers/stock_forecast_provider.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/core/widgets/connectivity_status_bar.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';
import 'package:flutter/rendering.dart';

enum ProductCatalogSort {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  stockAsc,
  stockDesc,
}

class ProductListScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const ProductListScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showSlowingOnly = false;
  ProductCatalogSort _sortOption = ProductCatalogSort.nameAsc;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortModal(bool isId) {
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
                  isId ? 'Urutkan Produk' : 'Sort Products',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _sortTile(
                  title: isId ? 'Nama (A - Z)' : 'Name (A - Z)',
                  subtitle: isId ? 'Urutkan alfabet produk A ke Z' : 'Alphabetical ascending',
                  selected: _sortOption == ProductCatalogSort.nameAsc,
                  onTap: () {
                    setState(() => _sortOption = ProductCatalogSort.nameAsc);
                    Navigator.pop(context);
                  },
                ),
                _sortTile(
                  title: isId ? 'Nama (Z - A)' : 'Name (Z - A)',
                  subtitle: isId ? 'Urutkan alfabet produk Z ke A' : 'Alphabetical descending',
                  selected: _sortOption == ProductCatalogSort.nameDesc,
                  onTap: () {
                    setState(() => _sortOption = ProductCatalogSort.nameDesc);
                    Navigator.pop(context);
                  },
                ),
                _sortTile(
                  title: isId ? 'Harga Termurah' : 'Lowest Price',
                  subtitle: isId ? 'Dari harga paling rendah' : 'Price low to high',
                  selected: _sortOption == ProductCatalogSort.priceAsc,
                  onTap: () {
                    setState(() => _sortOption = ProductCatalogSort.priceAsc);
                    Navigator.pop(context);
                  },
                ),
                _sortTile(
                  title: isId ? 'Harga Tertinggi' : 'Highest Price',
                  subtitle: isId ? 'Dari harga paling tinggi' : 'Price high to low',
                  selected: _sortOption == ProductCatalogSort.priceDesc,
                  onTap: () {
                    setState(() => _sortOption = ProductCatalogSort.priceDesc);
                    Navigator.pop(context);
                  },
                ),
                _sortTile(
                  title: isId ? 'Stok Paling Sedikit' : 'Lowest Stock',
                  subtitle: isId ? 'Prioritaskan produk yang hampir habis' : 'Low stock items first',
                  selected: _sortOption == ProductCatalogSort.stockAsc,
                  onTap: () {
                    setState(() => _sortOption = ProductCatalogSort.stockAsc);
                    Navigator.pop(context);
                  },
                ),
                _sortTile(
                  title: isId ? 'Stok Paling Banyak' : 'Highest Stock',
                  subtitle: isId ? 'Dari jumlah unit terbanyak' : 'Most stock items first',
                  selected: _sortOption == ProductCatalogSort.stockDesc,
                  onTap: () {
                    setState(() => _sortOption = ProductCatalogSort.stockDesc);
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
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
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

  Future<void> _showDeleteDialog(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Row(
          children: [
            const Icon(TablerIcons.alert_triangle, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(l10n.deleteProduct),
          ],
        ),
        description: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l10n.deleteProductConfirm(product.name),
          ),
        ),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text(l10n.deletePermanently),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(productNotifierProvider.notifier)
            .deleteProduct(product.supabaseId);

        try {
          final categories = ref.read(categoryNotifierProvider).value;
          final categoryName = categories?.firstWhere(
              (c) => c.supabaseId == product.categoryId,
              orElse: () => Category()..name = 'Tanpa Kategori',
            ).name ?? 'Tanpa Kategori';

          await AnalyticsService.instance.logProductDeletion(categoryName: categoryName);
        } catch (_) {}

        if (mounted) {
          mySnackBar(
            context: context,
            text: l10n.productDeletedSuccess,
            status: ToastStatus.success,
          );
        }
      } catch (e) {
        if (mounted) {
          mySnackBar(
            context: context,
            text: l10n.productDeleteFailed(e.toString()),
            status: ToastStatus.error,
          );
        }
      }
    }
  }

  void _openBarcodeViewer(
    BuildContext context,
    Product product,
    String categoryName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _BarcodeViewerSheet(product: product, categoryName: categoryName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final theme = ShadTheme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isId = locale.startsWith('id');

    final format = NumberFormat.currency(
      locale: locale,
      symbol: isId ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.productCatalog,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isId ? 'Kelola produk, harga & stok' : 'Manage products, prices & inventory',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
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
                context.go('/dashboard');
              }
            },
          ),
          toolbarHeight: 70,
          actions: [
            // Quick manage category icon button
            IconButton(
              tooltip: l10n.manageCategories,
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(TablerIcons.category, size: 19, color: Color(0xFF334155)),
              ),
              onPressed: () => context.push('/categories'),
            ),
            const SizedBox(width: 4),

            // Add Product action button (Minimalist Pill)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push('/products/add'),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Warna.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(TablerIcons.plus, size: 16, color: Colors.black),
                      const SizedBox(width: 5),
                      Text(
                        l10n.add,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConnectivityStatusBar(),

              // 1. Search Bar & Sort Button Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    // Search box
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
                            hintText: l10n.searchNameOrSku,
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort button
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showSortModal(isId),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _sortOption != ProductCatalogSort.nameAsc
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _sortOption != ProductCatalogSort.nameAsc
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TablerIcons.arrows_sort,
                              size: 15,
                              color: _sortOption != ProductCatalogSort.nameAsc
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _getSortLabel(_sortOption, isId),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _sortOption != ProductCatalogSort.nameAsc
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _sortOption != ProductCatalogSort.nameAsc
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Category & Filter Pills
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: categoriesAsync.maybeWhen(
                  data: (categories) {
                    final slowingIds = ref.watch(slowingProductIdsProvider);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill(
                            label: l10n.all,
                            isSelected: _selectedCategory == null && !_showSlowingOnly,
                            onTap: () {
                              setState(() {
                                _selectedCategory = null;
                                _showSlowingOnly = false;
                              });
                            },
                          ),
                          if (slowingIds.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildFilterPill(
                              label: isId ? 'Melambat' : 'Slowing',
                              icon: TablerIcons.trending_down,
                              badgeColor: const Color(0xFFEA580C),
                              isSelected: _showSlowingOnly,
                              onTap: () {
                                setState(() {
                                  _showSlowingOnly = !_showSlowingOnly;
                                  if (_showSlowingOnly) _selectedCategory = null;
                                });
                              },
                            ),
                          ],
                          ...categories.map((c) {
                            final isSelected = _selectedCategory == c.supabaseId && !_showSlowingOnly;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildFilterPill(
                                label: c.name,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = isSelected ? null : c.supabaseId;
                                    _showSlowingOnly = false;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),

              // 3. Product List
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    var filteredProducts = products.where((p) {
                      final query = _searchQuery.toLowerCase().trim();
                      final matchesSearch = query.isEmpty ||
                          p.name.toLowerCase().contains(query) ||
                          (p.sku?.toLowerCase().contains(query) ?? false);
                      final matchesCategory =
                          _selectedCategory == null || p.categoryId == _selectedCategory;
                      final matchesTrend =
                          !_showSlowingOnly || ref.read(slowingProductIdsProvider).contains(p.supabaseId);
                      return matchesSearch && matchesCategory && matchesTrend;
                    }).toList();

                    // Apply Sorting
                    filteredProducts.sort((a, b) {
                      switch (_sortOption) {
                        case ProductCatalogSort.nameAsc:
                          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                        case ProductCatalogSort.nameDesc:
                          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
                        case ProductCatalogSort.priceAsc:
                          final cmp = a.price.compareTo(b.price);
                          return cmp != 0 ? cmp : a.name.compareTo(b.name);
                        case ProductCatalogSort.priceDesc:
                          final cmp = b.price.compareTo(a.price);
                          return cmp != 0 ? cmp : a.name.compareTo(b.name);
                        case ProductCatalogSort.stockAsc:
                          final cmp = a.stockQuantity.compareTo(b.stockQuantity);
                          return cmp != 0 ? cmp : a.name.compareTo(b.name);
                        case ProductCatalogSort.stockDesc:
                          final cmp = b.stockQuantity.compareTo(a.stockQuantity);
                          return cmp != 0 ? cmp : a.name.compareTo(b.name);
                      }
                    });

                    final categoryMap = categoriesAsync.maybeWhen(
                      data: (categories) => {
                        for (var c in categories) c.supabaseId: c.name,
                      },
                      orElse: () => <String, String>{},
                    );

                    if (filteredProducts.isEmpty) {
                      return RefreshIndicator(
                        color: Warna.primary,
                        onRefresh: () => ref.read(productNotifierProvider.notifier).syncProducts(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: _buildEmptyState(
                                    theme,
                                    hasActiveFilter: _searchQuery.isNotEmpty ||
                                        _selectedCategory != null ||
                                        _showSlowingOnly,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: Warna.primary,
                      onRefresh: () => ref.read(productNotifierProvider.notifier).syncProducts(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 80),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final categoryName = categoryMap[product.categoryId] ?? (isId ? 'Tanpa Kategori' : 'No Category');
                          return _buildProductCard(
                            context,
                            product,
                            categoryName,
                            theme,
                            format,
                            isId,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Warna.primary, strokeWidth: 2.5),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(TablerIcons.alert_circle, size: 36, color: Color(0xFFE11D48)),
                        const SizedBox(height: 8),
                        Text('Error: $err', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
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

  String _getSortLabel(ProductCatalogSort sort, bool isId) {
    switch (sort) {
      case ProductCatalogSort.nameAsc:
        return 'A-Z';
      case ProductCatalogSort.nameDesc:
        return 'Z-A';
      case ProductCatalogSort.priceAsc:
        return isId ? 'Termurah' : 'Lowest';
      case ProductCatalogSort.priceDesc:
        return isId ? 'Tertinggi' : 'Highest';
      case ProductCatalogSort.stockAsc:
        return isId ? 'Stok Terendah' : 'Low Stock';
      case ProductCatalogSort.stockDesc:
        return isId ? 'Stok Terbanyak' : 'High Stock';
    }
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : (badgeColor ?? const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChip(String productSupabaseId) {
    final forecast = ref.watch(stockForecastProvider)[productSupabaseId];
    final trend = forecast?.demand.trend;
    if (trend == null || trend == DemandTrend.flat) {
      return const SizedBox.shrink();
    }

    final style = DemandTrendStyle.of(trend);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 10, color: style.color),
            const SizedBox(width: 3),
            Text(
              style.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: style.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockIndicator(int stock, ShadThemeData theme) {
    Color bgColor;
    Color textColor;
    String label;

    if (stock == 0) {
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFDC2626);
      label = AppLocalizations.of(context)!.outOfStock;
    } else if (stock <= 10) {
      bgColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFD97706);
      label = AppLocalizations.of(context)!.lowStockCount(stock);
    } else {
      bgColor = const Color(0xFFF0FDF4);
      textColor = const Color(0xFF16A34A);
      label = AppLocalizations.of(context)!.stockCount(stock);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    String categoryName,
    ShadThemeData theme,
    NumberFormat format,
    bool isId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Thumbnail Image (Compact & Clean)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      maxHeightDiskCache: 120,
                      maxWidthDiskCache: 120,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade100,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(TablerIcons.package_off, color: Color(0xFF94A3B8), size: 22),
                      ),
                    )
                  : (product.localImagePath != null
                      ? Image.file(
                          File(product.localImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : const Center(
                          child: Icon(TablerIcons.package, color: Color(0xFF94A3B8), size: 22),
                        )),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Product Name, Category & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name + Unsynced icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!product.isSynced)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Tooltip(
                          message: AppLocalizations.of(context)!.waitingForSync,
                          child: const Icon(TablerIcons.cloud_off, size: 13, color: Color(0xFFF59E0B)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),

                // Category & Trend & Stock
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTrendChip(product.supabaseId),
                    _buildStockIndicator(product.stockQuantity, theme),
                  ],
                ),
                const SizedBox(height: 4),

                // Price & SKU
                Row(
                  children: [
                    Text(
                      format.format(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (product.sku != null && product.sku!.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _openBarcodeViewer(context, product, categoryName);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(TablerIcons.barcode, size: 11, color: Color(0xFF475569)),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    product.sku!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // 3. Compact Edit & Delete Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                tooltip: AppLocalizations.of(context)!.edit,
                icon: const Icon(TablerIcons.edit, size: 17, color: Color(0xFF475569)),
                onPressed: () => context.push('/products/edit', extra: product),
              ),
              const SizedBox(width: 2),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                tooltip: AppLocalizations.of(context)!.deleteProduct,
                icon: const Icon(TablerIcons.trash, size: 17, color: Color(0xFFDC2626)),
                onPressed: () => _showDeleteDialog(product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    ShadThemeData theme, {
    required bool hasActiveFilter,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasActiveFilter ? TablerIcons.filter_off : TablerIcons.package,
              size: 38,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilter ? l10n.productNotFound : l10n.noProductsYet,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              hasActiveFilter ? l10n.productNotFoundDesc : l10n.noProductsYetDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasActiveFilter) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedCategory = null;
                      _showSlowingOnly = false;
                      _sortOption = ProductCatalogSort.nameAsc;
                    });
                  },
                  icon: const Icon(TablerIcons.filter_off, size: 16),
                  label: Text(l10n.resetFilter, style: const TextStyle(fontSize: 12.5)),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Warna.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push('/products/add'),
                icon: const Icon(TablerIcons.plus, size: 16),
                label: Text(l10n.addProduct, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarcodeViewerSheet extends StatefulWidget {
  final Product product;
  final String categoryName;

  const _BarcodeViewerSheet({
    required this.product,
    required this.categoryName,
  });

  @override
  State<_BarcodeViewerSheet> createState() => _BarcodeViewerSheetState();
}

class _BarcodeViewerSheetState extends State<_BarcodeViewerSheet> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareBarcodeCard() async {
    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/barcode_${widget.product.sku}.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await Share.shareXFiles([
        XFile(file.path),
      ], text: l10n.barcodeShareText(widget.product.name, widget.product.sku ?? ''));
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: AppLocalizations.of(context)!.shareFailed(e.toString()),
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.product.sku ?? ''));
    HapticFeedback.lightImpact();

    mySnackBar(
      context: context,
      text: AppLocalizations.of(context)!.skuCopied,
      status: ToastStatus.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final sku = widget.product.sku ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.productBarcode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(TablerIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.product.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.categoryName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        height: 90,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: sku,
                          width: double.infinity,
                          height: 70,
                          color: Colors.black,
                          drawText: false,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sku,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: _copyToClipboard,
                      leading: const Icon(TablerIcons.copy, size: 18),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(AppLocalizations.of(context)!.copySku),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadButton(
                      backgroundColor: Warna.primary,
                      foregroundColor: Colors.black,
                      onPressed: _isSharing ? null : _shareBarcodeCard,
                      leading: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(TablerIcons.share, size: 18),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppLocalizations.of(context)!.share,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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
}
