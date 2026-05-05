import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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
    final cartItems = ref.watch(cartNotifierProvider);
    final total = ref.read(cartNotifierProvider.notifier).totalAmount;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTotalCard(total, currencyFormat),
            const SizedBox(height: 24),
            const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildPaymentMethodSelector(),
            if (_paymentMethod == 'Tunai') ...[
              const SizedBox(height: 24),
              const Text('Uang Tunai Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _buildQuickCashButtons(total),
            ],
            const SizedBox(height: 32),
            _buildChangeSummary(total, currencyFormat),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _processPayment(total),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('Konfirmasi Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Warna.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Warna.primary),
      ),
      child: Column(
        children: [
          const Text('TOTAL TAGIHAN', style: TextStyle(letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(format.format(total), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
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
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Warna.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Warna.primary : Warna.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.grey),
            const SizedBox(height: 4),
            Text(method, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCashButtons(double total) {
    final suggestions = [total, 50000.0, 100000.0];
    return Wrap(
      spacing: 8,
      children: suggestions.map((val) => ActionChip(
        label: Text(NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ').format(val)),
        onPressed: () => setState(() => _cashController.text = val.toInt().toString()),
      )).toList(),
    );
  }

  Widget _buildChangeSummary(double total, NumberFormat format) {
    if (_paymentMethod != 'Tunai') return const SizedBox.shrink();
    
    final cash = double.tryParse(_cashController.text) ?? 0;
    final change = cash - total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Warna.neutral, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            change >= 0 ? format.format(change) : 'Uang Kurang',
            style: TextStyle(fontWeight: FontWeight.bold, color: change >= 0 ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(double totalAmount) async {
    final cash = double.tryParse(_cashController.text) ?? 0;
    if (_paymentMethod == 'Tunai' && cash < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang tunai tidak mencukupi')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final cartItems = ref.read(cartNotifierProvider);
      
      // 1. Ambil store_id & cashier_id
      final userData = await supabase.from('users').select('store_id').eq('id', supabase.auth.currentUser!.id).single();
      final storeId = userData['store_id'];

      // 2. Simpan Transaksi Utama
      final transaction = await supabase.from('transactions').insert({
        'store_id': storeId,
        'cashier_id': supabase.auth.currentUser!.id,
        'total_amount': totalAmount,
        'payment_method': _paymentMethod,
        'cash_paid': _paymentMethod == 'Tunai' ? cash : totalAmount,
        'change_amount': _paymentMethod == 'Tunai' ? cash - totalAmount : 0,
        'status': 'Berhasil',
      }).select().single();

      // 3. Simpan Item Transaksi
      final itemsToInsert = cartItems.map((item) => {
        'transaction_id': transaction['id'],
        'product_id': item.product.supabaseId,
        'product_name': item.product.name,
        'unit_price': item.product.price,
        'quantity': item.quantity,
        'subtotal': item.subtotal,
      }).toList();

      await supabase.from('transaction_items').insert(itemsToInsert);

      // 4. Potong Stok di Isar & Supabase (Opsional: Realtime akan handle sync balik)
      // Idealnya ada logic pengurangan stok di sini

      if (mounted) {
        ref.read(cartNotifierProvider.notifier).clearCart();
        _showSuccessDialog(transaction, itemsToInsert);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> transaction, List<Map<String, dynamic>> items) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(TablerIcons.circle_check, color: Colors.green, size: 64),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pembayaran Berhasil!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text('Transaksi telah disimpan ke sistem.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Ke Dashboard'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    context.push('/receipt', extra: {
                      'transaction': transaction,
                      'items': items,
                    });
                  },
                  child: const Text('Lihat Struk'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
