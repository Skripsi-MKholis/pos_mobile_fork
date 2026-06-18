import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/core/widgets/connectivity_status_bar.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

class StockManagementScreen extends ConsumerStatefulWidget {
  const StockManagementScreen({super.key});

  @override
  ConsumerState<StockManagementScreen> createState() =>
      _StockManagementScreenState();
}

class _StockManagementScreenState extends ConsumerState<StockManagementScreen> {
  // Optimization: Debouncer prevents expensive UI rebuilds and local filtering on every keystroke.
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _openStockEditModal(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockEditSheet(
        product: product,
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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    final locale = Localizations.localeOf(context);
    final format = NumberFormat.currency(
      locale: locale.toString(),
      symbol: locale.languageCode == 'id' ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
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
        toolbarHeight: 80,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ConnectivityStatusBar(),
            const SizedBox(height: 8),

            // SEARCH & FILTER BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.border.withValues(alpha: 0.5),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 450;

                    final searchInput = ShadInput(
                      placeholder: Text(l10n.searchNameOrSku),
                      leading: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(TablerIcons.search, size: 20),
                      ),
                      onChanged: (value) =>
                          _debouncer.run(() => setState(() => _searchQuery = value)),
                      decoration: ShadDecoration(
                        border: ShadBorder.none,
                        color: theme.colorScheme.background,
                      ),
                    );

                    final filterRow = Row(
                      children: [
                        Expanded(
                          child: categoriesAsync.when(
                            data: (categories) => ShadSelect<String>(
                              placeholder: Text(
                                l10n.allCategories,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              options: [
                                ShadOption(
                                  value: 'all',
                                  child: Text(l10n.allCategories),
                                ),
                                ...categories.map(
                                  (c) => ShadOption(
                                    value: c.supabaseId,
                                    child: Text(c.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _selectedCategory =
                                    value == 'all' ? null : value,
                              ),
                              selectedOptionBuilder: (context, value) => Text(
                                value == 'all'
                                    ? l10n.all
                                    : categories
                                          .firstWhere(
                                            (c) => c.supabaseId == value,
                                          )
                                          .name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            loading: () => const ShadSelect<String>(
                              placeholder: Text('...'),
                              options: [],
                              selectedOptionBuilder: null,
                            ),
                            error: (err, _) => ShadSelect<String>(
                              placeholder: Text('Error: $err'),
                              options: const [],
                              selectedOptionBuilder: null,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ShadButton.ghost(
                              size: ShadButtonSize.sm,
                              onPressed: () {
                                _debouncer.dispose(); // Cancel pending updates
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = null;
                                });
                              },
                              child: const Icon(TablerIcons.x, size: 18),
                            ),
                          ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          searchInput,
                          const SizedBox(height: 12),
                          filterRow,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 2, child: searchInput),
                        const SizedBox(width: 12),
                        Expanded(child: filterRow),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // ⚡ Bolt: Hoist invariant toLowerCase() outside the loop to prevent O(N) redundant string conversions
                  final lowerQuery = _searchQuery.toLowerCase();
                  final filteredProducts = products.where((p) {
                    final matchesSearch = p.name
                            .toLowerCase()
                            .contains(lowerQuery) ||
                        (p.sku?.toLowerCase().contains(
                                lowerQuery) ??
                            false);
                    final matchesCategory = _selectedCategory == null ||
                        p.categoryId == _selectedCategory;
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              TablerIcons.package_off,
                              size: 48,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.productNotFound,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.muted,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: product.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: product.imageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        maxHeightDiskCache: 120, // Resizes and caches optimized low-res image
                                        maxWidthDiskCache: 120,
                                        placeholder: (context, url) => Shimmer.fromColors(
                                          baseColor: theme.colorScheme.muted.withOpacity(0.5),
                                          highlightColor: theme.colorScheme.muted.withOpacity(0.2),
                                          child: Container(
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => const Center(
                                          child: Icon(
                                            TablerIcons.package_off,
                                            color: Colors.grey,
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : (product.localImagePath != null
                                        ? Image.file(
                                            File(product.localImagePath!),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Icon(
                                            TablerIcons.package,
                                            color: theme.colorScheme.mutedForeground,
                                            size: 28,
                                          )),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    format.format(product.price),
                                    style: TextStyle(
                                      color: theme.colorScheme.mutedForeground,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: product.stockQuantity == 0
                                              ? Colors.red.withValues(alpha: 0.1)
                                              : (product.stockQuantity <= 10
                                                  ? Colors.amber.withValues(alpha: 0.1)
                                                  : Colors.green.withValues(alpha: 0.1)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          l10n.stockCount(product.stockQuantity),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: product.stockQuantity == 0
                                                ? Colors.red.shade700
                                                : (product.stockQuantity <= 10
                                                    ? Colors.amber.shade700
                                                    : Colors.green.shade700),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ShadButton(
                              size: ShadButtonSize.sm,
                              backgroundColor: Warna.primary,
                              hoverBackgroundColor:
                                  Warna.primary.withValues(alpha: 0.8),
                              foregroundColor: Colors.black,
                              onPressed: () => _openStockEditModal(context, product),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(TablerIcons.edit, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.edit,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
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

  const _StockEditSheet({
    required this.product,
    required this.onSave,
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
    _currentStock = widget.product.stockQuantity;
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
    final locale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: locale.startsWith('id') ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.mutedForeground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header title
          Text(
            'Ubah Stok Produk',
            style: theme.textTheme.large.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),

          // Product details Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                 Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            maxHeightDiskCache: 120, // Resizes and caches optimized low-res image
                            maxWidthDiskCache: 120,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: theme.colorScheme.muted.withValues(alpha: 0.5),
                              highlightColor: theme.colorScheme.muted.withValues(alpha: 0.2),
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                TablerIcons.package_off,
                                color: Colors.grey,
                                size: 24,
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
                            : Icon(
                                TablerIcons.package,
                                color: theme.colorScheme.mutedForeground,
                                size: 24,
                              )),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(widget.product.price),
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Current stock badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Stok Saat Ini',
                        style: TextStyle(
                          fontSize: 8,
                          color: theme.colorScheme.mutedForeground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.stockQuantity.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stock Counter Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus Button
              Material(
                color: theme.colorScheme.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _updateLocalStock(_currentStock - 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(TablerIcons.minus, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Stock input
              SizedBox(
                width: 90,
                child: ShadInput(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ShadDecoration(
                    border: ShadBorder.all(
                      color: theme.colorScheme.border,
                      radius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val) ?? 0;
                    setState(() {
                      _currentStock = parsed;
                    });
                  },
                ),
              ),
              const SizedBox(width: 20),

              // Plus Button
              Material(
                color: theme.colorScheme.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _updateLocalStock(_currentStock + 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(TablerIcons.plus, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick stock adjuster chips
          Wrap(
            spacing: 8,
            children: [
              _adjustChip('-10', -10, theme),
              _adjustChip('-5', -5, theme),
              _adjustChip('+5', 5, theme),
              _adjustChip('+10', 10, theme),
            ],
          ),
          const SizedBox(height: 32),

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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adjustChip(String label, int value, ShadThemeData theme) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.foreground,
        ),
      ),
      backgroundColor: theme.colorScheme.muted.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onPressed: () {
        HapticFeedback.lightImpact();
        _updateLocalStock(_currentStock + value);
      },
    );
  }
}
