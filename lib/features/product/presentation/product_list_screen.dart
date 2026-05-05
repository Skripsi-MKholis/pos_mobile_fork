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

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  Future<void> _showDeleteDialog(Product product) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Hapus Produk'),
        description: Text(
          'Apakah Anda yakin ingin menghapus "${product.name}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Hapus'),
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
          title: const Text(
            'Katalog Produk',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: theme.colorScheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(TablerIcons.chevron_left),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ShadButton(
                size: ShadButtonSize.sm,
                backgroundColor: const Color(0xFF98D100), // Lime Green
                onPressed: () => context.push('/products/add'),
                leading: const Icon(TablerIcons.plus, size: 16),
                child: const Text('Tambah'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConnectivityStatusBar(),
              
              // SUBTITLE AREA
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Kelola inventaris barang yang Anda jual.',
                  style: theme.textTheme.muted,
                ),
              ),

              // SEARCH & FILTER BAR
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
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
                          setState(() => _searchQuery = value),
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
                        const SizedBox(width: 8),
                        ShadButton.outline(
                          onPressed: () => context.push('/categories'),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: const Icon(TablerIcons.settings, size: 18),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          searchInput,
                          const SizedBox(height: 8),
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
                            Icon(
                              TablerIcons.package,
                              size: 64,
                              color: theme.colorScheme.muted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Produk tidak ditemukan',
                              style: TextStyle(
                                color: theme.colorScheme.mutedForeground,
                              ),
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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.muted,
                                    borderRadius: BorderRadius.circular(8),
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
                                          size: 20,
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
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(
                                    alpha: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
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
                            Text(
                              '${product.stockQuantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: product.stockQuantity < 10
                                    ? Colors.red
                                    : null,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
