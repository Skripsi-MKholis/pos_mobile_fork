import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productNotifierProvider);
    final theme = ShadTheme.of(context);
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: const Text('Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.plus),
            onPressed: () => context.push('/products/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: const Text('Cari nama produk atau SKU...'),
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(TablerIcons.search, size: 20),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = products.where((p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();

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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ShadCard(
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                          onTap: () => context.push('/products/edit', extra: product),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.muted,
                                  borderRadius: BorderRadius.circular(8),
                                  image: product.imageUrl != null
                                      ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: product.imageUrl == null
                                    ? const Icon(TablerIcons.package, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('SKU: ${product.sku ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(format.format(product.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: product.stockQuantity > 5 ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Stok: ${product.stockQuantity}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: product.stockQuantity > 5 ? Colors.green.shade700 : Colors.red.shade700,
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
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
