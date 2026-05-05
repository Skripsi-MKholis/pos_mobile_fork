import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/printer_provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
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
      final devices = await ref
          .read(printerNotifierProvider.notifier)
          .getDevices();
      setState(() => _devices = devices);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = ref.watch(printerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(connectedDevice),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                ? const Center(
                    child: Text('Tidak ada perangkat Bluetooth terpasang'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected =
                          connectedDevice?.address == device.address;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(TablerIcons.printer),
                          title: Text(device.name ?? 'Unknown Device'),
                          subtitle: Text(device.address ?? ''),
                          trailing: isSelected
                              ? const Icon(
                                  TablerIcons.circle_check,
                                  color: Colors.green,
                                )
                              : ElevatedButton(
                                  onPressed: () => ref
                                      .read(printerNotifierProvider.notifier)
                                      .connect(device),
                                  child: const Text('Hubungkan'),
                                ),
                          onTap: isSelected
                              ? () => ref
                                    .read(printerNotifierProvider.notifier)
                                    .disconnect()
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BluetoothDevice? connectedDevice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: connectedDevice != null ? Colors.green[50] : Colors.orange[50],
      child: Column(
        children: [
          Icon(
            connectedDevice != null
                ? TablerIcons.printer
                : TablerIcons.printer_off,
            size: 48,
            color: connectedDevice != null ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 12),
          Text(
            connectedDevice != null
                ? 'Printer Terhubung'
                : 'Printer Belum Terhubung',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (connectedDevice != null) ...[
            const SizedBox(height: 4),
            Text(
              connectedDevice.name ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
