import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerScanScreen extends ConsumerStatefulWidget {
  const CustomerScanScreen({super.key});

  @override
  ConsumerState<CustomerScanScreen> createState() => _CustomerScanScreenState();
}

class _CustomerScanScreenState extends ConsumerState<CustomerScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isTableMode = true; // Toggle between Table Scan and Receipt Scan
  bool _isFlashOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleScannedValue(String rawValue) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _scannerController.stop();

    if (_isTableMode) {
      _processTableScan(rawValue);
    } else {
      _processReceiptScan(rawValue);
    }
  }

  Future<void> _processTableScan(String value) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Warna.primary),
        ),
      ),
    );

    String? storeId;
    String? storeName;
    String? tableParam;

    try {
      final uri = Uri.parse(value);
      if (uri.queryParameters.containsKey('store_id')) {
        storeId = uri.queryParameters['store_id'];
      } else if (uri.queryParameters.containsKey('store_name')) {
        storeName = uri.queryParameters['store_name'];
      }
      if (uri.queryParameters.containsKey('table')) {
        tableParam = uri.queryParameters['table'];
      }
    } catch (_) {
      final parts = value.split('-');
      if (parts.length >= 3 && parts[0].toUpperCase() == 'MEJA') {
        storeName = parts[1];
        tableParam = parts[2];
      } else if (parts.length == 2) {
        storeName = parts[0];
        tableParam = parts[1];
      } else {
        final uuidRegex = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
        if (uuidRegex.hasMatch(value)) {
          storeId = value;
        } else {
          storeName = value;
        }
      }
    }

    final supabase = Supabase.instance.client;

    // Resolve store
    Map<String, dynamic>? storeData;
    try {
      if (storeId != null) {
        storeData = await supabase
            .from('stores')
            .select('id, name')
            .eq('id', storeId)
            .maybeSingle();
      }
      
      if (storeData == null && storeName != null) {
        final results = await supabase
            .from('stores')
            .select('id, name')
            .ilike('name', '%$storeName%')
            .limit(1);
        if (results.isNotEmpty) {
          storeData = results.first;
        }
      }
    } catch (e) {
      debugPrint('Error fetching store: $e');
    }

    // Dismiss loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (storeData == null) {
      if (mounted) {
        showShadDialog(
          context: context,
          builder: (context) => ShadDialog(
            title: const Text('Toko Tidak Ditemukan'),
            description: Text('Tidak dapat menemukan gerai toko untuk "$value".'),
            actions: [
              ShadButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isProcessing = false);
                  _scannerController.start();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final resolvedStoreId = storeData['id'] as String;
    final resolvedStoreName = storeData['name'] as String;

    // Resolve table
    String? tableId;
    String resolvedTableName = tableParam ?? 'Umum';

    if (tableParam != null) {
      try {
        final tableResults = await supabase
            .from('tables')
            .select('id, name')
            .eq('store_id', resolvedStoreId)
            .ilike('name', tableParam)
            .limit(1);
        if (tableResults.isNotEmpty) {
          tableId = tableResults.first['id'] as String;
          resolvedTableName = tableResults.first['name'] as String;
        } else {
          final tableResults2 = await supabase
              .from('tables')
              .select('id, name')
              .eq('store_id', resolvedStoreId)
              .ilike('name', '%$tableParam%')
              .limit(1);
          if (tableResults2.isNotEmpty) {
            tableId = tableResults2.first['id'] as String;
            resolvedTableName = tableResults2.first['name'] as String;
          }
        }
      } catch (e) {
        debugPrint('Error fetching table: $e');
      }
    }

    if (mounted) {
      showShadDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ShadDialog(
          title: const Text('Meja Teridentifikasi!'),
          description: Text(
              'Apakah Anda berada di gerai "$resolvedStoreName" pada "$resolvedTableName"?'),
          actions: [
            ShadButton.outline(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isProcessing = false);
                _scannerController.start();
              },
              child: const Text('Batal'),
            ),
            ShadButton(
              backgroundColor: Warna.primary,
              onPressed: () async {
                Navigator.pop(context);
                
                // Set providers
                ref.read(customerStoreIdProvider.notifier).state = resolvedStoreId;
                ref.read(customerTableIdProvider.notifier).state = tableId;
                ref.read(customerTableNameProvider.notifier).state = resolvedTableName;

                // Auto join store_members
                final user = supabase.auth.currentUser;
                if (user != null) {
                  try {
                    await supabase.from('store_members').upsert({
                      'user_id': user.id,
                      'store_id': resolvedStoreId,
                      'role': 'Pelanggan',
                      'status': 'active',
                    }, onConflict: 'user_id,store_id');
                  } catch (e) {
                    debugPrint('Gagal gabung store member: $e');
                  }
                }

                if (mounted) {
                  context.go(
                    Uri(
                      path: '/customer/store-detail',
                      queryParameters: {
                        'store_id': resolvedStoreId,
                        'store_name': resolvedStoreName,
                      },
                    ).toString(),
                  );
                }
              },
              child: const Text('Mulai Pesan',
                  style: TextStyle(
                      color: Warna.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _processReceiptScan(String value) {
    String? orderId;
    String? transactionId;

    try {
      final uri = Uri.parse(value);
      if (uri.path.contains('/customer/order/')) {
        orderId = uri.pathSegments.last;
      } else if (uri.path.contains('/customer/receipt/')) {
        transactionId = uri.pathSegments.last;
      }
    } catch (_) {}

    if (orderId == null && transactionId == null) {
      if (value.toUpperCase().startsWith('ORD-')) {
        orderId = value;
      } else if (value.toUpperCase().startsWith('TX-')) {
        transactionId = value;
      } else {
        orderId = value;
      }
    }

    final isOrder = orderId != null;
    final displayId = orderId ?? transactionId ?? 'Unknown';

    showShadDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShadDialog(
        title: const Text('Struk Terdeteksi!'),
        description: Text('Apakah Anda ingin melacak atau melihat bukti transaksi untuk "$displayId"?'),
        actions: [
          ShadButton.outline(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
              _scannerController.start();
            },
            child: const Text('Batal'),
          ),
          ShadButton(
            backgroundColor: Warna.primary,
            onPressed: () {
              Navigator.pop(context);
              if (isOrder) {
                context.go('/customer/order/$orderId');
              } else {
                context.go('/customer/receipt/$transactionId');
              }
            },
            child: const Text('Lihat Detail', style: TextStyle(color: Warna.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showManualInputSheet() {
    _scannerController.stop();
    final controller = TextEditingController();
    
    showShadDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShadDialog(
        title: Text(_isTableMode ? 'Input Meja Manual' : 'Input Kode Struk Manual'),
        description: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isTableMode 
                ? 'Masukkan nama gerai & nomor meja (Format: Gerai-Meja, contoh: KopiKuno-05)'
                : 'Masukkan ID Pesanan atau Transaksi (contoh: ORD-12345)',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: controller,
              placeholder: Text(_isTableMode ? 'Contoh: KopiKuno-05' : 'Contoh: ORD-12345'),
            ),
          ],
        ),
        actions: [
          ShadButton.outline(
            onPressed: () {
              Navigator.pop(context);
              _scannerController.start();
            },
            child: const Text('Batal'),
          ),
          ShadButton(
            backgroundColor: Warna.primary,
            onPressed: () {
              final inputVal = controller.text.trim();
              if (inputVal.isNotEmpty) {
                Navigator.pop(context);
                _handleScannedValue(inputVal);
              }
            },
            child: const Text('Proses', style: TextStyle(color: Warna.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Mobile Scanner Camera Preview
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_isProcessing) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _handleScannedValue(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),

          // 2. Custom Finder Overlay Cutout
          Positioned.fill(
            child: _ScannerOverlay(isTableMode: _isTableMode),
          ),

          // 3. Header Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(TablerIcons.chevron_left, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                // Title
                const Text(
                  'Pindai QR / Barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
                // Torch Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flashlight_on : Icons.flashlight_off,
                      color: _isFlashOn ? Warna.primary : Colors.white,
                    ),
                    onPressed: () {
                      _scannerController.toggleTorch();
                      setState(() => _isFlashOn = !_isFlashOn);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. Mode Tab Selector (Dine-in Table vs Receipt)
          Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black87.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_isTableMode) {
                          setState(() => _isTableMode = true);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isTableMode ? Warna.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Scan Meja',
                            style: TextStyle(
                              color: _isTableMode ? Warna.black : Colors.white70,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_isTableMode) {
                          setState(() => _isTableMode = false);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isTableMode ? Warna.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Scan Struk',
                            style: TextStyle(
                              color: !_isTableMode ? Warna.black : Colors.white70,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Instruction text & Manual Input button
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Text(
                  _isTableMode
                      ? 'Dekatkan kamera ke kode QR Meja di gerai kami'
                      : 'Arahkan kamera ke Barcode / QR Code pada struk belanja Anda',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Manual input fallback button
                InkWell(
                  onTap: _showManualInputSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(TablerIcons.keyboard, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Masukkan Kode Manual',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final bool isTableMode;
  const _ScannerOverlay({required this.isTableMode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scanAreaWidth = size.width * 0.7;
    final double scanAreaHeight = isTableMode ? size.width * 0.7 : size.width * 0.45;

    return Stack(
      children: [
        // Cutout background
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: scanAreaWidth,
                  height: scanAreaHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Glowing Focus Target Frame
        Align(
          alignment: Alignment.center,
          child: Container(
            width: scanAreaWidth,
            height: scanAreaHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Warna.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Warna.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
