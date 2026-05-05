import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

class CartDetailSheet extends ConsumerWidget {
  const CartDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartNotifierProvider);
    final total = ref.read(cartNotifierProvider.notifier).totalAmount;
    final theme = ShadTheme.of(context);
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
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
              Text('Keranjang Belanja', style: theme.textTheme.h3),
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: () => Navigator.pop(context),
                leading: const Icon(TablerIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(TablerIcons.shopping_cart_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Keranjang masih kosong', style: theme.textTheme.muted),
                ],
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('${item.quantity} x ${format.format(item.product.price)}', 
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(format.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        ShadButton.outline(
                          size: ShadButtonSize.sm,
                          padding: EdgeInsets.zero,
                          onPressed: () => ref.read(cartNotifierProvider.notifier).updateQuantity(item.product.supabaseId, item.quantity - 1),
                          leading: const Icon(TablerIcons.minus, size: 16),
                        ),
                        const SizedBox(width: 4),
                        ShadButton.outline(
                          size: ShadButtonSize.sm,
                          padding: EdgeInsets.zero,
                          onPressed: () => ref.read(cartNotifierProvider.notifier).updateQuantity(item.product.supabaseId, item.quantity + 1),
                          leading: const Icon(TablerIcons.plus, size: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Bayar', style: theme.textTheme.large),
                Text(format.format(total), style: theme.textTheme.h3.copyWith(color: Colors.black)),
              ],
            ),
            const SizedBox(height: 24),
            ShadButton(
              size: ShadButtonSize.lg,
              onPressed: () {
                Navigator.pop(context);
                context.push('/payment');
              },
              child: const Text('Lanjut Pembayaran'),
            ),
          ],
        ],
      ),
    );
  }
}
