import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/settings/models/subscription_model.dart';
import 'package:pos_mobile/features/settings/providers/subscription_provider.dart';
import 'package:pos_mobile/features/settings/services/in_app_purchase_service.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  String _selectedPlanId = 'pro_monthly';
  bool _isLoading = false;

  void _handleSelectPlan(SubscriptionPlan plan) async {
    final currentSub = ref.read(currentSubscriptionProvider).value;
    final userRole = ref.read(userRoleProvider);

    final l10n = AppLocalizations.of(context)!;

    // SECURITY CHECK: Hanya Store Owner yang diizinkan mengubah paket langganan toko
    if (userRole != null && userRole.toLowerCase() != 'owner') {
      mySnackBar(
        context: context,
        text: l10n.accessDeniedOwnerOnly,
        status: ToastStatus.error,
      );
      return;
    }

    // KETENTUAN 1: Klik pada paket yang saat ini sedang aktif
    if (currentSub?.planId == plan.id) {
      mySnackBar(
        context: context,
        text: l10n.subscriptionSuccess(plan.name),
        status: ToastStatus.info,
      );
      return;
    }

    // KETENTUAN 2: ANTI-LOSS DOWNGRADE (User sedang memiliki paket berbayar aktif dan mengklik paket Lite/Gratis)
    if (plan.price == 0) {
      if (currentSub != null && currentSub.isPaidActive) {
        final formattedExpiry = currentSub.expiresAt != null
            ? DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(currentSub.expiresAt!)
            : '-';

        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(TablerIcons.shield_check, color: Colors.blue, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.stillOnPaidPlanTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.stillOnPaidPlanDesc(currentSub.planName, formattedExpiry),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(TablerIcons.info_circle, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.stillOnPaidPlanNotice,
                          style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(l10n.understood, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }

      // Jika user memang di paket gratis dan klik paket gratis
      mySnackBar(
        context: context,
        text: l10n.alreadyOnFreePlan,
        status: ToastStatus.info,
      );
      return;
    }

    // KETENTUAN 3: Jika user sedang aktif paket berbayar lain dan mau ganti/upgrade ke paket berbayar baru
    final isChangingPaidPlan = currentSub != null && currentSub.isPaidActive;

    // Modal dialog konfirmasi pembelian via Google Play Store
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(TablerIcons.brand_google_play, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isChangingPaidPlan ? 'Ganti Paket Langganan' : 'Google Play Billing',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isChangingPaidPlan) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(TablerIcons.arrows_exchange, color: Colors.blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.changingPlanNotice(currentSub.planName, plan.name),
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.subscriptionFee, style: const TextStyle(color: Colors.black54)),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(plan.price)} ${plan.period}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(TablerIcons.shield_check, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.secureGooglePlayPayment,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(bottomSheetContext);
                _processGooglePlayPurchase(plan);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Warna.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(TablerIcons.brand_google_play, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.confirmViaGooglePlay('Rp ${NumberFormat('#,###', 'id_ID').format(plan.price)}'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(bottomSheetContext),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _processGooglePlayPurchase(SubscriptionPlan plan) async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final iapService = ref.read(inAppPurchaseServiceProvider);

      // Pastikan store / Google Play Billing tersedia
      final isAvailable = await iapService.isStoreAvailable();
      if (!isAvailable) {
        throw Exception(
          'Layanan Google Play Store tidak tersedia di perangkat ini atau akun Google belum terhubung.',
        );
      }

      // Luncurkan alur pembelian resmi Google Play Billing
      final purchaseLaunched = await iapService.buySubscription(plan);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (purchaseLaunched) {
        // Pembelian berhasil diinisiasi ke sistem Google Play,
        // aktivasi langganan akan diproses otomatis oleh listener ketika pembayaran sukses.
        mySnackBar(
          context: context,
          text: 'Memproses pembayaran Google Play Store...',
          status: ToastStatus.info,
        );
      } else {
        throw Exception('Gagal memulai transaksi Google Play Billing.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      mySnackBar(
        context: context,
        text: l10n.subscriptionFailed(e.toString().replaceAll('Exception: ', '')),
        status: ToastStatus.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(availablePlansProvider);
    final currentSubAsync = ref.watch(currentSubscriptionProvider);

    final currentSub = currentSubAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.chooseSubscriptionPlan,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.restorePurchases,
            icon: const Icon(TablerIcons.refresh, color: Colors.black),
            onPressed: () async {
              try {
                await ref.read(inAppPurchaseServiceProvider).restorePurchases();
                if (!context.mounted) return;
                mySnackBar(
                  context: context,
                  text: l10n.restorePurchasesSent,
                  status: ToastStatus.info,
                );
              } catch (e) {
                if (!context.mounted) return;
                mySnackBar(
                  context: context,
                  text: l10n.restorePurchasesFailed(e.toString()),
                  status: ToastStatus.error,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.black),
                  const SizedBox(height: 16),
                  Text(l10n.processingSubscription, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : plansAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(TablerIcons.alert_circle, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Gagal memuat paket langganan: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(availablePlansProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (plans) => SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // Header Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Warna.primary,
                            Warna.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Warna.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(TablerIcons.crown, color: Colors.black, size: 28),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tingkatkan Performa Bisnis Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dapatkan fitur eksklusif tanpa batas untuk mempercepat pertumbuhan dan kelola toko lebih efisien.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // List of Plans
                    ...plans.map((plan) {
                      final isSelected = _selectedPlanId == plan.id;
                      final isCurrentPlan = currentSub?.planId == plan.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: plan.isPopular
                                ? Warna.primary
                                : (isSelected
                                    ? Colors.black87
                                    : Colors.grey.withValues(alpha: 0.2)),
                            width: plan.isPopular || isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (plan.isPopular)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: const BoxDecoration(
                                  color: Warna.primary,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(TablerIcons.sparkles, size: 16, color: Colors.black),
                                    SizedBox(width: 6),
                                    Text(
                                      'PALING POPULER & TERBAIK',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (isCurrentPlan)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Paket Aktif',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    plan.tagline,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        plan.price == 0
                                            ? 'Gratis'
                                            : 'Rp ${NumberFormat('#,###', 'id_ID').format(plan.price)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                        ),
                                      ),
                                      if (plan.price > 0)
                                        Text(
                                          ' ${plan.period}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 28),
                                  // Features (sembunyikan Smart Analytics sementara)
                                  ...plan.features
                                      .where((feature) =>
                                          !feature.toLowerCase().contains('smart analytic') &&
                                          !feature.toLowerCase().contains('prediksi ai'))
                                      .map(
                                    (feature) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            TablerIcons.circle_check_filled,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              feature,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isCurrentPlan
                                          ? null
                                          : () {
                                              setState(() => _selectedPlanId = plan.id);
                                              _handleSelectPlan(plan);
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: plan.isPopular ? Warna.primary : Colors.black,
                                        foregroundColor: plan.isPopular ? Colors.black : Colors.white,
                                        disabledBackgroundColor: Colors.grey[200],
                                        disabledForegroundColor: Colors.grey[500],
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isCurrentPlan
                                            ? 'Sedang Digunakan'
                                            : (plan.price == 0
                                                ? (currentSub != null && currentSub.isPaidActive
                                                    ? 'Tersedia Otomatis Saat Expired'
                                                    : 'Pilih Paket')
                                                : (currentSub != null && currentSub.isPaidActive
                                                    ? 'Ganti ke Paket Ini'
                                                    : 'Langganan Sekarang')),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

