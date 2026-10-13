import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/settings/providers/subscription_provider.dart';
import 'package:pos_mobile/features/settings/models/subscription_model.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ManageSubscriptionScreen extends ConsumerWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentSubAsync = ref.watch(currentSubscriptionProvider);
    final plansAsync = ref.watch(availablePlansProvider);

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
          l10n.manageSubscription,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: currentSubAsync.when(
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
                Text(l10n.failedToLoadSubscription(err.toString()), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentSubscriptionProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (currentSub) {
          final plans = plansAsync.value ?? [];
          final activePlan = plans.where((p) => p.id == currentSub.planId).firstOrNull ??
              SubscriptionPlan(
                id: currentSub.planId,
                slug: 'lite',
                name: currentSub.planName,
                tagline: 'Solusi dasar untuk memulai bisnis digital.',
                price: 0,
                period: 'Gratis',
                googlePlayProductId: '',
                features: const [
                  'Maksimal 500 transaksi/bulan',
                  'Laporan penjualan standar',
                  'Manajemen meja & reservasi',
                ],
              );

          final isPro = currentSub.planId != 'b29dcf1a-4c25-4abc-9e98-d562746e0294' &&
              currentSub.planId != 'lite' &&
              currentSub.planId != 'free';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Subscription Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: isPro
                          ? const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isPro ? null : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isPro ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPro
                                        ? Warna.primary
                                        : Colors.grey.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPro ? TablerIcons.crown : TablerIcons.sparkles,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.subscriptionStatus,
                                  style: TextStyle(
                                    color: isPro ? Colors.white70 : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPro
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isPro ? Colors.green : Colors.blue,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isPro ? l10n.activeStatus : l10n.freeStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPro ? Colors.greenAccent : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          activePlan.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isPro ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activePlan.tagline,
                          style: TextStyle(
                            fontSize: 13,
                            color: isPro ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: isPro ? Colors.white24 : Colors.grey.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.validUntil,
                              style: TextStyle(
                                fontSize: 12,
                                color: isPro ? Colors.white60 : Colors.black45,
                              ),
                            ),
                            Text(
                              currentSub.expiresAt != null
                                  ? DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(currentSub.expiresAt!)
                                  : l10n.lifetimeFree,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isPro ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (isPro) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.paymentMethod,
                                style: const TextStyle(fontSize: 12, color: Colors.white60),
                              ),
                              Row(
                                children: [
                                  const Icon(TablerIcons.brand_google_play, size: 14, color: Colors.greenAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.googlePlayBilling,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final userRole = ref.read(userRoleProvider);
                        if (userRole != null && userRole.toLowerCase() != 'owner') {
                          mySnackBar(
                            context: context,
                            text: l10n.accessDeniedOwnerOnly,
                            status: ToastStatus.error,
                          );
                          return;
                        }
                        context.push('/subscription-plans');
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
                          const Icon(TablerIcons.sparkles, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isPro ? l10n.changeOrUpgradePlan : l10n.upgradeToPro,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/subscription-history'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(TablerIcons.history, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.subscriptionHistory,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Benefit Info Card
                  Text(
                    l10n.currentPlanFeatures,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: activePlan.features.map((feature) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(TablerIcons.check, size: 16, color: Colors.green),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // FAQ & Information Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(TablerIcons.info_circle, color: Colors.blue, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.aboutGooglePlaySubscription,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.aboutGooglePlaySubscriptionDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
