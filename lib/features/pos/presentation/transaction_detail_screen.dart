import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> transaction;
  final List<dynamic> items;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();

    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy \u2022 HH:mm', currentLocale);

    final txId = (transaction['id'] ?? '').toString();
    final shortId = txId.length > 8
        ? txId.substring(0, 8).toUpperCase()
        : txId.toUpperCase();
    final status = (transaction['status'] ?? 'Berhasil').toString();
    final isSuccess =
        status.toLowerCase() == 'berhasil' || status.toLowerCase() == 'success';
    final isPending = status.toLowerCase() == 'pending';

    final paymentMethodRaw = (transaction['payment_method'] ?? 'Tunai')
        .toString();
    final paymentMethod = paymentMethodRaw.toLowerCase() == 'tunai'
        ? l10n.cash
        : paymentMethodRaw;

    final totalAmount =
        (transaction['total_amount'] as num?)?.toDouble() ?? 0.0;
    final cashPaid =
        (transaction['cash_paid'] as num?)?.toDouble() ?? totalAmount;
    final changeAmount =
        (transaction['change_amount'] as num?)?.toDouble() ?? 0.0;
    final discountTotal =
        (transaction['discount_total'] as num?)?.toDouble() ?? 0.0;

    final createdAtStr = transaction['created_at']?.toString();
    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr)?.toLocal()
        : null;

    final activeStore = ref.watch(activeStoreProvider).value;
    final storeName = activeStore?['name']?.toString() ?? 'Toko';

    final totalQty = items.fold<int>(0, (sum, it) {
      final q = (it['quantity'] as num?)?.toInt() ?? 1;
      return sum + q;
    });

    final subtotalBeforeDiscount = items.fold<double>(0.0, (sum, it) {
      final sub = (it['subtotal'] as num?)?.toDouble() ?? 0.0;
      return sum + sub;
    });

    return Scaffold(
      backgroundColor: isDark ? Warna.darkBG : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Warna.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            TablerIcons.arrow_left,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.transactionDetail,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.copyTransactionId,
            icon: Icon(
              TablerIcons.copy,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: txId));
              mySnackBar(
                context: context,
                text: l10n.transactionIdCopied,
                status: ToastStatus.success,
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Warna.darkLine : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Hero Status & Nominal Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? Warna.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Warna.darkLine : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : (isPending
                                ? Colors.orange.withOpacity(0.12)
                                : Colors.red.withOpacity(0.12)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess
                          ? TablerIcons.check
                          : (isPending
                                ? TablerIcons.clock
                                : TablerIcons.alert_circle),
                      size: 26,
                      color: isSuccess
                          ? const Color(0xFF10B981)
                          : (isPending ? Colors.orange : Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : (isPending
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSuccess
                          ? l10n.success
                          : (isPending ? l10n.pending : l10n.cancelled),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSuccess
                            ? const Color(0xFF10B981)
                            : (isPending ? Colors.orange : Colors.red),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.totalPayment,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalAmount),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ID: #$shortId',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Transaksi Card
            _buildSectionCard(
              context: context,
              title: l10n.transactionInfo,
              icon: TablerIcons.receipt,
              isDark: isDark,
              theme: theme,
              child: Column(
                children: [
                  _buildDetailRow(
                    label: l10n.store,
                    value: storeName,
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: l10n.transactionTime,
                    value: createdAt != null
                        ? dateFormat.format(createdAt)
                        : '-',
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: l10n.paymentMethod,
                    value: paymentMethod,
                    theme: theme,
                    isDark: isDark,
                    trailingBadge: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Warna.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        paymentMethod,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4D7C0F),
                        ),
                      ),
                    ),
                  ),
                  if (transaction['table_id'] != null &&
                      transaction['table_id'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      label: l10n.table,
                      value: transaction['table_id'].toString(),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Item Pesanan Card
            _buildSectionCard(
              context: context,
              title: l10n.orderItemsBreakdown(totalQty),
              icon: TablerIcons.shopping_bag,
              isDark: isDark,
              theme: theme,
              child: Column(
                children: [
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.noItemsBreakdown,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    )
                  else
                    ...items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final productName = (item['product_name'] ?? 'Produk')
                          .toString();
                      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                      final unitPrice =
                          (item['unit_price'] as num?)?.toDouble() ?? 0.0;
                      final subtotal =
                          (item['subtotal'] as num?)?.toDouble() ??
                          (qty * unitPrice);
                      final isLast = idx == items.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF262626)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.mutedForeground,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$qty x ${currencyFormat.format(unitPrice)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              theme.colorScheme.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currencyFormat.format(subtotal),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: isDark
                                  ? Warna.darkLine
                                  : const Color(0xFFF1F5F9),
                            ),
                        ],
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rincian Pembayaran Card
            _buildSectionCard(
              context: context,
              title: l10n.paymentBreakdown,
              icon: TablerIcons.wallet,
              isDark: isDark,
              theme: theme,
              child: Column(
                children: [
                  _buildDetailRow(
                    label: l10n.productSubtotal,
                    value: currencyFormat.format(
                      subtotalBeforeDiscount > 0
                          ? subtotalBeforeDiscount
                          : totalAmount,
                    ),
                    theme: theme,
                    isDark: isDark,
                  ),
                  if (discountTotal > 0) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      label: l10n.discountCut,
                      value: '- ${currencyFormat.format(discountTotal)}',
                      theme: theme,
                      isDark: isDark,
                      valueColor: Colors.red,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark ? Warna.darkLine : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    label: l10n.totalBelanja,
                    value: currencyFormat.format(totalAmount),
                    theme: theme,
                    isDark: isDark,
                    isBold: true,
                    fontSize: 15,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: l10n.amountPaid,
                    value: currencyFormat.format(cashPaid),
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: l10n.change,
                    value: currencyFormat.format(changeAmount),
                    theme: theme,
                    isDark: isDark,
                    valueColor: isSuccess ? const Color(0xFF10B981) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? Warna.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Warna.darkLine : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? Warna.darkLine
                            : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: txId));
                      mySnackBar(
                        context: context,
                        text: l10n.transactionIdCopied,
                        status: ToastStatus.success,
                      );
                    },
                    icon: Icon(
                      TablerIcons.copy,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    label: Text(
                      l10n.copy,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Warna.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      context.push(
                        '/receipt',
                        extra: {
                          'transaction': transaction,
                          'items': items,
                          'autoPrint': false,
                        },
                      );
                    },
                    icon: const Icon(TablerIcons.receipt, size: 18),
                    label: Text(
                      l10n.viewReceipt,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
    required ShadThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Warna.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Warna.darkLine : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Warna.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required ShadThemeData theme,
    required bool isDark,
    Widget? trailingBadge,
    Color? valueColor,
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        if (trailingBadge != null)
          trailingBadge
        else
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
      ],
    );
  }
}
