import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/core/theme/colors.dart';
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
  bool _isBluetoothEnabled = true;
  String? _connectingDeviceAddress;
  bool _isTestingPrint = false;
  bool _isOpeningDrawer = false;
  String? _savedMacAddress;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final saved = await ref
        .read(printerNotifierProvider.notifier)
        .getSavedPrinterAddress();
    if (mounted) {
      setState(() => _savedMacAddress = saved);
    }
    await _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cek status Bluetooth terlebih dahulu
      final isBtOn =
          await ref.read(printerNotifierProvider.notifier).isBluetoothOn();
      if (mounted) {
        setState(() => _isBluetoothEnabled = isBtOn);
      }

      // 2. Minta permission
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // 3. Muat daftar bonded devices
      final devices =
          await ref.read(printerNotifierProvider.notifier).getDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isBluetoothEnabled = true;
        });
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Peringatan: Bluetooth mungkin belum aktif atau perizinan ditolak ($e)',
          status: ToastStatus.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect(BluetoothDevice device) async {
    setState(() => _connectingDeviceAddress = device.address);
    try {
      await ref.read(printerNotifierProvider.notifier).connect(device);
      if (mounted) {
        setState(() => _savedMacAddress = device.address);
        mySnackBar(
          context: context,
          text: 'Berhasil terhubung ke ${device.name ?? "Printer"}',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal menghubungkan printer: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _connectingDeviceAddress = null);
      }
    }
  }

  Future<void> _handleDisconnect() async {
    try {
      await ref.read(printerNotifierProvider.notifier).disconnect();
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Koneksi printer diputuskan',
          status: ToastStatus.info,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal memutuskan printer: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  Future<void> _handleTestPrint() async {
    setState(() => _isTestingPrint = true);
    try {
      await ref.read(printerNotifierProvider.notifier).testPrint();
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Struk uji coba berhasil dicetak!',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal mencetak struk: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingPrint = false);
      }
    }
  }

  Future<void> _handleOpenDrawer() async {
    setState(() => _isOpeningDrawer = true);
    try {
      await ref.read(printerNotifierProvider.notifier).openCashDrawer();
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Sinyal pembuka laci kasir telah dikirim',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal membuka laci kasir: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningDrawer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = ref.watch(printerNotifierProvider);
    final theme = ShadTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: const Text(
            'Pengaturan Printer',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Pindai Ulang',
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(TablerIcons.refresh, color: Colors.black),
              onPressed: _isLoading ? null : _loadDevices,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDevices,
          color: Warna.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Connection Card (Hero Banner)
                _buildConnectionStatusCard(theme, connectedDevice),
                const SizedBox(height: 16),

                // 2. Bluetooth Warning Banner jika mati
                if (!_isBluetoothEnabled) ...[
                  _buildBluetoothDisabledWarning(theme),
                  const SizedBox(height: 16),
                ],

                // 3. Quick Actions jika sudah terhubung (Test Print, Cash Drawer, Custom Struk)
                if (connectedDevice != null) ...[
                  _buildPrinterActionRow(theme),
                  const SizedBox(height: 20),
                ],

                // 4. Header Daftar Perangkat Bluetooth
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAFTAR PERANGKAT BLUETOOTH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Perangkat yang sudah dipasangkan (paired)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (_devices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_devices.length} Perangkat',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. List Device Items
                _buildDeviceList(theme, connectedDevice),
                const SizedBox(height: 24),

                // 6. Card Pintasan Kustomisasi Struk
                _buildReceiptCustomizationBanner(theme),
                const SizedBox(height: 16),

                // 7. Info Card & Troubleshooting Tips
                _buildTroubleshootingTips(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Hero Card: Status Koneksi Printer
  Widget _buildConnectionStatusCard(
    ShadThemeData theme,
    BluetoothDevice? connectedDevice,
  ) {
    final isConnected = connectedDevice != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? Warna.success.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? Warna.success.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Container with soft badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isConnected
                      ? Warna.success.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isConnected ? TablerIcons.printer : TablerIcons.printer_off,
                  size: 28,
                  color: isConnected ? Warna.success : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? Warna.success
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'TERHUBUNG' : 'BELUM TERHUBUNG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isConnected
                                ? Warna.success
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? (connectedDevice.name ?? 'Thermal Printer')
                          : 'Tidak Ada Printer Aktif',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isConnected && connectedDevice.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'MAC: ${connectedDevice.address}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.destructive(
                  size: ShadButtonSize.sm,
                  leading: const Icon(TablerIcons.plug_connected_x, size: 16),
                  onPressed: _handleDisconnect,
                  child: const Text('Putuskan Koneksi'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 2. Peringatan Bluetooth Mati
  Widget _buildBluetoothDisabledWarning(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              TablerIcons.bluetooth_off,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Bluetooth Tidak Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Aktifkan Bluetooth di perangkat Anda untuk mendeteksi printer kasir.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () async {
              try {
                await ref
                    .read(printerNotifierProvider.notifier)
                    .openBluetoothSettings();
              } catch (_) {
                if (mounted) {
                  mySnackBar(
                    context: context,
                    text: 'Silakan aktifkan Bluetooth melalui Pengaturan perangkat Anda.',
                    status: ToastStatus.info,
                  );
                }
              }
            },
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }

  /// 3. Baris Tombol Aksi Cepat (Test Print & Laci Kasir)
  Widget _buildPrinterActionRow(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AKSI & PENGUJIAN PERANGKAT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ShadButton(
                  size: ShadButtonSize.sm,
                  enabled: !_isTestingPrint,
                  leading: _isTestingPrint
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(TablerIcons.receipt, size: 16),
                  onPressed: _isTestingPrint ? null : _handleTestPrint,
                  child: Text(
                    _isTestingPrint ? 'Mencetak...' : 'Test Print Struk',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShadButton.outline(
                  size: ShadButtonSize.sm,
                  enabled: !_isOpeningDrawer,
                  leading: _isOpeningDrawer
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(TablerIcons.archive, size: 16),
                  onPressed: _isOpeningDrawer ? null : _handleOpenDrawer,
                  child: Text(
                    _isOpeningDrawer ? 'Membuka...' : 'Buka Laci Uang',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4 & 5. List Device Items
  Widget _buildDeviceList(
    ShadThemeData theme,
    BluetoothDevice? connectedDevice,
  ) {
    if (_isLoading) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Warna.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Mencari printer bluetooth...',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                TablerIcons.bluetooth,
                size: 36,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum Ada Printer Bluetooth',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pastikan printer thermal sudah dipasangkan (paired) di pengaturan Bluetooth HP Anda terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              leading: const Icon(TablerIcons.settings, size: 16),
              onPressed: () async {
                try {
                  await ref
                      .read(printerNotifierProvider.notifier)
                      .openBluetoothSettings();
                } catch (e) {
                  if (mounted) {
                    mySnackBar(
                      context: context,
                      text: 'Silakan buka Pengaturan Bluetooth secara manual di perangkat Anda.',
                      status: ToastStatus.info,
                    );
                  }
                }
              },
              child: const Text('Buka Pengaturan HP'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _devices.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isSelected = connectedDevice?.address == device.address;
        final isLastSaved = _savedMacAddress == device.address;
        final isConnecting = _connectingDeviceAddress == device.address;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Warna.primary.withValues(alpha: 0.6)
                  : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Warna.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon Printer Device
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Warna.primary.withValues(alpha: 0.18)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  TablerIcons.printer,
                  size: 22,
                  color: isSelected ? Colors.black : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 14),
              // Name & Address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            device.name ?? 'Thermal Printer',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLastSaved && !isSelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            child: Text(
                              'Favorit',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.address ?? 'Alamat tidak diketahui',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Button
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Warna.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        TablerIcons.circle_check,
                        size: 16,
                        color: Colors.black,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Aktif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  enabled: _connectingDeviceAddress == null,
                  onPressed: () => _handleConnect(device),
                  leading: isConnecting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  child: Text(isConnecting ? 'Menghubungkan' : 'Hubungkan'),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 6. Banner Pintasan Kustomisasi Struk
  Widget _buildReceiptCustomizationBanner(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/receipt-customization'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Warna.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    TablerIcons.receipt_2,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kustomisasi Format Struk',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Atur lebar kertas (58/80mm), logo, pesan header, dan QR Code',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  TablerIcons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 7. Tips Panduan & Troubleshooting
  Widget _buildTroubleshootingTips(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                TablerIcons.info_circle,
                size: 18,
                color: Color(0xFF475569),
              ),
              SizedBox(width: 8),
              Text(
                'Panduan Penggunaan Printer Thermal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTipItem(
            '1. Hubungkan Bluetooth terlebih dahulu melalui menu Pengaturan Bluetooth di ponsel (PIN standar: 0000 atau 1234).',
          ),
          const SizedBox(height: 6),
          _buildTipItem(
            '2. Gunakan tombol "Test Print Struk" untuk memastikan teks tercetak rapi dan penjajaran kertas sesuai.',
          ),
          const SizedBox(height: 6),
          _buildTipItem(
            '3. Jika printer tidak merespons, matikan dan hidupkan kembali printer thermal Anda lalu tekan ikon "Pindai Ulang".',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        color: Color(0xFF475569),
        height: 1.4,
      ),
    );
  }
}
