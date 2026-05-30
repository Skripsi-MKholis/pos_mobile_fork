import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/widgets/connectivity_status_bar.dart';

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
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    _debouncer.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(Product product) {
    if (!_controllers.containsKey(product.supabaseId)) {
      _controllers[product.supabaseId] =
          TextEditingController(text: product.stockQuantity.toString());
    }
    return _controllers[product.supabaseId]!;
  }

  Future<void> _updateStock(Product product, int newStock) async {
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
          text: 'Stok ${product.name} diperbarui menjadi $newStock',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal memperbarui stok: $e',
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
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Stok',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Pantau dan perbarui stok produk Anda',
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
                      placeholder: const Text('Cari nama atau SKU...'),
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
                              placeholder: const Text(
                                'Semua Kategori',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              options: [
                                const ShadOption(
                                  value: 'all',
                                  child: Text('Semua Kategori'),
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
                                    ? 'Semua'
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
                            error: (err, _) => const ShadSelect<String>(
                              placeholder: Text('Error'),
                              options: [],
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
                  final filteredProducts = products.where((p) {
                    final matchesSearch = p.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        (p.sku?.toLowerCase().contains(
                                _searchQuery.toLowerCase()) ??
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
                            'Produk tidak ditemukan',
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
                      final controller = _getController(product);

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
                                image: product.imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(product.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : (product.localImagePath != null
                                        ? DecorationImage(
                                            image: FileImage(
                                                File(product.localImagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: (product.imageUrl == null &&
                                      product.localImagePath == null)
                                  ? Icon(
                                      TablerIcons.package,
                                      color: theme.colorScheme.mutedForeground,
                                      size: 28,
                                    )
                                  : null,
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Stock Controls
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.muted.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(12)),
                                      onTap: () {
                                        int current =
                                            int.tryParse(controller.text) ?? 0;
                                        controller.text = (current - 1).toString();
                                        _updateStock(product, current - 1);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(TablerIcons.minus, size: 18),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 48,
                                    child: Focus(
                                      onFocusChange: (hasFocus) {
                                        if (!hasFocus) {
                                          int newStock = int.tryParse(controller.text) ?? 0;
                                          if (newStock != product.stockQuantity) {
                                             _updateStock(product, newStock);
                                          }
                                        }
                                      },
                                      child: ShadInput(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 0),
                                        decoration: ShadDecoration(
                                          border: ShadBorder.none,
                                          focusedBorder: ShadBorder.none,
                                        ),
                                        onSubmitted: (value) {
                                          int newStock = int.tryParse(value) ?? 0;
                                          controller.text = newStock.toString();
                                          _updateStock(product, newStock);
                                        },
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.horizontal(
                                          right: Radius.circular(12)),
                                      onTap: () {
                                        int current =
                                            int.tryParse(controller.text) ?? 0;
                                        controller.text = (current + 1).toString();
                                        _updateStock(product, current + 1);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(TablerIcons.plus, size: 18),
                                      ),
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
