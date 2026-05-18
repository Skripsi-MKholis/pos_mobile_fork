import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
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
      final voucher = await ref
          .read(voucherNotifierProvider.notifier)
          .validateVoucher(code);
      if (voucher != null) {
        final subtotal = ref.read(cartNotifierProvider).subtotal;
        if (subtotal < voucher.minPurchase) {
          setState(() {
            _voucherError =
                'Min. belanja ${NumberFormat.currency(locale: "id_ID", symbol: "Rp ", decimalDigits: 0).format(voucher.minPurchase)}';
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
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    const showVoucher = false; // Matikan sementara fitur voucher

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Pesanan',
                      style: theme.textTheme.h3.copyWith(fontSize: 22),
                    ),
                    if (cartState.selectedTable != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              TablerIcons.armchair,
                              size: 14,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Meja: ${cartState.selectedTable!.name}',
                              style: TextStyle(
                                color: theme.colorScheme.mutedForeground,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.muted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        TablerIcons.shopping_cart_off,
                        size: 40,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keranjang masih kosong',
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              )
            else ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  format.format(item.product.price),
                                  style: TextStyle(
                                    color: theme.colorScheme.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                format.format(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => ref
                                            .read(cartNotifierProvider.notifier)
                                            .updateQuantity(
                                              item.product.supabaseId,
                                              item.quantity - 1,
                                            ),
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              left: Radius.circular(10),
                                            ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            TablerIcons.minus,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => ref
                                            .read(cartNotifierProvider.notifier)
                                            .updateQuantity(
                                              item.product.supabaseId,
                                              item.quantity + 1,
                                            ),
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              right: Radius.circular(10),
                                            ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            TablerIcons.plus,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (showVoucher) ...[
                const SizedBox(height: 16),
                // Voucher Section
                if (cartState.appliedVoucher == null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ShadInput(
                            controller: _voucherController,
                            placeholder: const Text('Punya kode voucher?'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: ShadDecoration(
                              border: ShadBorder.none,
                              focusedBorder: ShadBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShadButton(
                          onPressed: _isValidating ? null : _applyVoucher,
                          child: _isValidating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Pakai'),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF98D100).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF98D100).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF98D100),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            TablerIcons.ticket,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voucher: ${cartState.appliedVoucher!.code}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Hemat ${format.format(cartState.discountAmount)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(cartNotifierProvider.notifier)
                              .removeVoucher(),
                          icon: const Icon(
                            TablerIcons.trash,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_voucherError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        const Icon(
                          TablerIcons.alert_circle,
                          color: Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _voucherError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                        Text(
                          format.format(cartState.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (cartState.discountAmount > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Diskon Voucher',
                            style: TextStyle(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          Text(
                            '- ${format.format(cartState.discountAmount)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Bayar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          format.format(cartState.totalAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  if (cartState.selectedTable != null) ...[
                    Expanded(
                      child: ShadButton.outline(
                        size: ShadButtonSize.lg,
                        onPressed: () async {
                          try {
                            await ref
                                .read(tableMonitoringProvider.notifier)
                                .saveOrderToTable(
                                  table: cartState.selectedTable!,
                                  items: cartState.items,
                                  totalAmount: cartState.totalAmount,
                                  discountTotal: cartState.discountAmount,
                                  voucherInfo: cartState.appliedVoucher
                                      ?.toMap(),
                                  activeTransactionId:
                                      cartState.activeTransactionId,
                                );
                            ref.invalidate(tableMonitoringProvider);
                            ref.read(cartNotifierProvider.notifier).clearCart();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ShadToaster.of(context).show(
                                const ShadToast(
                                  title: Text('Pesanan Disimpan'),
                                  description: Text(
                                    'Pesanan berhasil disimpan ke meja.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ShadToaster.of(context).show(
                                ShadToast.destructive(
                                  title: const Text('Gagal Menyimpan'),
                                  description: Text(e.toString()),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Simpan ke Meja'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ShadButton(
                      size: ShadButtonSize.lg,
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/payment');
                      },
                      child: const Text(
                        'Lanjut Pembayaran',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
