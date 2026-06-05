import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
  String _paymentMethod = 'pay_at_counter'; // Mapped to 'Tunai' or 'QRIS'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill table number from route parameter or active customer table session
    final prefilledTable = widget.prefilledTableNumber ?? ref.read(customerTableNameProvider) ?? '';
    _tableController = TextEditingController(text: prefilledTable);
    _notesController = TextEditingController(text: widget.prefilledNotes ?? '');
  }

  @override
  void dispose() {
    _tableController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(double totalAmount) async {
    final cartItems = ref.read(customerCartProvider);
    final storeId = ref.read(customerStoreIdProvider);
    final tableId = ref.read(customerTableIdProvider);

    if (storeId == null || storeId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toko tidak terdeteksi. Silakan scan QR toko terlebih dahulu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (cartItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan item ke keranjang sebelum melanjutkan.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final nameStr = _nameController.text.trim();

      // 1. Retrieve or create customer record in public.customers
      String? customerId;
      if (nameStr.isNotEmpty) {
        try {
          final existing = await supabase
              .from('customers')
              .select('id')
              .eq('store_id', storeId)
              .eq('name', nameStr)
              .maybeSingle();

          if (existing != null) {
            customerId = existing['id'] as String;
          } else {
            final newCust = await supabase
                .from('customers')
                .insert({
                  'store_id': storeId,
                  'name': nameStr,
                  'email': user?.email,
                })
                .select('id')
                .single();
            customerId = newCust['id'] as String;
          }
        } catch (e) {
          debugPrint('Failed to handle customer record creation: $e');
        }
      }

      // 2. Insert order into public.transactions
      final transactionResponse = await supabase
          .from('transactions')
          .insert({
            'store_id': storeId,
            'table_id': tableId,
            'total_amount': totalAmount,
            'payment_method': _paymentMethod == 'qris' ? 'QRIS' : 'Tunai',
            'status': 'Pending',
            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            'customer_id': customerId,
            'discount_total': 0.0,
            'voucher_info': {},
          })
          .select('id')
          .single();

      final transactionId = transactionResponse['id'] as String;

      // 3. Insert transaction items into public.transaction_items
      final List<Map<String, dynamic>> itemsPayload = cartItems.map((item) {
        return {
          'transaction_id': transactionId,
          'product_id': item.id,
          'product_name': item.name,
          'unit_price': item.price,
          'quantity': item.quantity,
          'subtotal': item.lineTotal,
          'status': 'Pending',
        };
      }).toList();

      await supabase.from('transaction_items').insert(itemsPayload);

      // 4. Clear local cart
      ref.read(customerCartProvider.notifier).clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemesanan Berhasil! Pesanan Anda sedang diproses.'),
          backgroundColor: Colors.green,
        ),
      );

      // Redirect to Order Tracking screen
      context.go('/customer/order/$transactionId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final tableId = ref.watch(customerTableIdProvider);

    // Watch store settings for dynamic tax and service charge
    final storeDetailsAsync = ref.watch(customerStoreDetailsProvider);
    final storeDetails = storeDetailsAsync.value;
    final storeName = storeDetails?['name'] ?? 'Toko';

    final settings = storeDetails?['settings'] as Map<String, dynamic>?;
    final financial = settings?['financial'] as Map<String, dynamic>?;

    final taxEnabled = financial?['tax_enabled'] ?? false;
    final taxRate = (financial?['tax_rate'] ?? 0).toDouble();

    final serviceChargeEnabled = financial?['service_charge_enabled'] ?? false;
    final serviceChargeRate = (financial?['service_charge_rate'] ?? 0).toDouble();

    // Financial calculations
    final serviceCharge = serviceChargeEnabled ? (subtotal * serviceChargeRate / 100.0) : 0.0;
    final tax = taxEnabled ? (subtotal * taxRate / 100.0) : 0.0;
    final totalAmount = subtotal + serviceCharge + tax;

    final isTableDisabled = tableId != null && tableId.isNotEmpty;

    // Listen to user profile provider to prefill customer name
    ref.listen<AsyncValue<Map<String, dynamic>?>>(userProfileProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        final profile = next.value!;
        final fullName = profile['full_name'] as String?;
        if (fullName != null && _nameController.text.isEmpty) {
          _nameController.text = fullName;
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Store Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Warna.primary.withOpacity(0.12), Warna.primary.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Warna.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(TablerIcons.building_store, color: Warna.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        storeId != null && storeId.isNotEmpty ? 'ID: ${storeId.substring(0, 8)}...' : 'Store belum dipilih',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Methods
          _Section(
            title: 'Metode Pembayaran',
            child: Column(
              children: [
                _buildPaymentOption(
                  id: 'pay_at_counter',
                  title: 'Bayar di Kasir',
                  subtitle: 'Bayar tunai atau kartu langsung di konter',
                  icon: TablerIcons.wallet,
                ),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  id: 'qris',
                  title: 'QRIS',
                  subtitle: 'Scan kode QRIS menggunakan e-wallet Anda',
                  icon: TablerIcons.qrcode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Customer Info Form
          _Section(
            title: 'Identitas Pesanan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Pemesan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ShadInput(
                  controller: _nameController,
                  placeholder: const Text('Masukkan nama Anda'),
                  leading: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(TablerIcons.user, size: 18, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Nomor Meja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ShadInput(
                  controller: _tableController,
                  readOnly: isTableDisabled,
                  placeholder: const Text('Contoh: Meja 12'),
                  leading: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(TablerIcons.table_alias, size: 18, color: Colors.grey),
                  ),
                ),
                if (isTableDisabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      '* Diisi otomatis dari pindaian meja QR Anda',
                      style: TextStyle(
                        fontSize: 11,
                        color: Warna.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text('Catatan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ShadInput(
                  controller: _notesController,
                  placeholder: const Text('Tulis catatan khusus (contoh: pedas, es dipisah)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cart Billing Summary
          _Section(
            title: 'Ringkasan Belanja',
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ),
                        Text(
                          _formatCurrency(item.lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                    Text(_formatCurrency(subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (serviceChargeEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Biaya Layanan (${serviceChargeRate.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey)),
                      Text(_formatCurrency(serviceCharge), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                if (taxEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pajak (${taxRate.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey)),
                      Text(_formatCurrency(tax), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      _formatCurrency(totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Warna.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm Order Button
          ShadButton(
            size: ShadButtonSize.lg,
            backgroundColor: Warna.primary,
            onPressed: _isSubmitting ? null : () => _submitOrder(totalAmount),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Warna.black)),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(TablerIcons.square_rounded_check, color: Warna.black, size: 20),
                  ),
                Text(
                  _isSubmitting ? 'Memproses Pesanan...' : 'Konfirmasi Pesanan',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Warna.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Warna.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Warna.primary : Colors.black.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Warna.primary.withOpacity(0.16) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Warna.primary : Colors.grey.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Warna.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(TablerIcons.circle_check_filled, color: Warna.primary)
            else
              Icon(TablerIcons.circle, color: Colors.grey.shade300),
          ],
        ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.3),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  return 'Rp ${value.toStringAsFixed(0)}';
}
