import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/features/pos/presentation/widgets/cart_detail_sheet.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';

import 'package:pos_mobile/features/pos/providers/table_provider.dart';
import 'package:pos_mobile/core/models/table.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _showTablePicker(BuildContext context, WidgetRef ref) async {
    final tablesAsync = ref.read(tableNotifierProvider);
    final currentTable = ref.read(cartNotifierProvider).selectedTable;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final tablesAsync = ref.watch(tableNotifierProvider);
          return Container(
            decoration: BoxDecoration(
              color: ShadTheme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Meja',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (currentTable != null)
                      ShadButton.ghost(
                        onPressed: () {
                          ref.read(cartNotifierProvider.notifier).selectTable(null);
                          Navigator.pop(context);
                        },
                        child: const Text('Reset', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                tablesAsync.when(
                  data: (tables) => tables.isEmpty
                      ? const Center(child: Text('Tidak ada meja tersedia'))
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: tables.map((table) {
                            final isSelected = currentTable?.id == table.id;
                            final isOccupied = table.status == 'occupied';
                            
                            return InkWell(
                              onTap: isOccupied ? null : () {
                                ref.read(cartNotifierProvider.notifier).selectTable(table);
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 80,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFF98D100)
                                      : (isOccupied ? Colors.red.withValues(alpha: 0.1) : ShadTheme.of(context).colorScheme.muted),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? const Color(0xFF98D100) 
                                        : (isOccupied ? Colors.red.withValues(alpha: 0.2) : Colors.transparent),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      TablerIcons.armchair, 
                                      size: 24,
                                      color: isSelected ? Colors.black : (isOccupied ? Colors.red : Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      table.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.black : (isOccupied ? Colors.red : null),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final cartItems = cartState.items;
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        // Top Toolbar with Table Selection
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: _searchController,
                  placeholder: const Text('Cari produk...'),
                  leading: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(TablerIcons.search, size: 20),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showTablePicker(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cartState.selectedTable != null 
                        ? const Color(0xFF98D100).withValues(alpha: 0.1)
                        : theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cartState.selectedTable != null 
                          ? const Color(0xFF98D100)
                          : theme.colorScheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        TablerIcons.armchair, 
                        size: 20,
                        color: cartState.selectedTable != null 
                            ? const Color(0xFF98D100)
                            : theme.colorScheme.foreground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cartState.selectedTable?.name ?? 'Meja',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cartState.selectedTable != null 
                              ? const Color(0xFF98D100)
                              : theme.colorScheme.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final filteredProducts = products.where((p) =>
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();

              if (filteredProducts.isEmpty) {
                return const Center(child: Text('Produk tidak ditemukan'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final cartItem = cartItems.firstWhere(
                    (item) => item.product.supabaseId == product.supabaseId,
                    orElse: () => CartItem(product: product, quantity: 0),
                  );

                  return _buildProductCard(context, product, cartItem, cartNotifier, currencyFormat);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
        if (cartItems.isNotEmpty) _buildCartSummary(context, cartNotifier, currencyFormat),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product, CartItem cartItem, CartNotifier cartNotifier, NumberFormat format) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => cartNotifier.addItem(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  image: product.imageUrl != null
                      ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: product.imageUrl == null
                    ? const Center(child: Icon(TablerIcons.package, size: 40, color: Colors.grey))
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(format.format(product.price), style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (cartItem.quantity > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.foreground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${cartItem.quantity}x',
                        style: TextStyle(
                          color: theme.colorScheme.background,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Stok: ${product.stockQuantity}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.mutedForeground),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartNotifier cartNotifier, NumberFormat format) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        boxShadow: [BoxShadow(color: theme.colorScheme.foreground.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Belanja',
                    style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 12),
                  ),
                  Text(
                    format.format(cartNotifier.totalAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ShadButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CartDetailSheet(),
                );
              },
              child: const Text('Cek Detail'),
            ),
          ],
        ),
      ),
    );
  }
}
