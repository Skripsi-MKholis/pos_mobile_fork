import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_mobile/core/services/printer_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

part 'printer_provider.g.dart';

@riverpod
class PrinterNotifier extends _$PrinterNotifier {
  final _service = PrinterService();
  static const _prefSavedPrinterAddress = 'saved_printer_mac_address';

  @override
  BluetoothDevice? build() {
    return null;
  }

  Future<List<BluetoothDevice>> getDevices() async {
    return await _service.getDevices();
  }

  Future<bool> isBluetoothOn() async {
    return await _service.isBluetoothOn();
  }

  Future<void> openBluetoothSettings() async {
    await _service.openBluetoothSettings();
  }

  Future<void> connect(BluetoothDevice device) async {
    await _service.connect(device);
    state = device;
    if (device.address != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefSavedPrinterAddress, device.address!);
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = null;
  }

  Future<String?> getSavedPrinterAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefSavedPrinterAddress);
    } catch (_) {
      return null;
    }
  }

  Future<void> testPrint() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final loggedInName =
        (await ref.read(userProfileProvider.future))?['full_name'] as String?;
    await _service.printTestReceipt(
      activeStore: activeStore,
      cashierName: loggedInName,
    );
  }

  Future<void> openCashDrawer() async {
    await _service.openCashDrawer();
  }

  Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<dynamic> items,
  }) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final loggedInName =
        (await ref.read(userProfileProvider.future))?['full_name'] as String?;
    await _service.printReceipt(
      transaction: transaction,
      items: items,
      activeStore: activeStore,
      loggedInCashierName: loggedInName,
    );
  }
}
