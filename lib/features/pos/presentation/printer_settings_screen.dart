import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/features/pos/providers/printer_provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

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
      // Request Bluetooth & location permissions dynamically
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
          text: 'Error: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = ref.watch(printerNotifierProvider);
    final theme = ShadTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.background,
          elevation: 0,
          title: const Text(
            'Pengaturan Printer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(TablerIcons.chevron_left),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          actions: [
            ShadButton.ghost(
              child: const Icon(TablerIcons.refresh),
              onPressed: _loadDevices,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildStatusHeader(connectedDevice, theme),
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

                        return ShadCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.muted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(TablerIcons.printer),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name ?? 'Unknown Device',
                                      style: theme.textTheme.p.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      device.address ?? '',
                                      style: theme.textTheme.muted.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  TablerIcons.circle_check,
                                  color: theme.colorScheme.primary,
                                )
                              else
                                ShadButton.outline(
                                  size: ShadButtonSize.sm,
                                  onPressed: () => ref
                                      .read(printerNotifierProvider.notifier)
                                      .connect(device),
                                  child: const Text('Hubungkan'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
    BluetoothDevice? connectedDevice,
    ShadThemeData theme,
  ) {
    final isConnected = connectedDevice != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: isConnected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.muted,
      child: Column(
        children: [
          Icon(
            isConnected ? TablerIcons.printer : TablerIcons.printer_off,
            size: 56,
            color: isConnected
                ? theme.colorScheme.primary
                : theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            isConnected ? 'Printer Terhubung' : 'Printer Belum Terhubung',
            style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          if (isConnected) ...[
            const SizedBox(height: 8),
            Text(connectedDevice.name ?? '', style: theme.textTheme.muted),
            const SizedBox(height: 16),
            ShadButton.destructive(
              size: ShadButtonSize.sm,
              onPressed: () =>
                  ref.read(printerNotifierProvider.notifier).disconnect(),
              child: const Text('Putuskan Koneksi'),
            ),
          ],
        ],
      ),
    );
  }
}
