import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/pos/providers/printer_provider.dart';

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
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final connectedPrinter = ref.watch(printerNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Struk Digital'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.printer),
            onPressed: () => context.push('/printer-settings'),
          ),
          IconButton(
            icon: const Icon(TablerIcons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('PARZELLO POS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Terima Kasih Telah Berbelanja', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1, color: Colors.black12),
                    _buildRow('No. Transaksi', '#${transaction['id'].toString().substring(0, 8).toUpperCase()}'),
                    _buildRow('Tanggal', dateFormat.format(DateTime.parse(transaction['created_at']))),
                    _buildRow('Metode', transaction['payment_method']),
                    const Divider(thickness: 1, color: Colors.black12),
                    const SizedBox(height: 16),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${item['quantity']} x ${currencyFormat.format(item['unit_price'])}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(currencyFormat.format(item['subtotal']), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1, color: Colors.black12),
                    const SizedBox(height: 16),
                    _buildRow('Total Belanja', currencyFormat.format(transaction['total_amount']), isBold: true),
                    _buildRow('Bayar', currencyFormat.format(transaction['cash_paid'])),
                    _buildRow('Kembalian', currencyFormat.format(transaction['change_amount'])),
                    const SizedBox(height: 32),
                    const Text('--- SELESAI ---', style: TextStyle(color: Colors.grey, letterSpacing: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(TablerIcons.home),
                    label: const Text('Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (connectedPrinter == null) {
                        context.push('/printer-settings');
                      } else {
                        try {
                          await ref.read(printerNotifierProvider.notifier).printReceipt(
                            transaction: transaction,
                            items: items,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      }
                    },
                    icon: const Icon(TablerIcons.printer),
                    label: Text(connectedPrinter == null ? 'Set Printer' : 'Cetak Struk'),
                  ),
                ],
              ),
            ],
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
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
