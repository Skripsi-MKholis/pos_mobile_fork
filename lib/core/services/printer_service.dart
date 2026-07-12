import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/models/receipt_config.dart';

class PrinterService {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    return await bluetooth.getBondedDevices();
  }

  Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<dynamic> items,
    Map<String, dynamic>? activeStore,
    String? loggedInCashierName,
  }) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected == null || !isConnected) {
      throw 'Printer tidak terhubung';
    }

    final config = ReceiptConfig.fromStore(activeStore);
    final storeName = config.storeName;
    final showAddress = config.showAddress;
    final address = config.address;
    final showPhone = config.showPhone;
    final phone = config.phone;
    final showHeaderMsg = config.showHeaderMessage;
    final headerMsg = config.headerMessage;
    final showFooterMsg = config.showFooterMessage;
    final footerMsg = config.footerMessage;
    final showCashier = config.showCashier;
    final cashierName = config.resolveCashierName(loggedInCashierName);
    final websiteUrl = config.websiteUrl;
    final showQrCode = config.showQrCode;
    final freeText = config.freeText;
    final showPaymentMethod = config.showPaymentMethod;
    final receiptPrefix = config.receiptNumberPrefix;
    final separator = config.printerSeparator;

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    await bluetooth.printNewLine();

    // Header Store Name (Size 2 or 3 is usually double-height or double-width bold)
    await bluetooth.printCustom(storeName, 2, 1);

    if (showAddress && address.isNotEmpty) {
      await bluetooth.printCustom(address, 1, 1);
    }
    if (showPhone && phone.isNotEmpty) {
      await bluetooth.printCustom("Telp: $phone", 1, 1);
    }
    if (showHeaderMsg && headerMsg.isNotEmpty) {
      await bluetooth.printCustom(headerMsg, 1, 1);
    }
    await bluetooth.printNewLine();

    await bluetooth.printLeftRight(
      "No:",
      "#$receiptPrefix-${transaction['id'].toString().substring(0, 6).toUpperCase()}",
      1,
    );
    await bluetooth.printLeftRight(
      "Tgl:",
      dateFormat.format(DateTime.parse(transaction['created_at']).toLocal()),
      1,
    );
    if (showCashier) {
      final printedCashierName = cashierName.length > 16
          ? '${cashierName.substring(0, 15)}.'
          : cashierName;
      await bluetooth.printLeftRight("Kasir:", printedCashierName, 1);
    }
    await bluetooth.printCustom(separator, 1, 1);

    for (var item in items) {
      await bluetooth.printCustom(item['product_name'], 1, 0);
      await bluetooth.printLeftRight(
        "${item['quantity']} x ${currencyFormat.format(item['unit_price'])}",
        currencyFormat.format(item['subtotal']),
        1,
      );
    }

    await bluetooth.printCustom(separator, 1, 1);
    await bluetooth.printLeftRight(
      "TOTAL:",
      currencyFormat.format(transaction['total_amount']),
      2,
    );
    await bluetooth.printLeftRight(
      "BAYAR:",
      currencyFormat.format(transaction['cash_paid']),
      1,
    );
    await bluetooth.printLeftRight(
      "KEMBALI:",
      currencyFormat.format(transaction['change_amount']),
      1,
    );
    await bluetooth.printNewLine();

    if (showPaymentMethod) {
      await bluetooth.printCustom(
        "Metode: ${transaction['payment_method']}",
        1,
        1,
      );
      await bluetooth.printNewLine();
    }

    if (showFooterMsg && footerMsg.isNotEmpty) {
      await bluetooth.printCustom(footerMsg, 1, 1);
    } else {
      await bluetooth.printCustom("Terima Kasih", 1, 1);
    }
    await bluetooth.printNewLine();

    // Free Text Section
    if (freeText.isNotEmpty) {
      await bluetooth.printCustom(separator, 1, 1);
      final lines = freeText.split('\n');
      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          await bluetooth.printCustom(line, 1, 1);
        }
      }
      await bluetooth.printNewLine();
    }

    // QR Code Section
    if (showQrCode) {
      await bluetooth.printCustom(separator, 1, 1);
      await bluetooth.printNewLine();

      // Print QR code for receipt link
      await bluetooth.printCustom("Scan untuk Struk Online:", 1, 1);
      await bluetooth.printQRcode(
        "https://parzello-pos.vercel.app/receipt/${transaction['id']}",
        180,
        180,
        1,
      );
      await bluetooth.printNewLine();

      // Print Store name again
      await bluetooth.printCustom(storeName, 1, 1);

      // Website / Sosmed URL
      if (websiteUrl.isNotEmpty) {
        await bluetooth.printCustom(websiteUrl, 1, 1);
      }
    }

    await bluetooth.printCustom(separator, 1, 1);
    await bluetooth.printNewLine();
    await bluetooth.printCustom("Powered by Parzello POS", 0, 1);
    await bluetooth.printNewLine();
    await bluetooth.printNewLine();
    await bluetooth.paperCut();
  }

  Future<void> connect(BluetoothDevice device) async {
    await bluetooth.connect(device);
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }
}
