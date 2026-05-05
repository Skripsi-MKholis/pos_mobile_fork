import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final TextEditingController _cashController = TextEditingController();
  String _paymentMethod = 'Tunai';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final total = ref.read(cartNotifierProvider.notifier).totalAmount;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/pos');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTotalCard(total, currencyFormat),
            const SizedBox(height: 32),
            const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildPaymentMethodSelector(),
            if (_paymentMethod == 'Tunai') ...[
              const SizedBox(height: 32),
              const Text('Uang Tunai Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ShadInput(
                controller: _cashController,
                keyboardType: TextInputType.number,
                placeholder: const Text('Masukkan jumlah uang...'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                leading: const Padding(padding: EdgeInsets.all(12), child: Text('Rp', style: TextStyle(fontSize: 18, color: Colors.grey))),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _buildQuickCashButtons(total),
            ],
            const SizedBox(height: 32),
            _buildChangeSummary(total, currencyFormat),
            const SizedBox(height: 40),
            ShadButton(
              size: ShadButtonSize.lg,
              onPressed: _isLoading ? null : () => _processPayment(total),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Konfirmasi & Simpan Transaksi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total, NumberFormat format) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      backgroundColor: theme.colorScheme.muted,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text('TOTAL TAGIHAN', style: TextStyle(letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 12),
          Text(format.format(total), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Row(
      children: [
        Expanded(child: _methodTile('Tunai', TablerIcons.cash)),
        const SizedBox(width: 12),
        Expanded(child: _methodTile('QRIS', TablerIcons.qrcode)),
      ],
    );
  }

  Widget _methodTile(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    final theme = ShadTheme.of(context);
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      child: ShadCard(
        backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.card,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground),
            const SizedBox(height: 8),
            Text(method, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCashButtons(double total) {
    final suggestions = [total, 50000.0, 100000.0];
    return Wrap(
      spacing: 8,
      children: suggestions.map((val) => ShadButton.outline(
        onPressed: () => setState(() => _cashController.text = val.toInt().toString()),
        child: Text(NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ').format(val)),
      )).toList(),
    );
  }

  Widget _buildChangeSummary(double total, NumberFormat format) {
    if (_paymentMethod != 'Tunai') return const SizedBox.shrink();
    
    final cash = double.tryParse(_cashController.text) ?? 0;
    final change = cash - total;

    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: change >= 0 ? theme.colorScheme.muted : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: change >= 0 ? theme.colorScheme.border : Colors.red.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            change >= 0 ? format.format(change) : 'Uang Kurang',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: change >= 0 ? Colors.green.shade700 : Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(double totalAmount) async {
    final cash = double.tryParse(_cashController.text) ?? 0;
    if (_paymentMethod == 'Tunai' && cash < totalAmount) {
      ShadToaster.of(context).show(const ShadToast(description: Text('Uang tunai tidak mencukupi')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final cartState = ref.read(cartNotifierProvider);
      
      final userData = await supabase.from('users').select('store_id').eq('id', supabase.auth.currentUser!.id).single();
      final storeId = userData['store_id'];

      final transaction = await supabase.from('transactions').insert({
        'store_id': storeId,
        'cashier_id': supabase.auth.currentUser!.id,
        'total_amount': totalAmount,
        'payment_method': _paymentMethod,
        'cash_paid': _paymentMethod == 'Tunai' ? cash : totalAmount,
        'change_amount': _paymentMethod == 'Tunai' ? cash - totalAmount : 0,
        'status': 'Berhasil',
        'table_id': cartState.selectedTable?.id,
        'discount_total': cartState.discountAmount,
        'voucher_info': cartState.appliedVoucher != null ? cartState.appliedVoucher!.toMap() : {},
      }).select().single();

      final itemsToInsert = cartState.items.map((item) => {
        'transaction_id': transaction['id'],
        'product_id': item.product.supabaseId,
        'product_name': item.product.name,
        'unit_price': item.product.price,
        'quantity': item.quantity,
        'subtotal': item.subtotal,
      }).toList();

      await supabase.from('transaction_items').insert(itemsToInsert);

      if (mounted) {
        ref.read(cartNotifierProvider.notifier).clearCart();
        _showSuccessDialog(transaction, itemsToInsert);
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> transaction, List<Map<String, dynamic>> items) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShadDialog(
        title: const Text('Pembayaran Berhasil'),
        description: const Text('Transaksi Anda telah berhasil dicatat ke sistem.'),
        actions: [
          ShadButton.outline(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Ke Dashboard'),
          ),
          ShadButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/receipt', extra: {
                'transaction': transaction,
                'items': items,
              });
            },
            child: const Text('Lihat Struk'),
          ),
        ],
      ),
    );
  }
}
