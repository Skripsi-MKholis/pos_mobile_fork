import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/models/customer_order_model.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class CustomerCheckoutPage extends ConsumerStatefulWidget {
  const CustomerCheckoutPage({
    super.key,
    this.prefilledTableNumber,
    this.prefilledNotes,
  });

  final String? prefilledTableNumber;
  final String? prefilledNotes;

  @override
  ConsumerState<CustomerCheckoutPage> createState() =>
      _CustomerCheckoutPageState();
}

class _CustomerCheckoutPageState extends ConsumerState<CustomerCheckoutPage> {
  late final TextEditingController _tableController;
  final _nameController = TextEditingController();
  late final TextEditingController _notesController;
  String _paymentMethod = 'pay_at_counter';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tableController = TextEditingController(text: widget.prefilledTableNumber ?? '');
    _notesController = TextEditingController(text: widget.prefilledNotes ?? '');
  }

  @override
  void dispose() {
    _tableController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final cartItems = ref.read(customerCartProvider);
    final storeId = ref.read(customerStoreIdProvider);

    if (storeId == null || storeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store belum dipilih. Scan QR toko dulu.'),
        ),
      );
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final itemsPayload = cartItems
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'badge': item.badge,
            },
          )
          .toList();
      final subtotal = cartItems.fold<double>(
        0,
        (sum, item) => sum + item.lineTotal,
      );
      final order = CustomerOrderModel(
        id: '',
        storeId: storeId,
        status: 'pending',
        tableNumber: _tableController.text.trim().isEmpty
            ? null
            : _tableController.text.trim(),
        customerName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: itemsPayload,
        subtotal: subtotal,
        totalAmount: subtotal,
        paymentMethod: _paymentMethod,
      );

      final response = await Supabase.instance.client
          .from('customer_orders')
          .insert(order.toInsertMap())
          .select()
          .single();
      final orderId = response['id']?.toString();

      ref.read(customerCartProvider.notifier).clear();

      if (!mounted) return;
      if (orderId == null || orderId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat.')),
        );
        return;
      }
      context.go('/customer/order/$orderId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(customerCartProvider);
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final storeId = ref.watch(customerStoreIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _Banner(
            title: storeId == null || storeId.isEmpty
                ? 'Store belum dipilih'
                : 'Store aktif',
            description: storeId == null || storeId.isEmpty
                ? 'Scan QR toko untuk melanjutkan checkout.'
                : storeId,
            icon: TablerIcons.credit_card,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Metode pembayaran',
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'pay_at_counter',
                  groupValue: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value!),
                  title: const Text('Bayar di Kasir'),
                ),
                RadioListTile<String>(
                  value: 'qris',
                  groupValue: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value!),
                  title: const Text('QRIS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Identitas pesanan',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama pemesan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tableController,
                  decoration: const InputDecoration(labelText: 'Nomor meja'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan pesanan',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Ringkasan',
            child: Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${item.name} x${item.quantity}')),
                        Text(_formatCurrency(item.lineTotal)),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatCurrency(subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitOrder,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(TablerIcons.check),
            label: Text(_isSubmitting ? 'Memproses...' : 'Konfirmasi Pesanan'),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  return 'Rp ${value.toStringAsFixed(0)}';
}
