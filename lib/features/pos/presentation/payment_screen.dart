import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:flutter/services.dart';

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
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Pembayaran',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: Colors.black),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTotalCard(total, currencyFormat),
            const SizedBox(height: 24),
            Text(
              'Metode Pembayaran',
              style: theme.textTheme.large.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodSelector(),
            if (_paymentMethod == 'Tunai') ...[
              const SizedBox(height: 24),
              Text(
                'Uang Tunai Diterima',
                style: theme.textTheme.large.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              ShadInput(
                controller: _cashController,
                keyboardType: TextInputType.number,
                placeholder: const Text('Masukkan jumlah uang...'),
                style: theme.textTheme.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Rp',
                    style: theme.textTheme.h3.copyWith(
                      color: theme.colorScheme.mutedForeground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                decoration: ShadDecoration(
                  border: ShadBorder.all(
                    color: theme.colorScheme.border.withOpacity(0.5),
                    width: 1,
                    radius: BorderRadius.circular(12),
                  ),
                  color: theme.colorScheme.muted.withOpacity(0.1),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _buildQuickCashButtons(total),
            ],
            const SizedBox(height: 24),
            _buildChangeSummary(total, currencyFormat),
            const SizedBox(height: 32),
            ShadButton(
              size: ShadButtonSize.lg,
              width: double.infinity,
              backgroundColor: Warna.primary,
              hoverBackgroundColor: Warna.primary.withOpacity(0.8),
              onPressed: _isLoading ? null : () => _processPayment(total),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Konfirmasi & Simpan Transaksi',
                      style: theme.textTheme.p.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total, NumberFormat format) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Warna.primary,
            Color(0xFF8CE000), // Slightly darker lime for dynamic gradient
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Warna.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL TAGIHAN',
            style: theme.textTheme.small.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            format.format(total),
            style: theme.textTheme.h2.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -1,
            ),
          ),
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
    final popController = PopController();

    return PopEffect(
      controller: popController,
      child: InkWell(
        onTap: () {
          popController.pop();
          setState(() => _paymentMethod = method);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Warna.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Warna.primary
                  : theme.colorScheme.border.withOpacity(0.5),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? Colors.black
                    : theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 8),
              Text(
                method,
                style: theme.textTheme.small.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.black
                      : theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashButtons(double total) {
    final suggestions = [total, 50000.0, 100000.0];
    final theme = ShadTheme.of(context);
    final currentCashText = _cashController.text;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((val) {
        final formatted = NumberFormat.compactCurrency(
          locale: 'id_ID',
          symbol: 'Rp ',
        ).format(val);
        final isSelected = currentCashText == val.toInt().toString();

        return GestureDetector(
          onTap: () =>
              setState(() => _cashController.text = val.toInt().toString()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Warna.primary.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Warna.primary
                    : theme.colorScheme.border.withOpacity(0.8),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              formatted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChangeSummary(double total, NumberFormat format) {
    if (_paymentMethod != 'Tunai') return const SizedBox.shrink();

    final cash = double.tryParse(_cashController.text) ?? 0;
    final change = cash - total;
    final isNegative = cash > 0 && change < 0;
    final isSufficient = cash > 0 && change >= 0;

    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: isNegative
            ? Warna.destructive.withOpacity(0.05)
            : (isSufficient
                  ? Warna.success.withOpacity(0.05)
                  : theme.colorScheme.muted.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNegative
              ? Warna.destructive
              : (isSufficient
                    ? Warna.success
                    : theme.colorScheme.border.withOpacity(0.5)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KEMBALIAN',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isNegative
                    ? 'Uang Kurang'
                    : (cash == 0 ? '-' : format.format(change)),
                style: theme.textTheme.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isNegative
                      ? Warna.destructive
                      : (isSufficient ? Warna.success : Colors.black),
                ),
              ),
            ],
          ),
          if (isSufficient)
            const Icon(TablerIcons.check, color: Warna.success, size: 24)
          else if (isNegative)
            const Icon(
              TablerIcons.alert_circle,
              color: Warna.destructive,
              size: 24,
            ),
        ],
      ),
    );
  }

  Future<void> _processPayment(double totalAmount) async {
    final cartState = ref.read(cartNotifierProvider);
    final cash = double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
    if (_paymentMethod == 'Tunai' && cash < totalAmount) {
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('Uang tunai tidak mencukupi')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Ambil Store ID dari provider yang sudah ada
      final activeStore = ref.read(activeStoreProvider).value;
      final storeId = activeStore?['id'];

      if (storeId == null) {
        throw 'Toko aktif tidak ditemukan. Silakan pilih toko terlebih dahulu.';
      }

      final itemsToProcess = cartState.items
          .map(
            (item) => {
              'product_id': item.product.supabaseId,
              'product_name': item.product.name,
              'unit_price': item.product.price,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
            },
          )
          .toList();

      // Gunakan RPC untuk memproses transaksi
      dynamic response;

      if (cartState.activeTransactionId != null) {
        // 1. Sync items first to ensure any last-minute changes are saved
        final syncResponse = await supabase.rpc(
          'sync_pending_transaction',
          params: {
            'p_transaction_id': cartState.activeTransactionId,
            'p_items': itemsToProcess,
            'p_total_amount': totalAmount,
            'p_discount_total': cartState.discountAmount,
            'p_voucher_info': cartState.appliedVoucher != null
                ? cartState.appliedVoucher!.toMap()
                : {},
          },
        );

        if (syncResponse == null ||
            (syncResponse is Map && syncResponse['success'] == false)) {
          throw syncResponse?['error'] ??
              'Gagal memperbarui data pesanan sebelum pembayaran.';
        }

        // 2. Complete the pending transaction
        response = await supabase.rpc(
          'complete_pending_transaction',
          params: {
            'p_transaction_id': cartState.activeTransactionId,
            'p_payment_method': _paymentMethod,
            'p_cash_paid': _paymentMethod == 'Tunai' ? cash : totalAmount,
            'p_change_amount': _paymentMethod == 'Tunai'
                ? cash - totalAmount
                : 0,
          },
        );

        // Add transaction_id to response for consistency with create_transaction_v3
        if (response != null && response is Map) {
          response['transaction_id'] = cartState.activeTransactionId;
        }
      } else {
        // Normal flow for new transaction
        response = await supabase.rpc(
          'create_transaction_v3',
          params: {
            'p_store_id': storeId,
            'p_cashier_id': supabase.auth.currentUser!.id,
            'p_total_amount': totalAmount,
            'p_payment_method': _paymentMethod,
            'p_discount_total': cartState.discountAmount,
            'p_voucher_info': cartState.appliedVoucher != null
                ? cartState.appliedVoucher!.toMap()
                : {},
            'p_table_id': cartState.selectedTable?.id,
            'p_items': itemsToProcess,
            'p_status': 'Berhasil',
            'p_cash_paid': _paymentMethod == 'Tunai' ? cash : totalAmount,
            'p_change_amount': _paymentMethod == 'Tunai'
                ? cash - totalAmount
                : 0,
          },
        );
      }

      if (response == null ||
          (response is Map && response['success'] == false)) {
        throw response?['error'] ??
            'Terjadi kesalahan saat memproses transaksi.';
      }

      final transactionId = response['transaction_id'];

      // Konstruksi map transaksi untuk keperluan UI/Receipt tanpa fetch ulang
      final transactionMap = {
        'id': transactionId,
        'store_id': storeId,
        'cashier_id': supabase.auth.currentUser!.id,
        'total_amount': totalAmount,
        'payment_method': _paymentMethod,
        'cash_paid': _paymentMethod == 'Tunai' ? cash : totalAmount,
        'change_amount': _paymentMethod == 'Tunai' ? cash - totalAmount : 0,
        'status': 'Berhasil',
        'table_id': cartState.selectedTable?.id,
        'discount_total': cartState.discountAmount,
        'voucher_info': cartState.appliedVoucher != null
            ? cartState.appliedVoucher!.toMap()
            : {},
        'created_at': DateTime.now().toIso8601String(),
      };

      if (mounted) {
        HapticFeedback.heavyImpact();
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Pembayaran Berhasil!'),
            description: Text('Transaksi senilai ${currencyFormat.format(totalAmount)} telah disimpan.'),
            duration: const Duration(seconds: 3),
          ),
        );
        if (cartState.selectedTable != null) {
          await ref
              .read(tableMonitoringProvider.notifier)
              .handleTableTransactionComplete(
                tableId: cartState.selectedTable!.id,
                paidItems: cartState.items,
              );
        }
        ref.invalidate(tableMonitoringProvider);
        ref.read(cartNotifierProvider.notifier).clearCart();
        _showSuccessDialog(transactionMap, itemsToProcess);
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(
          context,
        ).show(ShadToast.destructive(description: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(
    Map<String, dynamic> transaction,
    List<Map<String, dynamic>> items,
  ) {
    final theme = ShadTheme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShadDialog(
        title: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Warna.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.check,
                  color: Warna.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pembayaran Berhasil',
                style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        description: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Transaksi Anda telah berhasil dicatat ke sistem. Silakan pilih langkah selanjutnya.',
            textAlign: TextAlign.center,
            style: theme.textTheme.muted,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('Ke Riwayat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadButton(
                  backgroundColor: Warna.primary,
                  hoverBackgroundColor: Warna.primary.withOpacity(0.8),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(
                      '/receipt',
                      extra: {
                        'transaction': transaction,
                        'items': items,
                        'autoPrint': true,
                      },
                    );
                  },
                  child: const Text(
                    'Lihat Struk',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
