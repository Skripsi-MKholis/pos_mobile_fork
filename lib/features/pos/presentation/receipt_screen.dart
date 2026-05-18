import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/pos/providers/printer_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptScreen extends ConsumerWidget {
  final Map<String, dynamic> transaction;
  final List<dynamic> items;

  const ReceiptScreen({
    super.key,
    required this.transaction,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final connectedPrinter = ref.watch(printerNotifierProvider);
    final theme = ShadTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/transactions');
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.muted,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.muted,
          elevation: 0,
          title: const Text(
            'Struk Digital',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(TablerIcons.chevron_left),
            onPressed: () => context.go(
              '/transactions',
            ), // After receipt, go to Riwayat Transaksi
          ),
          actions: [
            IconButton(
              icon: const Icon(TablerIcons.printer),
              onPressed: () => context.push('/printer-settings'),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ShadCard(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      children: [
                        Text('PARZELLO POS', style: theme.textTheme.h3),
                        const SizedBox(height: 4),
                        Text(
                          'Terima Kasih Telah Berbelanja',
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildRow(
                          'No. Transaksi',
                          '#${transaction['id'].toString().substring(0, 8).toUpperCase()}',
                        ),
                        _buildRow(
                          'Tanggal',
                          dateFormat.format(
                            DateTime.parse(transaction['created_at']),
                          ),
                        ),
                        _buildRow('Metode', transaction['payment_method']),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${item['quantity']} x ${currencyFormat.format(item['unit_price'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(item['subtotal']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildRow(
                          'Total Belanja',
                          currencyFormat.format(transaction['total_amount']),
                          isBold: true,
                        ),
                        _buildRow(
                          'Bayar',
                          currencyFormat.format(transaction['cash_paid']),
                        ),
                        _buildRow(
                          'Kembalian',
                          currencyFormat.format(transaction['change_amount']),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          '--- SELESAI ---',
                          style: theme.textTheme.muted.copyWith(
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShadButton.outline(
                      onPressed: () async {
                        final String shareText =
                            '''
=========================
      PARZELLO POS       
=========================
Terima Kasih Telah Berbelanja

No. Transaksi: #${transaction['id'].toString().substring(0, 8).toUpperCase()}
Tanggal: ${dateFormat.format(DateTime.parse(transaction['created_at']))}
Metode: ${transaction['payment_method']}
-------------------------
${items.map((item) => "${item['product_name']}\n${item['quantity']} x ${currencyFormat.format(item['unit_price'])}   ${currencyFormat.format(item['subtotal'])}").join('\n-------------------------\n')}
-------------------------
Total Belanja: ${currencyFormat.format(transaction['total_amount'])}
Bayar: ${currencyFormat.format(transaction['cash_paid'])}
Kembalian: ${currencyFormat.format(transaction['change_amount'])}
=========================
''';
                        await Share.share(
                          shareText,
                          subject: 'Struk Belanja Parzello POS',
                        );
                      },
                      leading: const Icon(TablerIcons.share),
                      child: const Text('Bagikan'),
                    ),
                    const SizedBox(width: 12),
                    ShadButton(
                      onPressed: () async {
                        if (connectedPrinter == null) {
                          context.push('/printer-settings');
                        } else {
                          try {
                            await ref
                                .read(printerNotifierProvider.notifier)
                                .printReceipt(
                                  transaction: transaction,
                                  items: items,
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ShadToaster.of(context).show(
                                ShadToast.destructive(
                                  description: Text(e.toString()),
                                ),
                              );
                            }
                          }
                        }
                      },
                      leading: const Icon(TablerIcons.printer),
                      child: Text(
                        connectedPrinter == null
                            ? 'Set Printer'
                            : 'Cetak Struk',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
