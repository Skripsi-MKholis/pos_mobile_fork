import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_mobile/core/services/printer_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

part 'printer_provider.g.dart';

@riverpod
class PrinterNotifier extends _$PrinterNotifier {
  final _service = PrinterService();

  @override
  BluetoothDevice? build() {
    return null;
  }

  Future<List<BluetoothDevice>> getDevices() async {
    return await _service.getDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    await _service.connect(device);
    state = device;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = null;
  }

  Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<dynamic> items,
  }) async {
    final activeStore = ref.read(activeStoreProvider).value;
    await _service.printReceipt(
      transaction: transaction,
      items: items,
      activeStore: activeStore,
    );
  }
}
