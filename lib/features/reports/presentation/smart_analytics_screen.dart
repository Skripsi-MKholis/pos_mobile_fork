import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/features/reports/providers/smart_analytics_provider.dart';

enum ForecastTab { daily, weekly, monthly, custom }

class SmartAnalyticsScreen extends ConsumerStatefulWidget {
  /// Jika diisi, layar menampilkan satu snapshot riwayat tertentu
  /// (read-only) alih-alih analisis terbaru toko.
  final String? snapshotId;

  const SmartAnalyticsScreen({super.key, this.snapshotId});

  @override
  ConsumerState<SmartAnalyticsScreen> createState() =>
      _SmartAnalyticsScreenState();
}

class _SmartAnalyticsScreenState extends ConsumerState<SmartAnalyticsScreen> {
  // ==========================================
  // CONFIGURATION: Lock Halaman / Coming Soon
  // ==========================================
  // Set true untuk mengunci halaman dengan efek blur & "Coming Soon"
  // Set false saat ingin melanjutkan development halaman ini
  static const bool _isLocked = false;
  // ==========================================

  ForecastTab _selectedTab = ForecastTab.daily;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(smartAnalyticsProvider.notifier);
      if (widget.snapshotId != null) {
        notifier.viewSnapshot(widget.snapshotId!, _selectedTab);
      } else {
        notifier.loadSmartAnalytics(_selectedTab);
      }
    });
  }

  // Menyegarkan analisis: mengambil ulang forecast terbaru dari model.
  // Model produksi bersifat stateless (baseline statistik), jadi ini murni
  // memuat ulang data — tidak ada training model per toko.
  Future<void> _refreshAnalytics() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id']?.toString() ?? 'unknown';
    await AnalyticsService.instance.logAICalibration(storeId: storeId);

    setState(() {
      _isLoading = true;
    });

    await ref
        .read(smartAnalyticsProvider.notifier)
        .refreshAnalytics(_selectedTab);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    mySnackBar(
      context: context,
      text: 'Analisis diperbarui dengan perkiraan terbaru dari model.',
      status: ToastStatus.success,
    );
  }

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Pull-to-refresh: sinkronkan ulang dari Supabase (snapshot terbaru atau
  // riwayat yang sedang dilihat). TIDAK memanggil model — cukup murah untuk
  // dipanggil berulang.
  Future<void> _syncLatest() async {
    setState(() {
      _isLoading = true;
    });

    final notifier = ref.read(smartAnalyticsProvider.notifier);
    if (widget.snapshotId != null) {
      await notifier.viewSnapshot(widget.snapshotId!, _selectedTab);
    } else {
      await notifier.loadSmartAnalytics(_selectedTab);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final state = ref.watch(smartAnalyticsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(TablerIcons.brain, color: Warna.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.smartAnalytics,
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLocked && widget.snapshotId == null)
            IconButton(
              icon: const Icon(TablerIcons.history, color: Warna.primary),
              tooltip: 'Riwayat Analisis',
              onPressed: () => context.push('/smart-analytics/history'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _syncLatest,
              color: Warna.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.isHistoryView && state.snapshotCreatedAt != null)
                      _buildHistoryBanner(theme, state.snapshotCreatedAt!)
                    else
                      _buildCalibrationCard(theme),
                    if (state.coldStartWarning.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildColdStartWarningBanner(theme, state.coldStartWarning),
                    ],
                    const SizedBox(height: 24),
                    if (!state.isLoading && !_isLoading && state.isEmpty)
                      _buildEmptyState(theme)
                    else ...[
                      _buildPeriodTabs(theme),
                      const SizedBox(height: 20),
                      state.isLoading || _isLoading
                          ? _buildShimmerKPIs(theme)
                          : _buildKPICards(theme),
                      const SizedBox(height: 20),
                      state.isLoading || _isLoading
                          ? _buildShimmerChartCard(theme)
                          : _buildSalesChartCard(theme),
                      const SizedBox(height: 24),
                      state.isLoading || _isLoading
                          ? _buildShimmerSection(theme, 130)
                          : _buildSmartPricingCarousel(theme),
                      const SizedBox(height: 24),
                      state.isLoading || _isLoading
                          ? _buildShimmerSection(theme, 240)
                          : _buildBestSellersAndTrends(theme),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
            if (_isLocked)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.white.withOpacity(0.3),
                      child:
                          Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.6),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Warna.primary.withOpacity(0.1),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: Warna.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          TablerIcons.lock,
                                          color: Warna.black,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // "Coming Soon" Title
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.comingSoon,
                                        style: theme.textTheme.h3.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          fontSize: 22,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Premium badge "AI Powered"
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Warna.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Warna.primary.withOpacity(0.25),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              TablerIcons.sparkles,
                                              color: Warna.black,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.aiProFeature,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Warna.black,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Friendly descriptive subtext
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.smartAnalyticsLockedDesc,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade600,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .scale(
                                duration: 500.ms,
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOutBack,
                              ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationCard(ShadThemeData theme) {
    final state = ref.watch(smartAnalyticsProvider);
    final hasRefreshed = !state.isEmpty;
    final isBusy = state.isLoading || _isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                TablerIcons.sparkles,
                color: Warna.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analisis Cerdas Penjualan',
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (hasRefreshed && state.snapshotCreatedAt != null)
                Text(
                  'Terakhir: ${DateFormat('dd/MM HH:mm').format(state.snapshotCreatedAt!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Perkiraan penjualan dihitung dari riwayat transaksi toko Anda. Segarkan untuk memuat perkiraan terbaru.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          // Status koneksi API server
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state.apiOnline ? Warna.success : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  state.apiOnline
                      ? 'Terhubung • ${state.apiServerLabel}'
                      : 'Terputus • ${state.apiServerLabel} (pakai estimasi lokal)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: state.apiOnline
                        ? Warna.success
                        : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Pemilihan server: Cloud (HuggingFace) atau Lokal
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildServerChip(
                  'Cloud (HF)',
                  !state.isLocalServer,
                  isBusy
                      ? null
                      : () => ref
                          .read(smartAnalyticsProvider.notifier)
                          .setServerMode(false, _selectedTab),
                ),
                _buildServerChip(
                  'Lokal',
                  state.isLocalServer,
                  isBusy
                      ? null
                      : () => ref
                          .read(smartAnalyticsProvider.notifier)
                          .setServerMode(true, _selectedTab),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ShadButton(
              width: double.infinity,
              backgroundColor: Warna.primary,
              foregroundColor: Warna.black,
              onPressed: isBusy ? null : _refreshAnalytics,
              leading: const Icon(TablerIcons.refresh, size: 14),
              child: Text(
                isBusy ? 'Memperbarui...' : 'Segarkan Analisis',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Banner ringkas saat menampilkan riwayat (read-only) — menggantikan
  // kartu kalibrasi/refresh yang tidak relevan untuk snapshot lama.
  Widget _buildHistoryBanner(ShadThemeData theme, DateTime createdAt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Warna.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Warna.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.history, size: 16, color: Warna.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Riwayat analisis • ${DateFormat('dd MMM yyyy, HH:mm').format(createdAt)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Warna.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ditampilkan saat toko belum pernah menjalankan Smart Analitik sama
  // sekali (belum ada snapshot di Supabase).
  Widget _buildEmptyState(ShadThemeData theme) {
    final isBusy = _isLoading;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Warna.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.chart_infographic,
              size: 32,
              color: Warna.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Analisis',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Toko Anda belum pernah menjalankan Smart Analitik. Jalankan analisis pertama untuk melihat perkiraan penjualan dan rekomendasi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 36,
            child: ShadButton(
              backgroundColor: Warna.primary,
              foregroundColor: Warna.black,
              onPressed: isBusy ? null : _refreshAnalytics,
              leading: const Icon(TablerIcons.sparkles, size: 14),
              child: Text(
                isBusy ? 'Menganalisis...' : 'Mulai Analisis Pertama',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerChip(String label, bool selected, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.black : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColdStartWarningBanner(ShadThemeData theme, String warning) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(TablerIcons.alert_triangle, color: Colors.amber.shade800, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.amber.shade900,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs(ShadThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton('Harian', ForecastTab.daily),
                _buildTabButton('Mingguan', ForecastTab.weekly),
                _buildTabButton('Bulanan', ForecastTab.monthly),
                _buildTabButton('Kustom', ForecastTab.custom),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String text, ForecastTab tab) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = tab;
          });
          final notifier = ref.read(smartAnalyticsProvider.notifier);
          if (widget.snapshotId != null) {
            notifier.viewSnapshot(widget.snapshotId!, tab);
          } else {
            notifier.loadSmartAnalytics(tab);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // --- KPI CARDS IMPLEMENTATION ---
  Widget _buildKPICards(ShadThemeData theme) {
    final state = ref.watch(smartAnalyticsProvider);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Estimasi Omzet',
                state.revenueText,
                state.revenueDiff,
                TablerIcons.coin,
                Warna.primary,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Estimasi Traffic',
                state.trafficText,
                null,
                TablerIcons.users,
                theme.colorScheme.mutedForeground,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildKPICardWide(
          'Prediksi Produk Terlaris Utama',
          state.bestSellingName,
          null,
          TablerIcons.crown,
          Warna.primary,
          theme,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildKPICard(
    String title,
    String value,
    String? subtitle,
    IconData icon,
    Color accentColor,
    ShadThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.muted.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.h4.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(TablerIcons.trending_up, size: 10, color: Warna.success),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKPICardWide(
    String title,
    String value,
    String? subtitle,
    IconData icon,
    Color accentColor,
    ShadThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.muted.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.large.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(TablerIcons.sparkles, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- CHART CARD IMPLEMENTATION ---
  Widget _buildSalesChartCard(ShadThemeData theme) {
    final state = ref.watch(smartAnalyticsProvider);
    final actualSpots = state.actualSpots;
    final forecastSpots = state.forecastSpots;
    final xLabels = state.xLabels;
    final maxY = state.maxY;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Warna.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  TablerIcons.presentation_analytics,
                  color: Warna.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Forecasting AI',
                      style: theme.textTheme.large.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Warna.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Riil',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Warna.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Prediksi AI (*)',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  TablerIcons.info_square_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () {
                  mySnackBar(
                    context: context,
                    text:
                        'Grafik Forecasting: Garis putus-putus = Proyeksi cerdas LSTM.',
                    status: ToastStatus.success,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        Colors.black.withOpacity(0.85),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isForecast = spot.barIndex == 1;
                        return LineTooltipItem(
                          '${isForecast ? "[AI] " : ""}${currencyFormat.format(spot.y)}',
                          TextStyle(
                            color: isForecast ? Warna.primary : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < xLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              xLabels[idx],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 24,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Actual solid line (green)
                  LineChartBarData(
                    spots: actualSpots,
                    isCurved: true,
                    color: Warna.success,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Warna.success,
                          ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Forecasted dotted line (primary/lime — proyeksi AI)
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: Warna.primary,
                    barWidth: 4,
                    dashArray: [6, 4],
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Warna.primary,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Warna.primary.withOpacity(0.2),
                          Warna.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // --- SMART PRICING RECOMMENDATIONS ---
  Widget _buildSmartPricingCarousel(ShadThemeData theme) {
    final state = ref.watch(smartAnalyticsProvider);
    final recs = state.pricingRecommendations;

    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  TablerIcons.trending_up,
                  color: Warna.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Pricing & Rekomendasi',
                  style: theme.textTheme.h4.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Warna.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Warna.primary.withOpacity(0.3)),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  fontSize: 8,
                  color: Warna.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final rec = recs[index];
              return _buildPricingCard(rec, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> rec, ShadThemeData theme) {
    final badgeColor = rec['color'] as Color;
    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(rec['icon'] as IconData, size: 10, color: Warna.black),
                    const SizedBox(width: 4),
                    Text(
                      rec['badge'] as String,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Warna.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(TablerIcons.sparkles, size: 12, color: Warna.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec['title'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            rec['desc'] as String,
            style: theme.textTheme.muted.copyWith(fontSize: 10, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  rec['rationale'] as String,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ShadButton(
                size: ShadButtonSize.sm,
                backgroundColor: Warna.black,
                hoverBackgroundColor: Colors.grey.shade900,
                onPressed: () {
                  mySnackBar(
                    context: context,
                    text:
                        'Rekomendasi "${rec['title']}" berhasil diterapkan ke modul diskon.',
                    status: ToastStatus.success,
                  );
                },
                child: const Text(
                  'Terapkan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BEST SELLING PRODUCTS & TRENDING CATEGORIES ---
  Widget _buildBestSellersAndTrends(ShadThemeData theme) {
    final state = ref.watch(smartAnalyticsProvider);
    final products = state.projectedBestSellers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  TablerIcons.package_export,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Proyeksi Menu Terlaris (Esok Hari)',
                  style: theme.textTheme.h4.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(TablerIcons.chart_pie, size: 18, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Text(
              'Belum ada data produk yang cukup untuk proyeksi.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = products[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.005),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Warna.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Warna.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Est: ${p['quantity']} unit terjual',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- SHIMMER loaders for trigger simulation ---
  Widget _buildShimmerKPIs(ShadThemeData theme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerChartCard(ShadThemeData theme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildShimmerSection(ShadThemeData theme, double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
