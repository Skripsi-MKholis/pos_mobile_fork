import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/models/stock_history.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/providers/sync_provider.dart';
import 'package:pos_mobile/features/product/providers/product_provider.dart';
import 'package:pos_mobile/features/product/providers/category_provider.dart';
import 'package:pos_mobile/features/product/providers/stock_history_provider.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';

class SyncMonitoringScreen extends ConsumerStatefulWidget {
  const SyncMonitoringScreen({super.key});

  @override
  ConsumerState<SyncMonitoringScreen> createState() =>
      _SyncMonitoringScreenState();
}

class _SyncMonitoringScreenState extends ConsumerState<SyncMonitoringScreen> {
  bool _isSyncing = false;
  String? _syncStatusMessage;
  int _activeStep = 0; // 0 = idle, 1 = auth, 2 = categories, 3 = products, 4 = transactions, 5 = stock history, 6 = finished, -1 = error

  int _unsyncedProducts = 0;
  int _unsyncedCategories = 0;
  int _unsyncedTransactions = 0;
  int _unsyncedStockHistory = 0;

  @override
  void initState() {
    super.initState();
    _loadUnsyncedCounts();
    // Refresh periodically
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      _loadUnsyncedCounts();
      return true;
    });
  }

  Future<void> _loadUnsyncedCounts() async {
    final isar = IsarService.instance;
    final prodCount = await isar
        .collection<Product>()
        .filter()
        .isSyncedEqualTo(false)
        .count();
    final catCount = await isar
        .collection<Category>()
        .filter()
        .isSyncedEqualTo(false)
        .count();
    final txCount = await isar
        .collection<TransactionLocal>()
        .filter()
        .isSyncedEqualTo(false)
        .count();
    final stockHistoryCount = await isar
        .collection<StockHistoryLocal>()
        .filter()
        .isSyncedEqualTo(false)
        .count();

    if (mounted) {
      setState(() {
        _unsyncedProducts = prodCount;
        _unsyncedCategories = catCount;
        _unsyncedTransactions = txCount;
        _unsyncedStockHistory = stockHistoryCount;
      });
    }
  }

  Future<void> _handleSync() async {
    final connectivity = ref.read(connectivityNotifierProvider).value;
    if (connectivity != ConnectivityStatus.online) {
      mySnackBar(
        context: context,
        text: 'Anda harus terhubung ke internet untuk sinkronisasi.',
        status: ToastStatus.error,
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncStatusMessage = 'Sedang menyelaraskan data dengan server cloud...';
      _activeStep = 1; // "Validasi Sesi Autentikasi"
    });

    try {
      final supabase = Supabase.instance.client;

      // Step 1: Validasi Sesi Autentikasi
      await supabase.ensureValidSession();
      
      setState(() {
        _activeStep = 2; // "Sinkronisasi Kategori"
      });
      await ref.read(syncNotifierProvider.notifier).syncCategories();
      
      setState(() {
        _activeStep = 3; // "Sinkronisasi Produk"
      });
      await ref.read(syncNotifierProvider.notifier).syncProducts();
      
      setState(() {
        _activeStep = 4; // "Sinkronisasi Transaksi"
      });
      await ref.read(syncNotifierProvider.notifier).syncTransactions();
      
      setState(() {
        _activeStep = 5; // "Sinkronisasi Riwayat Stok"
      });
      await ref.read(syncNotifierProvider.notifier).syncStockHistory();

      // Invalidate providers so UI gets fresh data
      ref.invalidate(productNotifierProvider);
      ref.invalidate(categoryNotifierProvider);
      ref.invalidate(stockHistoryProvider);

      await _loadUnsyncedCounts();

      if (mounted) {
        setState(() {
          _activeStep = 6; // Selesai
          _syncStatusMessage = 'Sinkronisasi selesai dengan sukses!';
        });
        mySnackBar(
          context: context,
          text: 'Semua data berhasil disinkronkan ke server.',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeStep = -1; // Error
          _syncStatusMessage = 'Sinkronisasi terhenti: $e';
        });
        mySnackBar(
          context: context,
          text: 'Sinkronisasi Gagal: ${e.toString()}',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final connectivity = ref.watch(connectivityNotifierProvider);
    final isOnline = connectivity.value == ConnectivityStatus.online;

    final totalUnsynced =
        _unsyncedProducts + _unsyncedCategories + _unsyncedTransactions + _unsyncedStockHistory;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Sinkronisasi Data',
          style: theme.textTheme.h4.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(TablerIcons.chevron_left, color: Colors.black87, size: 18),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/settings');
              }
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          // Elegant premium background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF9FAFC),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connectivity Status Card
                    _buildConnectivityCard(isOnline, theme)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 18),

                    // Sync Summary Status Card
                    _buildSyncSummaryCard(totalUnsynced, theme)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 24),

                    // Sync Progress Checklist (only visible when syncing or just finished)
                    if (_isSyncing || _activeStep > 0) ...[
                      _buildSyncStepsTimeline(theme)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'RINCIAN DATABASE LOKAL',
                      style: theme.textTheme.muted.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bento Grid of local database statistics
                    _buildBentoGrid(totalUnsynced, theme)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 30),

                    // Status Activity Log Card
                    if (_syncStatusMessage != null && !_isSyncing) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _activeStep == -1
                                    ? Warna.destructive.withValues(alpha: 0.1)
                                    : Warna.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _activeStep == -1 ? TablerIcons.alert_circle : TablerIcons.circle_check,
                                color: _activeStep == -1 ? Warna.destructive : Warna.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _activeStep == -1 ? 'Sinkronisasi Gagal' : 'Aktivitas Terakhir',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _syncStatusMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _activeStep == -1
                                          ? Warna.destructive
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),
                      const SizedBox(height: 24),
                    ],

                    // Manual Sync Action Button
                    _buildActionButton(isOnline)
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 400.ms),
                    
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityCard(bool isOnline, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Elegant pulsating/glowing connectivity dot indicator
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isOnline
                      ? Warna.success.withValues(alpha: 0.12)
                      : Warna.destructive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
              if (isOnline)
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Warna.success,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.15, 1.15), duration: 1000.ms, curve: Curves.easeInOut)
              else
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Warna.destructive,
                    shape: BoxShape.circle,
                  ),
                )
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOnline ? 'Terhubung Cloud' : 'Mode Offline Aktif',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isOnline ? TablerIcons.cloud_computing : TablerIcons.cloud_off,
                      size: 14,
                      color: isOnline ? Warna.success : Warna.destructive,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Server terhubung dengan lancar. Anda dapat menyelaraskan database kapan saja.'
                      : 'Transaksi tetap aman disimpan lokal di HP. Hubungkan ke internet untuk upload.',
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSummaryCard(int totalUnsynced, ShadThemeData theme) {
    final allSynced = totalUnsynced == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rotating or Glowing Icon Dial
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: allSynced
                        ? [Warna.success.withValues(alpha: 0.12), Colors.transparent]
                        : [Colors.amber.withValues(alpha: 0.12), Colors.transparent],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: allSynced
                      ? Warna.success.withValues(alpha: 0.1)
                      : Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allSynced ? TablerIcons.discount_check : TablerIcons.cloud_upload,
                  color: allSynced ? Warna.success : Colors.orange,
                  size: 32,
                ),
              ).animate(target: _isSyncing ? 1 : 0)
               .custom(
                 duration: 2000.ms,
                 builder: (context, value, child) => Transform.rotate(
                   angle: value * 6.28,
                   child: child,
                 ),
               ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            allSynced ? 'Database Tersinkronisasi' : 'Menunggu Sinkronisasi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              allSynced
                  ? 'Luar biasa! Seluruh data transaksi, riwayat stok, dan produk di perangkat ini telah tersimpan aman di server cloud.'
                  : 'Terdapat $totalUnsynced data baru di HP ini yang belum disinkronkan. Ketuk tombol di bawah untuk mengunggah.',
              textAlign: TextAlign.center,
              style: theme.textTheme.muted.copyWith(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStepsTimeline(ShadThemeData theme) {
    Widget buildStepRow(int stepNum, String title, bool isExecuting, bool isFinished, bool isError) {
      Widget statusIcon = Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.black12,
          shape: BoxShape.circle,
        ),
      );

      if (isFinished) {
        statusIcon = Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Warna.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(TablerIcons.check, color: Colors.white, size: 12),
        ).animate().scale(duration: 200.ms);
      } else if (isExecuting) {
        statusIcon = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Warna.primary,
          ),
        );
      } else if (isError) {
        statusIcon = const Icon(TablerIcons.x, color: Warna.destructive, size: 18);
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            statusIcon,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isExecuting || isFinished) ? FontWeight.w900 : FontWeight.w600,
                  color: isFinished
                      ? Colors.black87
                      : isExecuting
                          ? Colors.black87
                          : isError
                              ? Warna.destructive
                              : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROSES SINKRONISASI AKTIF',
            style: theme.textTheme.muted.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
              color: Warna.primary,
            ),
          ),
          const SizedBox(height: 14),
          buildStepRow(
            1,
            'Memvalidasi Sesi Autentikasi Cloud',
            _activeStep == 1,
            _activeStep > 1,
            _activeStep == -1,
          ),
          buildStepRow(
            2,
            'Sinkronisasi Kategori Produk',
            _activeStep == 2,
            _activeStep > 2,
            _activeStep == -1,
          ),
          buildStepRow(
            3,
            'Sinkronisasi Katalog Produk',
            _activeStep == 3,
            _activeStep > 3,
            _activeStep == -1,
          ),
          buildStepRow(
            4,
            'Sinkronisasi Riwayat Transaksi Penjualan',
            _activeStep == 4,
            _activeStep > 4,
            _activeStep == -1,
          ),
          buildStepRow(
            5,
            'Sinkronisasi Riwayat Stok Barang',
            _activeStep == 5,
            _activeStep > 5,
            _activeStep == -1,
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(int totalUnsynced, ShadThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildBentoCard(
                title: 'Kategori',
                count: _unsyncedCategories,
                icon: TablerIcons.category,
                glowColor: Colors.amber,
                theme: theme,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 1,
              child: _buildBentoCard(
                title: 'Katalog Produk',
                count: _unsyncedProducts,
                icon: TablerIcons.package,
                glowColor: Colors.blue,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildBentoCard(
                title: 'Transaksi',
                count: _unsyncedTransactions,
                icon: TablerIcons.receipt,
                glowColor: Warna.success,
                theme: theme,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 1,
              child: _buildBentoCard(
                title: 'Riwayat Stok',
                count: _unsyncedStockHistory,
                icon: TablerIcons.history,
                glowColor: Colors.purple,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String title,
    required int count,
    required IconData icon,
    required Color glowColor,
    required ShadThemeData theme,
  }) {
    final hasUnsynced = count > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasUnsynced
              ? glowColor.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.04),
          width: hasUnsynced ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          if (hasUnsynced)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: glowColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: glowColor, size: 18),
              ),
              if (hasUnsynced)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: glowColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: glowColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.muted.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isOnline) {
    return SizedBox(
      width: double.infinity,
      child: ShadButton(
        size: ShadButtonSize.lg,
        onPressed: (_isSyncing || !isOnline) ? null : _handleSync,
        backgroundColor: Warna.primary,
        hoverBackgroundColor: Warna.primary.withValues(alpha: 0.8),
        child: _isSyncing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Menyinkronkan...',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    TablerIcons.refresh,
                    color: isOnline ? Colors.black87 : Colors.black38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isOnline ? 'Sinkronkan Sekarang' : 'Offline - Sambungkan Internet',
                    style: TextStyle(
                      color: isOnline ? Colors.black87 : Colors.black38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
