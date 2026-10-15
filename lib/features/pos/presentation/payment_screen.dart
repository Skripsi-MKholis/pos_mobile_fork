import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/core/widgets/pop_effect.dart';
import 'package:pos_mobile/features/pos/models/cart_item.dart';
import 'package:pos_mobile/features/pos/models/cart_state.dart';
import 'package:pos_mobile/features/pos/providers/cart_provider.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:flutter/services.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/stock_history.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/providers/sync_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:pos_mobile/core/guards/feature_guard.dart';
import 'package:pos_mobile/features/settings/providers/subscription_provider.dart';
import 'package:pos_mobile/features/product/providers/stock_history_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final TextEditingController _cashController = TextEditingController();
  String _paymentMethod = 'Tunai';
  bool _isLoading = false;
  bool _isOrderSummaryExpanded = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setCashAmount(num amount) {
    HapticFeedback.lightImpact();
    setState(() {
      _cashController.text = amount.toInt().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final total = ref.watch(cartNotifierProvider.notifier).totalAmount;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final theme = ShadTheme.of(context);

    final cash = double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
    final isCashMethod = _paymentMethod == 'Tunai';
    final isCashSufficient = !isCashMethod || (cash >= total);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          l10n.payment,
          style: theme.textTheme.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTotalHeroCard(total, currencyFormat, cartState),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      title: l10n.paymentMethod,
                      icon: TablerIcons.wallet,
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodSelector(),
                    if (isCashMethod) ...[
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        title: l10n.cashReceived,
                        icon: TablerIcons.cash,
                      ),
                      const SizedBox(height: 10),
                      _buildCashInputField(theme, l10n),
                      const SizedBox(height: 12),
                      _buildQuickCashButtons(total),
                      const SizedBox(height: 16),
                      _buildChangeSummary(total, currencyFormat),
                    ] else ...[
                      const SizedBox(height: 20),
                      _buildQrisInfoCard(theme),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomBar(total, isCashSufficient, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalHeroCard(double total, NumberFormat format, CartState cartState) {
    final theme = ShadTheme.of(context);
    final itemCount = cartState.items.fold<int>(0, (int sum, CartItem item) => sum + item.quantity);
    final tableName = cartState.selectedTable?.name;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bagian Atas: Gradient Hero Accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9AE600), Color(0xFF82D600)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.totalBill,
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withOpacity(0.65),
                              fontSize: 11,
                            ),
                          ),
                          if (tableName != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(TablerIcons.armchair, size: 12, color: Colors.black87),
                                  const SizedBox(width: 4),
                                  Text(
                                    tableName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          format.format(total),
                          style: theme.textTheme.h2.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(TablerIcons.shopping_bag, size: 14, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(
                        '$itemCount item',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bagian Bawah: Ringkasan Rincian Item (Collapsible)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isOrderSummaryExpanded = !_isOrderSummaryExpanded;
                });
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isOrderSummaryExpanded ? TablerIcons.chevron_up : TablerIcons.receipt,
                          size: 16,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isOrderSummaryExpanded
                              ? 'Sembunyikan Rincian'
                              : 'Lihat Rincian Pesanan (${cartState.items.length} produk)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _isOrderSummaryExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                      size: 16,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isOrderSummaryExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                itemCount: cartState.items.length,
                separatorBuilder: (_, _) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = cartState.items[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x  ${item.product.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        format.format(item.subtotal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _methodTile(
            method: 'Tunai',
            label: l10n.cash,
            description: 'Bayar dengan uang cash',
            icon: TablerIcons.cash,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _methodTile(
            method: 'QRIS',
            label: 'QRIS',
            description: 'GoPay, OVO, Dana, dll',
            icon: TablerIcons.qrcode,
          ),
        ),
      ],
    );
  }

  Widget _methodTile({
    required String method,
    required String label,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == method;
    final popController = PopController();

    return PopEffect(
      controller: popController,
      child: InkWell(
        onTap: () {
          popController.pop();
          HapticFeedback.selectionClick();
          setState(() => _paymentMethod = method);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF9AE600).withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF9AE600) : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF9AE600).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF9AE600) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.black : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.black : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.black87 : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  TablerIcons.circle_check_filled,
                  size: 18,
                  color: Color(0xFF65A30D),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashInputField(ShadThemeData theme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          ShadInput(
            controller: _cashController,
            keyboardType: TextInputType.number,
            placeholder: Text(l10n.enterAmount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontSize: 22,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            trailing: _cashController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(TablerIcons.circle_x_filled, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _cashController.clear());
                    },
                  )
                : null,
            decoration: const ShadDecoration(
              border: ShadBorder.none,
              color: Colors.transparent,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCashButtons(double total) {
    final currentCash = double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
    final currentLocale = Localizations.localeOf(context).toString();

    // Nilai nominal uang umum yang relevan (selalu include uang pas & kelipatan 50k, 100k yang lebih besar dari total)
    final Set<double> suggestionSet = {total};
    if (total <= 50000) suggestionSet.add(50000.0);
    if (total <= 100000) suggestionSet.add(100000.0);
    if (total <= 200000) suggestionSet.add(200000.0);
    if (total > 100000) {
      final next50k = (total / 50000).ceil() * 50000.0;
      suggestionSet.add(next50k);
      suggestionSet.add(next50k + 50000.0);
    }

    final suggestions = suggestionSet.toList()..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((val) {
        final isExact = val == total;
        final formatted = isExact
            ? 'Uang Pas'
            : NumberFormat.compactCurrency(
                locale: currentLocale,
                symbol: 'Rp ',
              ).format(val);
        final isSelected = currentCash.toInt() == val.toInt();

        return InkWell(
          onTap: () => _setCashAmount(val),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF9AE600)
                  : (isExact ? const Color(0xFFF1F5F9) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF9AE600)
                    : (isExact ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExact) ...[
                  Icon(
                    TablerIcons.sparkles,
                    size: 13,
                    color: isSelected ? Colors.black : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  formatted,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.black : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChangeSummary(double total, NumberFormat format) {
    if (_paymentMethod != 'Tunai') return const SizedBox.shrink();

    final cash = double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
    final change = cash - total;
    final isNegative = cash > 0 && change < 0;

    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String statusLabel;

    if (cash == 0) {
      bg = Colors.white;
      border = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF94A3B8);
      icon = TablerIcons.calculator;
      statusLabel = 'Menunggu input tunai';
    } else if (isNegative) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECDD3);
      textColor = const Color(0xFFE11D48);
      icon = TablerIcons.alert_circle;
      statusLabel = 'Uang Kurang ${format.format(change.abs())}';
    } else {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF16A34A);
      icon = TablerIcons.check;
      statusLabel = change == 0 ? 'Pas (Tanpa Kembalian)' : 'Kembalian Siap Diberikan';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.change.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isNegative
                    ? AppLocalizations.of(context)!.insufficientCash
                    : (cash == 0 ? 'Rp 0' : format.format(change)),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.85),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisInfoCard(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.qrcode, size: 40, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pembayaran Non-Tunai (QRIS)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Setelah menekan tombol konfirmasi, transaksi akan dicatat lunas secara instan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double total, bool isCashSufficient, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ShadButton(
        size: ShadButtonSize.lg,
        width: double.infinity,
        backgroundColor: const Color(0xFF9AE600),
        hoverBackgroundColor: const Color(0xFF8AE000),
        enabled: !_isLoading && isCashSufficient,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(TablerIcons.check, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.confirmAndSaveTransaction,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
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

    // Cek kuota transaksi bulanan berdasarkan paket langganan aktif
    final subInfo = ref.read(currentSubscriptionProvider).value;
    if (subInfo != null && subInfo.maxTransactions > 0) {
      final monthlyCount = ref.read(monthlyTransactionCountProvider).value ?? 0;
      if (monthlyCount >= subInfo.maxTransactions) {
        if (!mounted) return;
        showQuotaExceededDialog(
          context,
          title: l10n.quotaExceededTitle,
          message: l10n.quotaExceededDesc(subInfo.maxTransactions, subInfo.planName),
          currentLimit: l10n.monthlyTransactionsLimit(subInfo.maxTransactions),
        );
        return;
      }
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

        // 2. Kurangi stok produk secara lokal dan catat riwayat stok
        final cashierId = supabase.auth.currentUser?.id;
        for (var item in cartState.items) {
          final localProd = await isar.collection<Product>().filter().supabaseIdEqualTo(item.product.supabaseId).findFirst();
          if (localProd != null) {
            final oldStock = localProd.stockQuantity;
            final newStock = oldStock - item.quantity;
            localProd.stockQuantity = newStock;
            await isar.collection<Product>().put(localProd);

            final history = StockHistoryLocal(
              supabaseId: const Uuid().v4(),
              storeId: storeId.toString(),
              productId: item.product.supabaseId,
              productName: item.product.name,
              changeType: 'sale',
              quantityChange: -item.quantity,
              oldStock: oldStock,
              newStock: newStock,
              referenceId: transactionId,
              cashierId: cashierId,
              createdAt: DateTime.now(),
              isSynced: false,
            );
            await isar.collection<StockHistoryLocal>().put(history);
          }
        }
      });

      // 3. Coba sinkronisasi langsung jika online
      bool syncedSuccessfully = false;
      TransactionLocal? updatedTx;
      final connectivity = ref.read(connectivityNotifierProvider).value;
      if (connectivity == ConnectivityStatus.online) {
        try {
          await ref.read(syncNotifierProvider.notifier).syncUnsynced();
        } catch (e) {
          print('DEBUG: Immediate sync failed, it will retry in background: $e');
        }

        updatedTx = await isar.collection<TransactionLocal>().filter().supabaseIdEqualTo(transactionId).findFirst();
        if (updatedTx != null && updatedTx.isSynced) {
          syncedSuccessfully = true;
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
            : (updatedTx?.syncError != null
                ? '${l10n.transactionSavedLocal(currencyFormat.format(totalAmount))} (${updatedTx!.syncError})'
                : l10n.transactionSavedLocal(currencyFormat.format(totalAmount)));

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
        ref.invalidate(stockHistoryProvider);
        ref.invalidate(productNotifierProvider);

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
