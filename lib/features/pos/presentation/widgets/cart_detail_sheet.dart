import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/features/pos/providers/voucher_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CartDetailSheet extends ConsumerStatefulWidget {
  const CartDetailSheet({super.key});

  @override
  ConsumerState<CartDetailSheet> createState() => _CartDetailSheetState();
}

class _CartDetailSheetState extends ConsumerState<CartDetailSheet> {
  final TextEditingController _voucherController = TextEditingController();
  bool _isValidating = false;
  String? _voucherError;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _voucherError = null;
    });

    try {
      final voucher = await ref.read(voucherNotifierProvider.notifier).validateVoucher(code);
      if (voucher != null) {
        final subtotal = ref.read(cartNotifierProvider).subtotal;
        if (subtotal < voucher.minPurchase) {
          setState(() {
            _voucherError = 'Min. belanja ${NumberFormat.currency(locale: "id_ID", symbol: "Rp ", decimalDigits: 0).format(voucher.minPurchase)}';
          });
        } else {
          ref.read(cartNotifierProvider.notifier).applyVoucher(voucher);
          _voucherController.clear();
        }
      } else {
        setState(() {
          _voucherError = 'Kode voucher tidak valid';
        });
      }
    } catch (e) {
      setState(() {
        _voucherError = 'Terjadi kesalahan';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final cartItems = cartState.items;
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
              Text('Detail Pesanan', style: theme.textTheme.h3),
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: () => Navigator.pop(context),
                leading: const Icon(TablerIcons.x),
              ),
            ],
          ),
          if (cartState.selectedTable != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(TablerIcons.armchair, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Meja: ${cartState.selectedTable!.name}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Voucher Section
            if (cartState.appliedVoucher == null)
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _voucherController,
                      placeholder: const Text('Kode Voucher'),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(
                    onPressed: _isValidating ? null : _applyVoucher,
                    child: _isValidating 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Pakai'),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF98D100).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF98D100).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(TablerIcons.ticket, color: Color(0xFF98D100)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voucher: ${cartState.appliedVoucher!.code}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Diskon ${format.format(cartState.discountAmount)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(cartNotifierProvider.notifier).removeVoucher(),
                      icon: const Icon(TablerIcons.trash, color: Colors.red, size: 20),
                    ),
                  ],
                ),
              ),
            if (_voucherError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_voucherError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
              
            const SizedBox(height: 20),
            
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: theme.textTheme.muted),
                Text(format.format(cartState.subtotal)),
              ],
            ),
            if (cartState.discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Diskon Voucher', style: theme.textTheme.muted),
                  Text('- ${format.format(cartState.discountAmount)}', style: const TextStyle(color: Colors.red)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Bayar', style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w800)),
                Text(format.format(cartState.totalAmount), 
                  style: theme.textTheme.h3.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
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
