import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:flutter/services.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/providers/sync_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:isar/isar.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
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
          l10n.payment,
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
              l10n.paymentMethod,
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
                l10n.cashReceived,
                style: theme.textTheme.large.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              ShadInput(
                controller: _cashController,
                keyboardType: TextInputType.number,
                placeholder: Text(l10n.enterAmount),
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
                      l10n.confirmAndSaveTransaction,
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
            AppLocalizations.of(context)!.totalBill,
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: _methodTile('Tunai', l10n.cash, TablerIcons.cash)),
        const SizedBox(width: 12),
        Expanded(child: _methodTile('QRIS', 'QRIS', TablerIcons.qrcode)),
      ],
    );
  }

  Widget _methodTile(String method, String label, IconData icon) {
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
                label,
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
    final currentLocale = Localizations.localeOf(context).toString();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((val) {
        final formatted = NumberFormat.compactCurrency(
          locale: currentLocale,
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
                AppLocalizations.of(context)!.change,
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
                    ? AppLocalizations.of(context)!.insufficientCash
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
    final l10n = AppLocalizations.of(context)!;
    final cash = double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
    if (_paymentMethod == 'Tunai' && cash < totalAmount) {
      mySnackBar(
        context: context,
        text: l10n.cashNotSufficient,
        status: ToastStatus.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Ambil Store ID dari provider yang sudah ada
      final activeStore = ref.read(activeStoreProvider).value;
      final storeId = activeStore?['id'];

      if (storeId == null) {
        throw l10n.activeStoreNotFound;
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

      final transactionId = cartState.activeTransactionId ?? const Uuid().v4();

      final transactionLocal = TransactionLocal(
        supabaseId: transactionId,
        storeId: storeId.toString(),
        cashierId: supabase.auth.currentUser?.id ?? '',
        totalAmount: totalAmount,
        paymentMethod: _paymentMethod,
        cashPaid: _paymentMethod == 'Tunai' ? cash : totalAmount,
        changeAmount: _paymentMethod == 'Tunai' ? cash - totalAmount : 0,
        status: 'Berhasil',
        tableId: cartState.selectedTable?.id,
        discountTotal: cartState.discountAmount,
        voucherInfo: cartState.appliedVoucher != null
            ? jsonEncode(cartState.appliedVoucher!.toMap())
            : null,
        createdAt: DateTime.now(),
        isSynced: false,
      );

      final localItems = cartState.items.map((item) => TransactionItemLocal(
        transactionSupabaseId: transactionId,
        productId: item.product.supabaseId,
        productName: item.product.name,
        unitPrice: item.product.price,
        quantity: item.quantity,
        subtotal: item.subtotal,
      )).toList();

      // 1. Simpan Transaksi dan Item secara lokal di Isar
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.collection<TransactionLocal>().put(transactionLocal);
        for (var item in localItems) {
          await isar.collection<TransactionItemLocal>().put(item);
        }

        // 2. Kurangi stok produk secara lokal
        for (var item in cartState.items) {
          final localProd = await isar.collection<Product>().filter().supabaseIdEqualTo(item.product.supabaseId).findFirst();
          if (localProd != null) {
            localProd.stockQuantity = localProd.stockQuantity - item.quantity;
            await isar.collection<Product>().put(localProd);
          }
        }
      });

      // 3. Coba sinkronisasi langsung jika online
      bool syncedSuccessfully = false;
      final connectivity = ref.read(connectivityNotifierProvider).value;
      if (connectivity == ConnectivityStatus.online) {
        try {
          await ref.read(syncNotifierProvider.notifier).syncUnsynced();
          
          final updatedTx = await isar.collection<TransactionLocal>().filter().supabaseIdEqualTo(transactionId).findFirst();
          if (updatedTx != null && updatedTx.isSynced) {
            syncedSuccessfully = true;
          }
        } catch (e) {
          print('DEBUG: Immediate sync failed, it will retry in background: $e');
        }
      }

      // Konstruksi map transaksi untuk keperluan UI/Receipt tanpa fetch ulang
      final transactionMap = {
        'id': transactionId,
        'store_id': storeId,
        'cashier_id': supabase.auth.currentUser?.id ?? '',
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
        'created_at': transactionLocal.createdAt.toIso8601String(),
      };

      if (mounted) {
        HapticFeedback.heavyImpact();
        final currentLocale = Localizations.localeOf(context).toString();
        final currencyFormat = NumberFormat.currency(
          locale: currentLocale,
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        
        final String toastMsg = syncedSuccessfully
            ? l10n.transactionSynced(currencyFormat.format(totalAmount))
            : l10n.transactionSavedLocal(currencyFormat.format(totalAmount));

        mySnackBar(
          context: context,
          text: toastMsg,
          status: syncedSuccessfully ? ToastStatus.success : ToastStatus.warning,
        );

        if (cartState.selectedTable != null) {
          try {
            await ref
                .read(tableMonitoringProvider.notifier)
                .handleTableTransactionComplete(
                  tableId: cartState.selectedTable!.id,
                  paidItems: cartState.items,
                );
          } catch (e) {
            print('DEBUG: Table state remote update failed (offline): $e');
          }
        }
        ref.invalidate(tableMonitoringProvider);

        // Log transaction to Firebase Analytics
        final totalItemCount = cartState.items.fold<int>(0, (sum, item) => sum + item.quantity);
        await AnalyticsService.instance.logPurchase(
          transactionId: transactionId,
          totalAmount: totalAmount,
          paymentMethod: _paymentMethod,
          itemCount: totalItemCount,
        );

        ref.read(cartNotifierProvider.notifier).clearCart();
        _showSuccessDialog(transactionMap, itemsToProcess);
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.failedWithReason(e.toString()),
          status: ToastStatus.error,
        );
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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.paymentSuccess,
                style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        description: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            l10n.paymentSuccessDesc,
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
                  child: Text(l10n.toHistory),
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
                  child: Text(
                    l10n.viewReceipt,
                    style: const TextStyle(
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
