import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class CartDetailSheet extends ConsumerWidget {
  const CartDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Detail Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(TablerIcons.trash, color: Colors.red),
                onPressed: () => cartNotifier.clearCart(),
              ),
            ],
          ),
          const Divider(),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: cartItems.isEmpty 
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Keranjang Kosong')))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(currencyFormat.format(item.product.price), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(TablerIcons.minus, size: 20),
                                onPressed: () => cartNotifier.updateQuantity(item.product.supabaseId, item.quantity - 1),
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(TablerIcons.plus, size: 20),
                                onPressed: () => cartNotifier.updateQuantity(item.product.supabaseId, item.quantity + 1),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(currencyFormat.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Belanja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(cartNotifier.totalAmount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Warna.primary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: cartItems.isEmpty ? null : () {
              Navigator.pop(context); // Close sheet
              context.push('/payment');
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Bayar Sekarang'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
