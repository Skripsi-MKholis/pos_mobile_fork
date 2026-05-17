import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/widgets/parzello_table.dart';
import 'package:pos_mobile/core/widgets/connectivity_status_bar.dart';
import 'package:pos_mobile/core/utils/debouncer.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  // ⚡ Bolt Optimization: Throttle search input to prevent expensive list filtering on every keystroke
  final Debouncer _debouncer = Debouncer(milliseconds: 300);

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _showDeleteDialog(Product product) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Row(
          children: [
            Icon(TablerIcons.alert_triangle, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Hapus Produk'),
          ],
        ),
        description: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Apakah Anda yakin ingin menghapus "${product.name}"? Tindakan ini tidak dapat dibatalkan.',
          ),
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Hapus Permanen'),
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
        if (mounted) {
          ShadToaster.of(
            context,
          ).show(const ShadToast(description: Text('Produk berhasil dihapus')));
        }
      } catch (e) {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              description: Text('Gagal menghapus produk: $e'),
            ),
          );
        }
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Katalog Produk',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Kelola inventaris barang Anda',
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ShadButton(
                size: ShadButtonSize.sm,
                backgroundColor: const Color(0xFF98D100), // Lime Green
                foregroundColor: Colors.black,
                onPressed: () => context.push('/products/add'),
                leading: const Icon(TablerIcons.plus, size: 18),
                child: const Text(
                  'Tambah',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                        onChanged: (value) {
                          _debouncer.run(() {
                            setState(() => _searchQuery = value);
                          });
                        },
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
                                  () => _selectedCategory = value == 'all'
                                      ? null
                                      : value,
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
                          if (_searchQuery.isNotEmpty || _selectedCategory != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ShadButton.ghost(
                                size: ShadButtonSize.sm,
                                onPressed: () {
                                  _debouncer.cancel();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = null;
                                  });
                                },
                                child: const Icon(TablerIcons.x, size: 18),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ShadButton.outline(
                            onPressed: () => context.push('/categories'),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: const Icon(TablerIcons.category, size: 20),
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

              // TABLE
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filteredProducts = products.where((p) {
                      final matchesSearch =
                          p.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          (p.sku?.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ??
                              false);
                      final matchesCategory =
                          _selectedCategory == null ||
                          p.categoryId == _selectedCategory;
                      return matchesSearch && matchesCategory;
                    }).toList();

                    final tableColumns = [
                      ParzelloColumn(title: 'PRODUK', width: 220),
                      ParzelloColumn(
                        title: 'KATEGORI',
                        width: 120,
                        textAlign: TextAlign.center,
                      ),
                      ParzelloColumn(
                        title: 'HARGA',
                        width: 120,
                        textAlign: TextAlign.center,
                      ),
                      ParzelloColumn(
                        title: 'STOK',
                        width: 70,
                        textAlign: TextAlign.center,
                      ),
                      ParzelloColumn(
                        title: 'AKSI',
                        isFlex: true,
                        textAlign: TextAlign.center,
                      ),
                    ];

                    final categoryMap = categoriesAsync.maybeWhen(
                      data: (categories) => {
                        for (var c in categories) c.supabaseId: c.name,
                      },
                      orElse: () => <String, String>{},
                    );

                    return ParzelloTable(
                      totalWidth: 700,
                      columns: tableColumns,
                      itemCount: filteredProducts.length,
                      onRefresh: () => ref
                          .read(productNotifierProvider.notifier)
                          .syncProducts(),
                      emptyWidget: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.muted.withValues(alpha: 0.5),
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
                            const SizedBox(height: 8),
                            Text(
                              'Coba gunakan kata kunci lain atau\ntambah produk baru ke katalog Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ShadButton.outline(
                              onPressed: () {
                                _debouncer.cancel();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = null;
                                });
                              },
                              child: const Text('Reset Filter'),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final categoryName =
                            categoryMap[product.categoryId] ?? 'Tanpa Kategori';

                        return ParzelloTableRow(
                          columns: tableColumns,
                          children: [
                            // PRODUK
                            Row(
                              children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.muted,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      image: product.imageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(product.imageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : (product.localImagePath != null
                                              ? DecorationImage(
                                                  image: FileImage(File(product.localImagePath!)),
                                                  fit: BoxFit.cover,
                                                )
                                              : null),
                                    ),
                                    child: (product.imageUrl == null && product.localImagePath == null)
                                        ? Icon(
                                            TablerIcons.package,
                                            color:
                                                theme.colorScheme.mutedForeground,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(product.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                          if (!product.isSynced)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(TablerIcons.cloud_off,
                                                  size: 12, color: Colors.orange),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        product.sku ?? 'Tanpa SKU',
                                        style: theme.textTheme.muted.copyWith(
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // KATEGORI
                             Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            // HARGA
                            Text(
                              format.format(product.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // STOK
                             Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: product.stockQuantity < 10
                                      ? BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        )
                                      : null,
                                  child: Text(
                                    '${product.stockQuantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: product.stockQuantity < 10
                                          ? Colors.red
                                          : theme.colorScheme.foreground,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            // AKSI
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => context.push('/products/edit',
                                      extra: product),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(TablerIcons.edit, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _showDeleteDialog(product),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(TablerIcons.trash,
                                        size: 18, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
