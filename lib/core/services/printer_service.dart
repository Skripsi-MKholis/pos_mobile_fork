import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

class PrinterService {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    return await bluetooth.getBondedDevices();
  }

  Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<dynamic> items,
  }) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected == null || !isConnected) {
      throw 'Printer tidak terhubung';
    }

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    // Layout untuk printer 58mm
    await bluetooth.printNewLine();
    await bluetooth.printCustom("PARZELLO POS", 3, 1); // Bold, Center
    await bluetooth.printCustom("Terima Kasih", 1, 1);
    await bluetooth.printNewLine();
    
    await bluetooth.printLeftRight("No:", "#${transaction['id'].toString().substring(0, 6).toUpperCase()}", 1);
    await bluetooth.printLeftRight("Tgl:", dateFormat.format(DateTime.parse(transaction['created_at'])), 1);
    await bluetooth.printCustom("--------------------------------", 1, 1);

    for (var item in items) {
      await bluetooth.printCustom(item['product_name'], 1, 0);
      await bluetooth.printLeftRight(
        "${item['quantity']} x ${currencyFormat.format(item['unit_price'])}",
        currencyFormat.format(item['subtotal']),
        1,
      );
    }

    await bluetooth.printCustom("--------------------------------", 1, 1);
    await bluetooth.printLeftRight("TOTAL:", currencyFormat.format(transaction['total_amount']), 2);
    await bluetooth.printLeftRight("BAYAR:", currencyFormat.format(transaction['cash_paid']), 1);
    await bluetooth.printLeftRight("KEMBALI:", currencyFormat.format(transaction['change_amount']), 1);
    await bluetooth.printNewLine();
    
    await bluetooth.printCustom("Metode: ${transaction['payment_method']}", 1, 1);
    await bluetooth.printNewLine();
    await bluetooth.printCustom("Powered by Parzello", 0, 1);
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
