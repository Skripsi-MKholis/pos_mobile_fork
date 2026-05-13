import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  final TableOrder order;
  const SplitBillScreen({super.key, required this.order});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  final Map<String, int> _selectedQuantities = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize with 0 for all items
    for (var item in widget.order.items) {
      _selectedQuantities[item['product_id']] = 0;
    }
  }

  double get _selectedTotal {
    double total = 0;
    for (var item in widget.order.items) {
      final qty = _selectedQuantities[item['product_id']] ?? 0;
      total += qty * (item['unit_price'] as num).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Bayar Pisah - Meja ${widget.order.table.name}',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                final productId = item['product_id'];
                final maxQty = item['quantity'] as int;
                final currentQty = _selectedQuantities[productId] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: currentQty > 0 ? Warna.primary.withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentQty > 0 ? Warna.primary.withOpacity(0.3) : Colors.grey.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['product_name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currencyFormat.format(item['unit_price'])} / item',
                              style: theme.textTheme.muted.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(TablerIcons.minus, size: 20),
                            onPressed: currentQty > 0
                                ? () => setState(() => _selectedQuantities[productId] = currentQty - 1)
                                : null,
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '$currentQty / $maxQty',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(TablerIcons.plus, size: 20),
                            onPressed: currentQty < maxQty
                                ? () => setState(() => _selectedQuantities[productId] = currentQty + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildSummary(context, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, NumberFormat format) {
    final theme = ShadTheme.of(context);
    final products = ref.watch(productNotifierProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Terpilih',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  format.format(_selectedTotal),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ShadButton(
              size: ShadButtonSize.lg,
              width: double.infinity,
              backgroundColor: Warna.primary,
              onPressed: _selectedTotal > 0
                  ? () {
                      _proceedToPayment(products);
                    }
                  : null,
              child: const Text(
                'Lanjut Pembayaran',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment(List<Product> allProducts) {
    final List<CartItem> selectedItems = [];
    
    for (var item in widget.order.items) {
      final productId = item['product_id'];
      final qty = _selectedQuantities[productId] ?? 0;
      
      if (qty > 0) {
        final product = allProducts.firstWhere(
          (p) => p.supabaseId == productId,
          orElse: () => Product(
            supabaseId: productId,
            storeId: item['store_id'] ?? '',
            name: item['product_name'],
            price: (item['unit_price'] as num).toDouble(),
            stockQuantity: 0,
          ),
        );
        selectedItems.add(CartItem(product: product, quantity: qty));
      }
    }

    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    cartNotifier.clearCart();
    cartNotifier.selectTable(widget.order.table);
    cartNotifier.setItems(selectedItems);

    context.push('/payment');
  }
}
