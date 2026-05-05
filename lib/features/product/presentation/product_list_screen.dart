import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final theme = ShadTheme.of(context);
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER AREA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Katalog Produk',
                        style: theme.textTheme.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola inventaris barang yang Anda jual.',
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                  ShadButton(
                    backgroundColor: const Color(0xFF98D100), // Lime Green
                    onPressed: () => context.push('/products/new'),
                    leading: const Icon(TablerIcons.plus, size: 18),
                    child: const Text('Tambah Produk'),
                  ),
                ],
              ),
            ),

            // SEARCH & FILTER BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ShadInput(
                      placeholder: const Text('Cari nama atau SKU...'),
                      leading: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(TablerIcons.search, size: 20),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: categoriesAsync.when(
                      data: (categories) => ShadSelect<String>(
                        placeholder: const Text('Semua Kategori'),
                        options: [
                          const ShadOption(value: 'all', child: Text('Semua Kategori')),
                          ...categories.map((c) => ShadOption(value: c.supabaseId, child: Text(c.name))),
                        ],
                        onChanged: (value) => setState(() => _selectedCategory = value == 'all' ? null : value),
                        selectedOptionBuilder: (context, value) => Text(
                          value == 'all' ? 'Semua Kategori' : categories.firstWhere((c) => c.supabaseId == value).name,
                        ),
                      ),
                      loading: () => const ShadSelect<String>(
                        placeholder: Text('Loading...'),
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TABLE HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Produk', style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Kategori', style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Harga', style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Stok', style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 80, child: Center(child: Text('Aksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),

            const Divider(indent: 24, endIndent: 24),

            // PRODUCT LIST
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(productNotifierProvider.notifier).syncProducts(),
                child: productsAsync.when(
                data: (products) {
                  final filteredProducts = products.where((p) {
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                    final matchesCategory = _selectedCategory == null || p.categoryId == _selectedCategory;
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(TablerIcons.package_off, size: 64, color: theme.colorScheme.muted),
                          const SizedBox(height: 16),
                          Text('Tidak ada produk', style: TextStyle(color: theme.colorScheme.mutedForeground)),
                        ],
                      ),
                    );
                  }

                  return categoriesAsync.when(
                    data: (categories) {
                      final categoryMap = {for (var c in categories) c.supabaseId: c.name};
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final categoryName = categoryMap[product.categoryId] ?? 'Tanpa Kategori';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: theme.colorScheme.border.withValues(alpha: 0.5))),
                            ),
                            child: Row(
                              children: [
                                // PRODUK COLUMN
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.muted,
                                          borderRadius: BorderRadius.circular(8),
                                          image: product.imageUrl != null
                                              ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                                              : null,
                                        ),
                                        child: product.imageUrl == null
                                            ? Icon(TablerIcons.package, color: theme.colorScheme.mutedForeground, size: 20)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text(product.sku ?? 'Tanpa SKU', style: theme.textTheme.muted.copyWith(fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // KATEGORI COLUMN
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                // HARGA COLUMN
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    format.format(product.price),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                // STOK COLUMN
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${product.stockQuantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: product.stockQuantity < 10 ? Colors.red : null,
                                    ),
                                  ),
                                ),
                                // AKSI COLUMN
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(TablerIcons.edit, size: 18),
                                        onPressed: () => context.push('/products/edit', extra: product),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(TablerIcons.trash, size: 18, color: Colors.red),
                                        onPressed: () {}, // TODO: Implement delete
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
                    error: (err, _) => Center(child: Text('Error loading categories: $err')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
