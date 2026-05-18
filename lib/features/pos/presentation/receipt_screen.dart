import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/pos/providers/printer_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> transaction;
  final List<dynamic> items;
  final bool autoPrint;

  const ReceiptScreen({
    super.key,
    required this.transaction,
    required this.items,
    this.autoPrint = false,
  });

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoPrint) {
        _handlePrint();
      }
    });
  }

  Future<void> _handlePrint() async {
    final connectedPrinter = ref.read(printerNotifierProvider);
    if (connectedPrinter == null) {
      _showQuickConnectDialog();
      return;
    }

    setState(() => _isPrinting = true);
    try {
      await ref
          .read(printerNotifierProvider.notifier)
          .printReceipt(transaction: widget.transaction, items: widget.items);
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Berhasil'),
            description: Text('Struk sedang dicetak.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Gagal Mencetak'),
            description: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<void> _showQuickConnectDialog() async {
    showShadDialog(
      context: context,
      builder: (context) => _QuickConnectDialog(
        onConnected: () {
          Navigator.of(context).pop();
          _handlePrint();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final connectedPrinter = ref.watch(printerNotifierProvider);
    final theme = ShadTheme.of(context);

    final activeStore = ref.watch(activeStoreProvider).value;
    final storeSettings =
        activeStore?['settings'] as Map<String, dynamic>? ?? {};
    final receiptSettings =
        storeSettings['receipt'] as Map<String, dynamic>? ?? {};

    final storeName = receiptSettings['store_name']?.isNotEmpty == true
        ? receiptSettings['store_name']
        : (activeStore?['name'] ?? 'PARZELLO POS');
    final showLogo = receiptSettings['show_logo'] ?? true;
    final showAddress = receiptSettings['show_address'] ?? true;
    final address = receiptSettings['address']?.isNotEmpty == true
        ? receiptSettings['address']
        : (activeStore?['address'] ?? '');
    final showPhone = receiptSettings['show_phone'] ?? true;
    final phone = receiptSettings['phone']?.isNotEmpty == true
        ? receiptSettings['phone']
        : (activeStore?['phone'] ?? '');
    final showHeaderMsg = receiptSettings['show_header_message'] ?? true;
    final headerMsg = receiptSettings['header_message'] ?? '';
    final showFooterMsg = receiptSettings['show_footer_message'] ?? true;
    final footerMsg = receiptSettings['footer_message']?.isNotEmpty == true
        ? receiptSettings['footer_message']
        : 'Terima Kasih';
    final showCashier = receiptSettings['show_cashier'] ?? true;
    final websiteUrl = receiptSettings['website_url'] ?? '';
    final showQrCode = receiptSettings['show_qr_code'] ?? true;
    final freeText = receiptSettings['free_text'] ?? '';

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
            onPressed: () => context.go('/transactions'),
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
                        if (showLogo) ...[
                          Container(
                            height: 60,
                            width: 60,
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Warna.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Warna.primary.withOpacity(0.3),
                              ),
                            ),
                            child:
                                activeStore?['logo_url'] != null &&
                                    (activeStore?['logo_url'] as String)
                                        .isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: activeStore?['logo_url'],
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          TablerIcons.building_store,
                                          size: 28,
                                        ),
                                  )
                                : const Icon(
                                    TablerIcons.building_store,
                                    size: 28,
                                  ),
                          ),
                        ],
                        Text(
                          storeName,
                          style: theme.textTheme.h3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        if (showAddress && address.isNotEmpty) ...[
                          Text(
                            address,
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                        ],
                        if (showPhone && phone.isNotEmpty) ...[
                          Text(
                            'Telp: $phone',
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (showHeaderMsg && headerMsg.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              headerMsg,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildRow(
                          'No. Transaksi',
                          '#${widget.transaction['id'].toString().substring(0, 8).toUpperCase()}',
                        ),
                        _buildRow(
                          'Tanggal',
                          dateFormat.format(
                            DateTime.parse(widget.transaction['created_at']).toLocal(),
                          ),
                        ),
                        _buildRow(
                          'Metode',
                          widget.transaction['payment_method'],
                        ),
                        if (showCashier) ...[
                          _buildRow('Kasir', 'Staf Parzello'),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        ...widget.items.map(
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
                          currencyFormat.format(
                            widget.transaction['total_amount'],
                          ),
                          isBold: true,
                        ),
                        _buildRow(
                          'Bayar',
                          currencyFormat.format(
                            widget.transaction['cash_paid'],
                          ),
                        ),
                        _buildRow(
                          'Kembalian',
                          currencyFormat.format(
                            widget.transaction['change_amount'],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: List.generate(
                            20,
                            (index) => Expanded(
                              child: Container(
                                color: index % 2 == 0
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        // Free Text Section
                        if (freeText.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              freeText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: List.generate(
                              20,
                              (index) => Expanded(
                                child: Container(
                                  color: index % 2 == 0
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // QR Code & Branding Section
                        if (showQrCode) ...[
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data:
                                        'https://parzello-pos.vercel.app/receipt/${widget.transaction['id']}',
                                    version: QrVersions.auto,
                                    size: 110.0,
                                    gapless: false,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pindai untuk melihat struk online',
                                  style: theme.textTheme.muted.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Store Icon and Store Name again
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: Warna.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child:
                                          activeStore?['logo_url'] != null &&
                                              (activeStore?['logo_url']
                                                      as String)
                                                  .isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  activeStore?['logo_url'],
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(
                                              TablerIcons.building_store,
                                              size: 12,
                                              color: Warna.primary,
                                            ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      storeName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // Website / Sosmed URL
                                if (websiteUrl.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        TablerIcons.world,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        websiteUrl,
                                        style: theme.textTheme.muted.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: List.generate(
                              20,
                              (index) => Expanded(
                                child: Container(
                                  color: index % 2 == 0
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 24),
                        if (showFooterMsg && footerMsg.isNotEmpty) ...[
                          Text(
                            footerMsg,
                            style: theme.textTheme.muted.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          Text(
                            '--- SELESAI ---',
                            style: theme.textTheme.muted.copyWith(
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Powered by Parzello POS',
                          style: theme.textTheme.muted.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
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
=================================
      ${storeName.toUpperCase()}       
=================================
${showHeaderMsg && headerMsg.isNotEmpty ? '$headerMsg\n' : ''}${showAddress && address.isNotEmpty ? '$address\n' : ''}${showPhone && phone.isNotEmpty ? 'Telp: $phone\n' : ''}---------------------------------
No. Transaksi: #${widget.transaction['id'].toString().substring(0, 8).toUpperCase()}
Tanggal: ${dateFormat.format(DateTime.parse(widget.transaction['created_at']).toLocal())}
Metode: ${widget.transaction['payment_method']}
${showCashier ? 'Kasir: Staf Parzello\n' : ''}---------------------------------
${widget.items.map((item) => "${item['product_name']}\n${item['quantity']} x ${currencyFormat.format(item['unit_price'])}   ${currencyFormat.format(item['subtotal'])}").join('\n---------------------------------\n')}
---------------------------------
Total Belanja: ${currencyFormat.format(widget.transaction['total_amount'])}
Bayar: ${currencyFormat.format(widget.transaction['cash_paid'])}
Kembalian: ${currencyFormat.format(widget.transaction['change_amount'])}
---------------------------------
${showFooterMsg && footerMsg.isNotEmpty ? footerMsg : 'Terima Kasih'}
=================================
''';
                        await Share.share(
                          shareText,
                          subject: 'Struk Belanja $storeName',
                        );
                      },
                      leading: const Icon(TablerIcons.share),
                      child: const Text('Bagikan'),
                    ),
                    const SizedBox(width: 12),
                    ShadButton(
                      enabled: !_isPrinting,
                      onPressed: _isPrinting ? null : _handlePrint,
                      leading: _isPrinting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Icon(TablerIcons.printer),
                      child: Text(
                        _isPrinting
                            ? 'Mencetak...'
                            : (connectedPrinter == null
                                  ? 'Set Printer'
                                  : 'Cetak Struk'),
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

class _QuickConnectDialog extends ConsumerStatefulWidget {
  final VoidCallback onConnected;
  const _QuickConnectDialog({required this.onConnected});

  @override
  ConsumerState<_QuickConnectDialog> createState() =>
      _QuickConnectDialogState();
}

class _QuickConnectDialogState extends ConsumerState<_QuickConnectDialog> {
  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final devices = await ref
          .read(printerNotifierProvider.notifier)
          .getDevices();
      setState(() => _devices = devices);
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal memuat printer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Hubungkan Printer'),
      description: const Text(
        'Pilih printer bluetooth Anda untuk langsung mencetak struk.',
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 250),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _devices.isEmpty
            ? const Center(
                child: Text('Tidak ada bluetooth printer terpasang.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      TablerIcons.printer,
                      color: Warna.primary,
                    ),
                    title: Text(
                      device.name ?? 'Printer Thermal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(device.address ?? ''),
                    trailing: ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: () async {
                        try {
                          await ref
                              .read(printerNotifierProvider.notifier)
                              .connect(device);
                          widget.onConnected();
                        } catch (e) {
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                description: Text('Gagal menghubungkan: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Pilih'),
                    ),
                  );
                },
              ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ShadButton.ghost(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/printer-settings');
          },
          child: const Text('Pengaturan'),
        ),
      ],
    );
  }
}
