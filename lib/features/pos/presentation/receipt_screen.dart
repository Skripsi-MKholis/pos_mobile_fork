import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/pos/providers/printer_provider.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/core/models/receipt_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_mobile/core/ads/interstitial_ad_manager.dart';

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
  bool _isSharingImage = false;
  final GlobalKey _receiptKey = GlobalKey();

  Future<void> _handleShareAsImage() async {
    setState(() => _isSharingImage = true);
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw 'Gagal mengambil gambar struk';

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/struk_${widget.transaction['id']}.png',
      ).create();
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Struk Belanja');
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal membagikan gambar struk: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoPrint) {
        _handlePrint();
      }
    });
  }

  /// Keluar dari layar struk. Sesekali (frequency-capped) menampilkan
  /// interstitial ad di titik transisi ini agar tidak mengganggu kasir.
  void _finishAndExit() {
    InterstitialAdManager.instance.maybeShow(
      onDone: () {
        if (mounted) context.go('/transactions');
      },
    );
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

      // Log to Firebase Analytics
      try {
        await AnalyticsService.instance.logPrintReceipt(
          printerConnection: 'bluetooth',
          isReprint: !widget.autoPrint,
        );
      } catch (_) {}

      if (mounted) {
        mySnackBar(
          context: context,
          text: AppLocalizations.of(context)!.receiptPrinting,
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: AppLocalizations.of(context)!.failedToPrint(e.toString()),
          status: ToastStatus.error,
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
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: currentLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final connectedPrinter = ref.watch(printerNotifierProvider);
    final theme = ShadTheme.of(context);

    final activeStore = ref.watch(activeStoreProvider).value;
    final config = ReceiptConfig.fromStore(activeStore);

    final storeName = config.storeName;
    final showLogo = config.showLogo;
    final showAddress = config.showAddress;
    final address = config.address;
    final showPhone = config.showPhone;
    final phone = config.phone;
    final showHeaderMsg = config.showHeaderMessage;
    final headerMsg = config.headerMessage;
    final showFooterMsg = config.showFooterMessage;
    final footerMsg = config.footerMessage;
    final showCashier = config.showCashier;
    final loggedInName =
        ref.watch(userProfileProvider).value?['full_name'] as String?;
    final cashierName = config.resolveCashierName(
      loggedInName,
      fallback: l10n.parzelloStaff,
    );
    final receiptPrefix = config.receiptNumberPrefix;
    final websiteUrl = config.websiteUrl;
    final showQrCode = config.showQrCode;
    final freeText = config.freeText;
    final showPaymentMethod = config.showPaymentMethod;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finishAndExit();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.muted,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.muted,
          elevation: 0,
          title: Text(
            l10n.digitalReceipt,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(TablerIcons.chevron_left),
            onPressed: _finishAndExit,
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                RepaintBoundary(
                  key: _receiptKey,
                  child: ShadCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      children: [
                        if (showLogo) ...[
                          Container(
                            height: 48,
                            width: 48,
                            margin: const EdgeInsets.only(bottom: 8),
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
                                          size: 24,
                                        ),
                                  )
                                : const Icon(
                                    TablerIcons.building_store,
                                    size: 24,
                                  ),
                          ),
                        ],
                        Text(
                          storeName,
                          style: theme.textTheme.h4,
                          textAlign: TextAlign.center,
                        ),
                        if (showAddress && address.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            address,
                            style: theme.textTheme.muted.copyWith(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (showPhone && phone.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            'Telp: $phone',
                            style: theme.textTheme.muted.copyWith(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (showHeaderMsg && headerMsg.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              headerMsg,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        _buildRow(
                          l10n.transactionNo,
                          receiptPrefix.isNotEmpty
                              ? '#$receiptPrefix-${widget.transaction['id'].toString().substring(0, 8).toUpperCase()}'
                              : '#${widget.transaction['id'].toString().substring(0, 8).toUpperCase()}',
                        ),
                        _buildRow(
                          l10n.date,
                          dateFormat.format(
                            DateTime.parse(widget.transaction['created_at']).toLocal(),
                          ),
                        ),

                        if (showCashier) ...[
                          _buildRow(l10n.cashier, cashierName),
                        ],
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        ...widget.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
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
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${item['quantity'] ?? 1} x ${currencyFormat.format(item['unit_price'] ?? 0)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(item['subtotal'] ?? 0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        _buildRow(
                          l10n.totalBelanja,
                          currencyFormat.format(
                            widget.transaction['total_amount'] ?? 0,
                          ),
                          isBold: true,
                        ),
                        if (showPaymentMethod) ...[
                          _buildRow(
                            l10n.method,
                            (widget.transaction['payment_method']?.toString().isNotEmpty ?? false)
                                ? widget.transaction['payment_method'].toString()
                                : 'Tunai',
                          ),
                        ],
                        _buildRow(
                          l10n.paid,
                          // Bisa null pada data dari server (non-tunai):
                          // fallback ke total belanja.
                          currencyFormat.format(
                            widget.transaction['cash_paid'] ??
                                widget.transaction['total_amount'] ??
                                0,
                          ),
                        ),
                        _buildRow(
                          l10n.change,
                          currencyFormat.format(
                            widget.transaction['change_amount'] ?? 0,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              freeText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                        ],

                        // QR Code & Branding Section
                        if (showQrCode) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data:
                                        'https://parzello-pos.vercel.app/receipt/${widget.transaction['id']}',
                                    version: QrVersions.auto,
                                    size: 96.0,
                                    gapless: false,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.scanToViewOnlineReceipt,
                                  style: theme.textTheme.muted.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'https://parzello-pos.vercel.app/receipt/${widget.transaction['id']}',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade500,
                                      fontFamily: 'monospace',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Store Icon and Store Name again
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
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
                                              size: 10,
                                              color: Warna.primary,
                                            ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      storeName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // Website / Sosmed URL
                                if (websiteUrl.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        TablerIcons.world,
                                        size: 10,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        websiteUrl,
                                        style: theme.textTheme.muted.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
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
                        ],
                        const SizedBox(height: 12),
                        if (showFooterMsg && footerMsg.isNotEmpty) ...[
                          Text(
                            footerMsg,
                            style: theme.textTheme.muted.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                        ] else if (showFooterMsg) ...[
                          Text(
                            'Terima Kasih Telah Berbelanja',
                            style: theme.textTheme.muted.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          'Powered by ZelloPOS',
                          style: theme.textTheme.muted.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ShadButton.outline(
                      onPressed: () async {
                        final String shareText =
                            '''
=================================
      ${storeName.toUpperCase()}       
=================================
${showHeaderMsg && headerMsg.isNotEmpty ? '$headerMsg\n' : ''}${showAddress && address.isNotEmpty ? '$address\n' : ''}${showPhone && phone.isNotEmpty ? 'Telp: $phone\n' : ''}---------------------------------
${l10n.transactionNo}: ${receiptPrefix.isNotEmpty ? '#$receiptPrefix-' : '#'}${widget.transaction['id'].toString().substring(0, 8).toUpperCase()}
${l10n.date}: ${dateFormat.format(DateTime.parse(widget.transaction['created_at']).toLocal())}
${showPaymentMethod ? '${l10n.method}: ${widget.transaction['payment_method'] ?? 'Tunai'}\n' : ''}${showCashier ? '${l10n.cashier}: $cashierName\n' : ''}---------------------------------
${widget.items.map((item) => "${item['product_name']}\n${item['quantity'] ?? 1} x ${currencyFormat.format(item['unit_price'] ?? 0)}   ${currencyFormat.format(item['subtotal'] ?? 0)}").join('\n---------------------------------\n')}
---------------------------------
${l10n.totalBelanja}: ${currencyFormat.format(widget.transaction['total_amount'] ?? 0)}
${l10n.paid}: ${currencyFormat.format(widget.transaction['cash_paid'] ?? widget.transaction['total_amount'] ?? 0)}
${l10n.change}: ${currencyFormat.format(widget.transaction['change_amount'] ?? 0)}
${showFooterMsg ? '${footerMsg.isNotEmpty ? footerMsg : 'Terima Kasih Telah Berbelanja'}\n' : ''}=================================
''';
                        await Share.share(
                          shareText,
                          subject: 'Struk Belanja $storeName',
                        );
                      },
                      leading: const Icon(TablerIcons.share),
                      child: Text(l10n.share),
                    ),
                    ShadButton.outline(
                      enabled: !_isSharingImage,
                      onPressed: _isSharingImage ? null : _handleShareAsImage,
                      leading: _isSharingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(TablerIcons.photo),
                      child: const Text('Gambar'),
                    ),
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
                            ? l10n.printing
                            : (connectedPrinter == null
                                  ? l10n.setPrinter
                                  : l10n.printReceipt),
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
        mySnackBar(
          context: context,
          text: 'Gagal memuat printer: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ShadDialog(
      title: Text(l10n.connectPrinter),
      description: Text(l10n.connectPrinterDesc),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 250),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _devices.isEmpty
            ? Center(
                child: Text(l10n.noBluetoothPrinterFound),
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
                      device.name ?? l10n.thermalPrinter,
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
                          mySnackBar(
                              context: context,
                              text: l10n.failedWithReason(e.toString()),
                              status: ToastStatus.error,
                            );
                          }
                        }
                      },
                      child: Text(l10n.select),
                    ),
                  );
                },
              ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ShadButton.ghost(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/printer-settings');
          },
          child: Text(l10n.settings),
        ),
      ],
    );
  }
}
