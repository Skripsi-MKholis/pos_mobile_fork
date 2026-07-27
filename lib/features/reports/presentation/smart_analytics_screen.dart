import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shimmer/shimmer.dart';

import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_tab.dart';
import 'package:pos_mobile/features/reports/models/tab_analytics_data.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/apply_recommendation_sheet.dart';
import 'package:pos_mobile/features/reports/presentation/widgets/recommendation_style.dart';
import 'package:pos_mobile/features/reports/providers/smart_analytics_provider.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

export 'package:pos_mobile/features/reports/models/forecast_tab.dart';

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
  static const bool _isLocked = false;
  // ==========================================

  ForecastTab _selectedTab = ForecastTab.daily;
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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

  /// Satu-satunya jalur yang benar-benar memanggil server model.
  Future<void> _refreshAnalytics() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id']?.toString() ?? 'unknown';
    await AnalyticsService.instance.logAICalibration(storeId: storeId);

    setState(() => _isLoading = true);
    await ref
        .read(smartAnalyticsProvider.notifier)
        .refreshAnalytics(_selectedTab);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final state = ref.read(smartAnalyticsProvider);
    mySnackBar(
      context: context,
      text: 'Analisis diperbarui — ${state.mode.label}.',
      status: state.mode.isLstm ? ToastStatus.success : ToastStatus.warning,
    );
  }

  /// Pull-to-refresh: hanya menyinkronkan ulang snapshot, tanpa memanggil model.
  Future<void> _syncLatest() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(smartAnalyticsProvider.notifier);
    if (widget.snapshotId != null) {
      await notifier.viewSnapshot(widget.snapshotId!, _selectedTab);
    } else {
      await notifier.loadSmartAnalytics(_selectedTab);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _selectTab(ForecastTab tab) {
    setState(() => _selectedTab = tab);
    final notifier = ref.read(smartAnalyticsProvider.notifier);
    if (widget.snapshotId != null) {
      notifier.viewSnapshot(widget.snapshotId!, tab);
    } else {
      notifier.loadSmartAnalytics(tab);
    }
  }

  /// Pemilih rentang tanggal untuk tab Kustom — dibatasi horizon model.
  Future<void> _pickCustomRange() async {
    final state = ref.read(smartAnalyticsProvider);
    final forecast = state.forecast;
    if (forecast == null || forecast.daily.isEmpty) {
      mySnackBar(
        context: context,
        text: 'Jalankan analisis dulu untuk menentukan rentang prediksi.',
        status: ToastStatus.warning,
      );
      return;
    }

    final dates = forecast.daily.map((p) => p.date).toList()..sort();
    final first = dates.first;
    final last = dates.last;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: DateTimeRange(
        start: state.customFrom ?? first,
        end:
            state.customTo ??
            (dates.length >= 3 ? dates[2] : last),
      ),
      helpText: 'Pilih rentang prediksi',
      saveText: 'Terapkan',
    );

    if (picked == null) return;
    ref
        .read(smartAnalyticsProvider.notifier)
        .setCustomRange(picked.start, picked.end);
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
          if (!_isLocked && widget.snapshotId == null) ...[
            IconButton(
              icon: const Icon(TablerIcons.target_arrow, color: Warna.primary),
              tooltip: 'Akurasi Model',
              onPressed: () => context.push('/smart-analytics/accuracy'),
            ),
            IconButton(
              icon: const Icon(TablerIcons.history, color: Warna.primary),
              tooltip: 'Riwayat Analisis',
              onPressed: () => context.push('/smart-analytics/history'),
            ),
          ],
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
                      _buildHistoryBanner(state.snapshotCreatedAt!)
                    else
                      _buildCalibrationCard(theme, state),
                    if (state.coldStartWarning.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildWarningBanner(state.coldStartWarning),
                    ],
                    const SizedBox(height: 24),
                    if (!state.isLoading && !_isLoading && state.isEmpty)
                      _buildEmptyState(theme)
                    else ...[
                      _buildPeriodTabs(),
                      if (_selectedTab == ForecastTab.custom) ...[
                        const SizedBox(height: 10),
                        _buildCustomRangeBar(state),
                      ],
                      const SizedBox(height: 20),
                      state.isLoading || _isLoading
                          ? _buildShimmerKPIs()
                          : _buildKPICards(theme, state),
                      const SizedBox(height: 20),
                      state.isLoading || _isLoading
                          ? _buildShimmerChartCard()
                          : _buildSalesChartCard(theme, state),
                      const SizedBox(height: 24),
                      state.isLoading || _isLoading
                          ? _buildShimmerSection(130)
                          : _buildRecommendationCarousel(theme, state),
                      const SizedBox(height: 24),
                      state.isLoading || _isLoading
                          ? _buildShimmerSection(240)
                          : _buildBestSellers(theme, state),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
            if (_isLocked) _buildLockOverlay(theme),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // Kartu status & kalibrasi
  // ================================================================
  Widget _buildCalibrationCard(ShadThemeData theme, SmartAnalyticsState state) {
    final hasRefreshed = !state.isEmpty;
    final isBusy = state.isLoading || _isLoading;
    final modeStyle = ForecastModeStyle.of(
      state.mode,
      isFromCache: state.isFromCache,
    );

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
              const Icon(TablerIcons.sparkles, color: Warna.primary, size: 18),
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
            'Perkiraan penjualan dihitung dari riwayat transaksi toko Anda. '
            'Segarkan untuk memuat perkiraan terbaru.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),

          // Status model — label mengikuti model yang benar-benar dipakai.
          Row(
            children: [
              Icon(modeStyle.icon, size: 13, color: modeStyle.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasRefreshed
                      ? modeStyle.label
                      : 'Belum ada analisis dijalankan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: modeStyle.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (state.modelVersion != null)
                Text(
                  state.modelVersion!,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: state.apiOnline ? Warna.success : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  state.apiOnline
                      ? 'Server: ${state.apiServerLabel}'
                      : 'Server: ${state.apiServerLabel} (tidak terhubung)',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (state.inputDays > 0)
                Text(
                  '${state.inputDays} hari data',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 8),

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

  Widget _buildHistoryBanner(DateTime createdAt) {
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
            'Toko Anda belum pernah menjalankan Smart Analitik. Jalankan '
            'analisis pertama untuk melihat perkiraan penjualan dan rekomendasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
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

  Widget _buildWarningBanner(String warning) {
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
          Icon(
            TablerIcons.alert_triangle,
            color: Colors.amber.shade800,
            size: 18,
          ),
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

  // ================================================================
  // Tab periode
  // ================================================================
  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final tab in ForecastTab.values) _buildTabButton(tab),
        ],
      ),
    );
  }

  Widget _buildTabButton(ForecastTab tab) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(tab),
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
            tab.label,
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

  Widget _buildCustomRangeBar(SmartAnalyticsState state) {
    final from = state.customFrom;
    final to = state.customTo;
    final format = DateFormat('dd MMM');
    final label = (from == null || to == null)
        ? 'Rentang bawaan: 3 hari ke depan'
        : '${format.format(from)} – ${format.format(to)}';

    return InkWell(
      onTap: _pickCustomRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(TablerIcons.calendar_event, size: 15, color: Warna.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Ubah',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // KPI
  // ================================================================
  Widget _buildKPICards(ShadThemeData theme, SmartAnalyticsState state) {
    final tab = state.tab;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Estimasi Omzet',
                tab.revenueText,
                tab.revenueDiff,
                TablerIcons.coin,
                Warna.primary,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Estimasi Traffic',
                tab.trafficText,
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
          'Produk Terlaris Saat Ini',
          state.bestSellingName,
          state.forecast?.peakHour == null
              ? null
              : 'Jam tersibuk diprediksi '
                    '${state.forecast!.peakHour!.hour.toString().padLeft(2, '0')}.00',
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
                Icon(
                  subtitle.startsWith('-')
                      ? TablerIcons.trending_down
                      : TablerIcons.trending_up,
                  size: 10,
                  color: subtitle.startsWith('-')
                      ? Colors.orange.shade700
                      : Warna.success,
                ),
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
                  Icon(TablerIcons.clock_hour_4, size: 14, color: accentColor),
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

  // ================================================================
  // Grafik
  // ================================================================
  Widget _buildSalesChartCard(ShadThemeData theme, SmartAnalyticsState state) {
    final tab = state.tab;
    final actual = tab.actualPoints;
    final forecast = tab.forecastPoints;
    final modeStyle = ForecastModeStyle.of(
      state.mode,
      isFromCache: state.isFromCache,
    );

    final hasInterval = tab.hasInterval;
    final lineBars = <LineChartBarData>[
      _actualBar(actual),
      _forecastBar(forecast),
      if (hasInterval) ..._intervalBars(forecast),
    ];

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
                      'Grafik Forecasting',
                      style: theme.textTheme.large.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _legendDot(Warna.success, 'Riil'),
                        const SizedBox(width: 10),
                        _legendDot(
                          Warna.primary,
                          '${modeStyle.label.split(' (').first} (*)',
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
                onPressed: () => mySnackBar(
                  context: context,
                  text:
                      'Garis solid = transaksi riil. Garis putus-putus (*) = '
                      'proyeksi ${state.mode.label}.',
                  status: ToastStatus.success,
                ),
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
                    getTooltipColor: (_) => Colors.black.withOpacity(0.85),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (spots) => spots.map((spot) {
                      // Bar interval (indeks 2/3) tidak perlu tooltip.
                      if (spot.barIndex >= 2) return null;

                      final isForecast = spot.barIndex == 1;
                      final points = isForecast ? forecast : actual;
                      final point = spot.spotIndex < points.length
                          ? points[spot.spotIndex]
                          : null;

                      if (!isForecast && point != null && !point.hasActual) {
                        return const LineTooltipItem(
                          'Tidak ada transaksi',
                          TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }

                      final prefix = isForecast
                          ? '[${state.mode.shortLabel}] '
                          : '';
                      return LineTooltipItem(
                        '$prefix${currencyFormat.format(spot.y)}',
                        TextStyle(
                          color: isForecast ? Warna.primary : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                  handleBuiltInTouches: true,
                ),
                betweenBarsData: hasInterval
                    ? [
                        BetweenBarsData(
                          fromIndex: 2,
                          toIndex: 3,
                          color: Warna.primary.withOpacity(0.12),
                        ),
                      ]
                    : const [],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
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
                        if (idx < 0 || idx >= tab.xLabels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            tab.xLabels[idx],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: lineBars,
                minY: 0,
                maxY: tab.maxY,
              ),
            ),
          ),
          if (tab.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  TablerIcons.info_circle,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tab.note,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.grey.shade500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  LineChartBarData _actualBar(List<ChartPoint> points) {
    return LineChartBarData(
      spots: [for (final p in points) FlSpot(p.x, p.y)],
      isCurved: true,
      color: Warna.success,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          // Hari tanpa transaksi digambar berongga agar terlihat berbeda
          // dari hari yang omzetnya memang nol-kecil.
          final hasActual =
              index < points.length ? points[index].hasActual : true;
          return FlDotCirclePainter(
            radius: 3,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: hasActual ? Warna.success : Colors.grey.shade300,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  LineChartBarData _forecastBar(List<ChartPoint> points) {
    return LineChartBarData(
      spots: [for (final p in points) FlSpot(p.x, p.y)],
      isCurved: true,
      color: Warna.primary,
      barWidth: 4,
      dashArray: [6, 4],
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: Warna.primary,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  /// Dua garis tak terlihat sebagai batas pita interval prediksi.
  List<LineChartBarData> _intervalBars(List<ChartPoint> points) {
    LineChartBarData bar(double? Function(ChartPoint) pick) {
      return LineChartBarData(
        spots: [for (final p in points) FlSpot(p.x, pick(p) ?? p.y)],
        isCurved: true,
        color: Colors.transparent,
        barWidth: 0,
        dotData: const FlDotData(show: false),
      );
    }

    return [bar((p) => p.low), bar((p) => p.high)];
  }

  // ================================================================
  // Rekomendasi
  // ================================================================
  Widget _buildRecommendationCarousel(
    ShadThemeData theme,
    SmartAnalyticsState state,
  ) {
    final recs = state.recommendations;
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
              child: Text(
                state.mode.shortLabel,
                style: const TextStyle(
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
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) =>
                _buildRecommendationCard(recs[index], state, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    ForecastRecommendation rec,
    SmartAnalyticsState state,
    ShadThemeData theme,
  ) {
    final style = RecommendationStyle.of(rec.kind);
    final description = _recommendationDescription(rec);
    // Hanya rekomendasi harga yang bisa dijadikan voucher.
    final canApply = rec.kind == 'happy_hour' && !state.isHistoryView;

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
                  color: style.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: style.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(style.icon, size: 10, color: Warna.black),
                    const SizedBox(width: 4),
                    Text(
                      rec.badge,
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
            rec.title,
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
            description,
            style: theme.textTheme.muted.copyWith(fontSize: 10, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  rec.rationale,
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
              if (canApply)
                ShadButton(
                  size: ShadButtonSize.sm,
                  backgroundColor: Warna.black,
                  hoverBackgroundColor: Colors.grey.shade900,
                  onPressed: () => _applyRecommendation(rec, state),
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

  /// Deskripsi rekomendasi dirangkai di sisi UI agar angka rupiah mengikuti
  /// format lokal perangkat, bukan disimpan sebagai teks jadi di database.
  String _recommendationDescription(ForecastRecommendation rec) {
    if (rec.desc.isNotEmpty) return rec.desc;

    switch (rec.kind) {
      case 'target_omzet':
        final moderate = (rec.payload['moderate'] as num?)?.toDouble();
        final aggressive = (rec.payload['aggressive'] as num?)?.toDouble();
        final parts = <String>[
          if (moderate != null)
            'Target moderat: ${currencyFormat.format(moderate)}',
          if (aggressive != null)
            'target agresif: ${currencyFormat.format(aggressive)}',
        ];
        return parts.isEmpty ? '—' : '${parts.join('. ')}.';
      case 'restock':
        final qty = (rec.payload['recommended_qty'] as num?)?.toInt();
        return qty == null ? '—' : 'Saran pembelian: $qty unit.';
      case 'happy_hour':
        final percent = (rec.payload['discount_percent'] as num?)?.toInt();
        final from = (rec.payload['hour_from'] as num?)?.toInt();
        final to = (rec.payload['hour_to'] as num?)?.toInt();
        if (percent == null) return '—';
        if (from == null || to == null) return 'Diskon $percent%.';
        return 'Diskon $percent% pada jam '
            '${from.toString().padLeft(2, '0')}.00–'
            '${to.toString().padLeft(2, '0')}.00.';
      default:
        return '—';
    }
  }

  Future<void> _applyRecommendation(
    ForecastRecommendation rec,
    SmartAnalyticsState state,
  ) async {
    final storeId = ref.read(activeStoreProvider).value?['id']?.toString();
    if (storeId == null) return;

    final voucher = await ApplyRecommendationSheet.show(
      context,
      recommendation: rec,
      storeId: storeId,
      snapshotId: state.snapshotId,
    );

    if (voucher == null || !mounted) return;
    mySnackBar(
      context: context,
      text:
          'Voucher ${voucher.code} (${voucher.percent.round()}%) dibuat, '
          'berlaku sampai ${formatVoucherExpiry(voucher.expiresAt)}.',
      status: ToastStatus.success,
    );
  }

  // ================================================================
  // Proyeksi produk
  // ================================================================
  Widget _buildBestSellers(ShadThemeData theme, SmartAnalyticsState state) {
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
                  'Proyeksi Produk Terlaris',
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
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildProductRow(products[index], index),
          ),
      ],
    );
  }

  Widget _buildProductRow(ProductDemand demand, int index) {
    final trendStyle = DemandTrendStyle.of(demand.trend);
    final qty = demand.recommendedQty > 0
        ? demand.recommendedQty
        : demand.predictedQty;

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
                  demand.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Est: $qty unit • ${demand.category}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(trendStyle.icon, size: 16, color: trendStyle.color),
        ],
      ),
    );
  }

  // ================================================================
  // Shimmer & overlay
  // ================================================================
  Widget _buildShimmerKPIs() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _shimmerBox(90)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(90)),
            ],
          ),
          const SizedBox(height: 12),
          _shimmerBox(60),
        ],
      ),
    );
  }

  Widget _buildShimmerChartCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: _shimmerBox(270, radius: 20),
    );
  }

  Widget _buildShimmerSection(double height) {
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
          _shimmerBox(height),
        ],
      ),
    );
  }

  Widget _shimmerBox(double height, {double radius = 16}) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  Widget _buildLockOverlay(ShadThemeData theme) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.white.withOpacity(0.3),
            child:
                Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
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
                              decoration: const BoxDecoration(
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
                            Text(
                              AppLocalizations.of(context)!.comingSoon,
                              style: theme.textTheme.h3.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Warna.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
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
                                    AppLocalizations.of(context)!.aiProFeature,
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
    );
  }
}
