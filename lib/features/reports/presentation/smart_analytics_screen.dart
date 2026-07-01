import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  const SmartAnalyticsScreen({super.key});

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

  // AI Calibration States
  bool _hasAgreed = false;
  bool _isCalibrating = false;
  double _calibrationProgress = 0.0;
  String _calibrationStepText = "Menunggu...";
  int _newTransactionCount = 8; // Memulai simulasi dengan 8 data transaksi baru

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartAnalyticsProvider.notifier).loadSmartAnalytics(_selectedTab);
    });
  }

  Future<void> _startCalibration() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id']?.toString() ?? 'unknown';
    await AnalyticsService.instance.logAICalibration(storeId: storeId);

    setState(() {
      _isCalibrating = true;
      _calibrationProgress = 0.0;
      _calibrationStepText = "Mempersiapkan data transaksi...";
    });

    // Step 1 & 2 — animasi lokal sebelum network call dimulai
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _calibrationProgress = 0.2;
      _calibrationStepText =
          "Menyeleksi & membersihkan data transaksi harian khusus toko...";
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _calibrationProgress = 0.35;
      _calibrationStepText =
          "Mengompresi & mengunggah data transaksional ke Python Server...";
    });

    // Mulai kalibrasi nyata: fetch Supabase + latih LSTM di server Python
    // Future ini berjalan bersamaan dengan animasi step berikutnya
    final calibrationFuture =
        ref.read(smartAnalyticsProvider.notifier).calibrateModel();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _calibrationProgress = 0.55;
      _calibrationStepText =
          "Melatih model LSTM terpisah khusus Toko (Isolated Model)...";
    });

    // Tunggu sampai pelatihan LSTM di server benar-benar selesai
    await calibrationFuture;
    if (!mounted) return;

    // Step 4-5 — animasi penutup setelah kalibrasi selesai
    setState(() {
      _calibrationProgress = 0.88;
      _calibrationStepText =
          "Menyimpan file model terkompresi (.h5) ke Cloud Storage Registry...";
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _calibrationProgress = 1.0;
      _calibrationStepText =
          "Menyelesaikan kalibrasi & memuat model untuk proyeksi 30 hari...";
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _isCalibrating = false;
      _newTransactionCount = 0;
    });

    mySnackBar(
      context: context,
      text:
          'Kalibrasi AI Selesai! Model LSTM telah disesuaikan dengan pola penjualan unik toko Anda.',
      status: ToastStatus.success,
    );
  }

  void _showAgreementDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                TablerIcons.brain,
                color: Color(0xFF6B4EFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Persetujuan Latihan AI'),
          ],
        ),
        description: const Text(
          'Untuk menyelaraskan AI dengan karakteristik unik toko Anda, sistem memerlukan persetujuan pemrosesan data historis.',
          style: TextStyle(fontSize: 12),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogBullet(
                TablerIcons.shield_lock,
                'Privasi Terjamin & Terenkripsi',
                'Data pribadi pelanggan dan detail nomor pembayaran sama sekali tidak diunggah atau disimpan.',
              ),
              const SizedBox(height: 12),
              _buildDialogBullet(
                TablerIcons.server,
                'Model LSTM Terisolasi (Per Toko)',
                'Server Python melatih model LSTM terpisah secara mandiri untuk toko Anda untuk menjaga privasi data antar owner.',
              ),
              const SizedBox(height: 12),
              _buildDialogBullet(
                TablerIcons.chart_dots_3,
                'Penyimpanan Model & Inferensi',
                'Model spesifik toko (.h5) disimpan di Cloud Registry. Prediksi dihitung real-time dari 14 hari transaksi terakhir (lookback).',
              ),
            ],
          ),
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ShadButton(
            backgroundColor: const Color(0xFF6B4EFF),
            hoverBackgroundColor: const Color(0xFF523BFF),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _hasAgreed = true;
              });
              _startCalibration();
            },
            child: const Text('Setuju & Mulai Latihan'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBullet(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B4EFF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Trigger real database load / mock LSTM reload
  Future<void> _simulateAiReload() async {
    setState(() {
      _isLoading = true;
    });

    await ref.read(smartAnalyticsProvider.notifier).loadSmartAnalytics(_selectedTab);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      mySnackBar(
        context: context,
        text:
            'AI Berhasil Sinkron! Analisis perkiraan penjualan terbaru telah diperbarui.',
        status: ToastStatus.success,
      );
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
            ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF9B72CB),
                      Color(0xFFD96570),
                    ],
                  ).createShader(bounds),
                  child: const Icon(
                    TablerIcons.brain,
                    color: Colors.white,
                    size: 26,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  duration: 1.5.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                )
                .shimmer(delay: 1.seconds, duration: 1.5.seconds),
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
          if (!_isLocked)
            IconButton(
              icon: const Icon(TablerIcons.sparkles, color: Warna.primary),
              tooltip: 'Picu Analisis AI',
              onPressed: state.isLoading || _isLoading ? null : _simulateAiReload,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _simulateAiReload,
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
                    _buildCalibrationCard(theme),
                    if (state.coldStartWarning.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildColdStartWarningBanner(theme, state.coldStartWarning),
                    ],
                    const SizedBox(height: 24),
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
                                        color: const Color(
                                          0xFF6B4EFF,
                                        ).withOpacity(0.08),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Animated Glowing Lock Icon
                                      Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF6B4EFF),
                                                  Color(0xFF8A6BFF),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF6B4EFF,
                                                  ).withOpacity(0.3),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              TablerIcons.lock,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .scale(
                                            duration: 2.seconds,
                                            begin: const Offset(0.92, 0.92),
                                            end: const Offset(1.08, 1.08),
                                          )
                                          .shimmer(
                                            delay: 1.seconds,
                                            duration: 1.5.seconds,
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
                                          color: const Color(
                                            0xFF6B4EFF,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF6B4EFF,
                                            ).withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              TablerIcons.sparkles,
                                              color: Color(0xFF6B4EFF),
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.aiProFeature,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF6B4EFF),
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
    final hasTrained = state.isCalibrated;
    final isLocked = hasTrained && _newTransactionCount < 20;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCalibrating
              ? const Color(0xFF6B4EFF).withOpacity(0.4)
              : const Color(0xFF6B4EFF).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCalibrating
                    ? TablerIcons.brain
                    : isLocked
                    ? TablerIcons.circle_check
                    : TablerIcons.sparkles,
                color: isLocked ? Warna.success : const Color(0xFF6B4EFF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isCalibrating
                      ? 'Mengkalibrasi Model AI...'
                      : hasTrained
                      ? 'Model AI Terkalibrasi Aktif'
                      : 'Model AI Belum Dikalibrasi',
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (hasTrained && !_isCalibrating && state.lastCalibrationTime != null)
                Text(
                  'Terakhir: ${DateFormat('dd/MM HH:mm').format(state.lastCalibrationTime!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isCalibrating) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _calibrationStepText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B4EFF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_calibrationProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4EFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _calibrationProgress,
                backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6B4EFF),
                ),
                minHeight: 4,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    isLocked
                        ? 'Simulasi data baru: $_newTransactionCount / 20'
                        : 'Latih model dengan transaksi terbaru agar estimasi optimal.',
                    style: TextStyle(
                      fontSize: 10,
                      color: isLocked
                          ? Colors.grey.shade600
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isLocked)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _newTransactionCount += 5;
                      });
                      mySnackBar(
                        context: context,
                        text: '+5 Transaksi baru disimulasikan ke toko.',
                        status: ToastStatus.success,
                      );
                    },
                    child: const Text(
                      '+ Simulasikan +5',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B4EFF),
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            if (isLocked) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_newTransactionCount / 20).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Warna.success.withOpacity(0.8),
                  ),
                  minHeight: 3,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ShadButton(
                width: double.infinity,
                backgroundColor: isLocked
                    ? Colors.grey.shade100
                    : const Color(0xFF6B4EFF),
                hoverBackgroundColor: isLocked
                    ? Colors.grey.shade100
                    : const Color(0xFF523BFF),
                foregroundColor: isLocked ? Colors.grey.shade400 : Colors.white,
                onPressed: isLocked
                    ? null
                    : () {
                        if (!_hasAgreed) {
                          _showAgreementDialog();
                        } else {
                          _startCalibration();
                        }
                      },
                child: Text(
                  hasTrained
                      ? 'Latih Ulang Model AI'
                      : 'Mulai Latih & Kalibrasi AI',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
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
          ref.read(smartAnalyticsProvider.notifier).loadSmartAnalytics(tab);
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
                state.trafficPeak,
                TablerIcons.users,
                const Color(0xFF4285F4),
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildKPICardWide(
          'Prediksi Produk Terlaris Utama',
          state.bestSellingName,
          state.bestSellingEst,
          TablerIcons.crown,
          const Color(0xFFFF9E00),
          theme,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildKPICard(
    String title,
    String value,
    String subtitle,
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
      ),
    );
  }

  Widget _buildKPICardWide(
    String title,
    String value,
    String subtitle,
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
                  color: const Color(0xFF4285F4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  TablerIcons.presentation_analytics,
                  color: Color(0xFF4285F4),
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
                            color: Color(0xFF4285F4),
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
                            color: isForecast
                                ? const Color(0xFF9AE600)
                                : Colors.white,
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
                  // Forecasted dotted line (blue)
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: const Color(0xFF4285F4),
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
                            strokeColor: const Color(0xFF4285F4),
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4285F4).withOpacity(0.15),
                          const Color(0xFF4285F4).withOpacity(0.0),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF9B72CB)],
                  ).createShader(bounds),
                  child: const Icon(
                    TablerIcons.trending_up,
                    color: Colors.white,
                    size: 22,
                  ),
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
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: const Text(
                'AI PRO',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.purple,
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
                  color: badgeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(rec['icon'] as IconData, size: 10, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      rec['badge'] as String,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(TablerIcons.sparkles, size: 12, color: Colors.purple),
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final p = products[index];
            final scorePercent = ((p['confidence'] as double) * 100).toInt();
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
                    decoration: BoxDecoration(
                      color: (p['trendColor'] as Color).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      p['icon'] as IconData,
                      color: p['trendColor'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: (p['trendColor'] as Color).withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p['trend'] as String,
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: p['trendColor'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Est: ${p['quantity']} unit terjual',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '|',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$scorePercent% Keyakinan AI',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.purple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Mini Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: p['confidence'] as double,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.purple,
                            ),
                            minHeight: 4,
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
        const SizedBox(height: 24),
        _buildSeasonalAlertCard(theme),
      ],
    );
  }

  Widget _buildSeasonalAlertCard(ShadThemeData theme) {
    final state = ref.watch(smartAnalyticsProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4285F4).withOpacity(0.08),
            Colors.purple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.sun, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Seasonal & Weather Insight',
                style: theme.textTheme.large.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.weatherInsight,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
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
