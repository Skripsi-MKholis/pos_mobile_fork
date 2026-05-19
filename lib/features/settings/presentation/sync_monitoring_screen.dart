import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/providers/sync_provider.dart';
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

  int _unsyncedProducts = 0;
  int _unsyncedCategories = 0;
  int _unsyncedTransactions = 0;

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

    if (mounted) {
      setState(() {
        _unsyncedProducts = prodCount;
        _unsyncedCategories = catCount;
        _unsyncedTransactions = txCount;
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
      _syncStatusMessage = 'Sedang mensinkronisasikan data ke server...';
    });

    try {
      await ref.read(syncNotifierProvider.notifier).syncUnsynced();
      await _loadUnsyncedCounts();

      if (mounted) {
        setState(() {
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
          _syncStatusMessage = 'Terjadi kesalahan saat sinkronisasi: $e';
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
        _unsyncedProducts + _unsyncedCategories + _unsyncedTransactions;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Sinkronisasi Offline',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connectivity Status Card
              _buildConnectivityCard(
                isOnline,
                theme,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),

              // Sync Summary Status
              _buildSyncSummaryCard(totalUnsynced, theme)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              Text(
                'RINCIAN DATA BELUM TERSINKRON',
                style: theme.textTheme.muted.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Unsynced Breakdown Lists
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    title: 'Produk',
                    count: _unsyncedProducts,
                    icon: TablerIcons.package,
                    color: Colors.blue,
                    theme: theme,
                  ),
                  _buildStatCard(
                    title: 'Kategori',
                    count: _unsyncedCategories,
                    icon: TablerIcons.category,
                    color: Colors.orange,
                    theme: theme,
                  ),
                  _buildStatCard(
                    title: 'Transaksi',
                    count: _unsyncedTransactions,
                    icon: TablerIcons.receipt,
                    color: Warna.success,
                    theme: theme,
                  ),
                  _buildStatCard(
                    title: 'Semua Data',
                    count: totalUnsynced,
                    icon: TablerIcons.database,
                    color: Colors.purple,
                    theme: theme,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 28),

              // Sync Logs or Status Message Card
              if (_syncStatusMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Aktivitas',
                        style: theme.textTheme.muted.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _syncStatusMessage!,
                        style: theme.textTheme.p.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              _syncStatusMessage!.contains('gagal') ||
                                  _syncStatusMessage!.contains('kesalahan')
                              ? Warna.destructive
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 24),
              ],

              // Manual Sync Action Button
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: (_isSyncing || !isOnline) ? null : _handleSync,
                  backgroundColor: Warna.primary,
                  hoverBackgroundColor: Warna.primary.withValues(alpha: 0.8),
                  child: _isSyncing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Mensinkronkan...',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.refresh,
                              color: isOnline ? Colors.black : Colors.black38,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isOnline
                                  ? 'Sinkronkan Sekarang'
                                  : 'Offline - Tidak Bisa Sinkron',
                              style: TextStyle(
                                color: isOnline ? Colors.black : Colors.black38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(
                height: 120,
              ), // 120px to avoid floating navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectivityCard(bool isOnline, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline
            ? Warna.success.withValues(alpha: 0.08)
            : Warna.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? Warna.success.withValues(alpha: 0.2)
              : Warna.destructive.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOnline
                  ? Warna.success.withValues(alpha: 0.15)
                  : Warna.destructive.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? TablerIcons.wifi : TablerIcons.wifi_off,
              color: isOnline ? Warna.success : Warna.destructive,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Terhubung dengan Internet' : 'Mode Offline Aktif',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Aplikasi terhubung ke server. Data akan otomatis disinkronkan.'
                      : 'Transaksi tetap dapat dilakukan. Data akan tersimpan lokal di HP.',
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            allSynced ? TablerIcons.circle_check : TablerIcons.alert_circle,
            color: allSynced ? Warna.success : Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            allSynced ? 'Semua Data Tersinkronisasi' : 'Ada Data Belum Sinkron',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            allSynced
                ? 'Seluruh data transaksi dan produk di perangkat Anda telah sama dengan di server.'
                : 'Terdapat $totalUnsynced data yang tersimpan lokal di perangkat ini dan belum masuk ke server database.',
            textAlign: TextAlign.center,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required ShadThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Warna.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PENTING',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Warna.destructive,
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
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.muted.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
