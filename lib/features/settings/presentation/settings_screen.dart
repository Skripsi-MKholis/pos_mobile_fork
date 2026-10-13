import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';
import 'package:pos_mobile/core/ads/banner_ad_widget.dart';
import 'package:pos_mobile/core/guards/feature_guard.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider);
    final activeStore = ref.watch(activeStoreProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isAdmin =
        role?.toLowerCase() == 'owner' || user?.appMetadata['role'] == 'admin';

    final isIndonesian = currentLocale.languageCode == 'id';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeStore.value != null)
            _buildStoreHeader(
              context,
              theme,
              activeStore.value!,
            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 28),

          // 1. KATALOG & STOK
          _buildMenuSection(theme, l10n.catalogAndStock, [
            _buildMenuItem(
              context,
              theme,
              TablerIcons.package,
              l10n.productList,
              () => context.push('/products'),
            ),
            _buildMenuItem(
              context,
              theme,
              TablerIcons.category,
              l10n.productCategory,
              () => context.push('/categories'),
            ),
            _buildMenuItem(
              context,
              theme,
              TablerIcons.packages,
              l10n.manageStock,
              () => context.push('/stock'),
            ),
            _buildMenuItem(
              context,
              theme,
              TablerIcons.history,
              isIndonesian ? 'Riwayat Stok' : 'Stock History',
              () => context.push('/stock/history'),
            ),
          ]),
          const SizedBox(height: 28),

          // 2. OPERASIONAL & PERANGKAT
          _buildMenuSection(
            theme,
            isIndonesian ? 'OPERASIONAL & PERANGKAT' : 'DEVICES & HARDWARE',
            [
              _buildMenuItem(
                context,
                theme,
                TablerIcons.printer,
                l10n.printerConnection,
                () => context.push('/printer-settings'),
              ),
              _buildMenuItem(
                context,
                theme,
                TablerIcons.receipt,
                l10n.receiptCustomization,
                () => context.push('/receipt-customization'),
              ),
              _buildMenuItem(
                context,
                theme,
                TablerIcons.bell_ringing,
                l10n.notificationSettings,
                () => context.push('/notification-settings'),
              ),
              _buildMenuItem(
                context,
                theme,
                TablerIcons.speakerphone,
                l10n.broadcastNotification,
                () => context.push('/broadcast-notification'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 3. PENGELOLAAN TOKO (Owner / Admin)
          if (isAdmin) ...[
            _buildMenuSection(
              theme,
              isIndonesian ? 'PENGELOLAAN TOKO' : 'STORE MANAGEMENT',
              [
                _buildMenuItem(
                  context,
                  theme,
                  TablerIcons.building_store,
                  l10n.storeInformation,
                  () => context.push('/store-info'),
                ),
                _buildMenuItem(
                  context,
                  theme,
                  TablerIcons.users,
                  l10n.employeeManagement,
                  () => context.push('/staff-management'),
                  requiredFeature: AppFeature.staffManagement,
                  ref: ref,
                ),
                _buildMenuItem(
                  context,
                  theme,
                  TablerIcons.crown,
                  l10n.manageSubscription,
                  () => context.push('/subscription'),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],

          // 4. PENGATURAN APLIKASI & AKUN (Akses Menu Pengaturan Lengkap)
          _buildMenuSection(
            theme,
            isIndonesian ? 'PENGATURAN & AKUN' : 'APP & ACCOUNT',
            [
              _buildMenuItem(
                context,
                theme,
                TablerIcons.adjustments_horizontal,
                isIndonesian
                    ? 'Pengaturan Aplikasi & Akun'
                    : 'App & Account Settings',
                () => context.push('/app-settings'),
              ),
              _buildMenuItem(
                context,
                theme,
                TablerIcons.refresh,
                l10n.dataSynchronization,
                () => context.push('/sync-monitoring'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: BannerAdWidget(padding: EdgeInsets.symmetric(vertical: 4)),
          ),
          const SizedBox(height: 24),

          // Quick Logout Button
          ShadButton.destructive(
            width: double.infinity,
            onPressed: () => _handleLogout(context, ref, l10n),
            child: Text(l10n.logoutApp),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 20),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final appVersion = snapshot.data?.version ?? '';
                return Text(
                  'Zello POS • ${l10n.version} $appVersion',
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                );
              },
            ),
          ),
          // Jarak aman pas agar tidak tertutup floating bottom bar tanpa celah kosong berlebihan
          SizedBox(
            height: 80 + MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader(
    BuildContext context,
    ShadThemeData theme,
    Map<String, dynamic> store,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Warna.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Warna.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                store['logo_url'] != null &&
                    (store['logo_url'] as String).isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: store['logo_url'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      TablerIcons.building_store,
                      color: Colors.black,
                      size: 24,
                    ),
                  )
                : const Icon(
                    TablerIcons.building_store,
                    color: Colors.black,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['name'] ?? 'Toko Aktif',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  store['address'] ?? 'Alamat tidak diatur',
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () => context.push('/select-store'),
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    ShadThemeData theme,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.muted.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
              color: theme.colorScheme.mutedForeground.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    ShadThemeData theme,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    String? trailingText,
    AppFeature? requiredFeature,
    WidgetRef? ref,
  }) {
    final bool isLocked = requiredFeature != null &&
        ref != null &&
        !ref.watch(canAccessFeatureProvider(requiredFeature));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.black.withValues(alpha: 0.05)
              : (color?.withValues(alpha: 0.1) ??
                  theme.colorScheme.muted.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isLocked ? Colors.black38 : (color ?? Colors.black),
          size: 18,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.black38 : (color ?? Colors.black),
              ),
            ),
          ),
          if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(TablerIcons.lock, size: 10, color: Colors.amber),
                  SizedBox(width: 3),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: theme.textTheme.muted.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            TablerIcons.chevron_right,
            size: 16,
            color: color?.withValues(alpha: 0.5) ?? Colors.black26,
          ),
        ],
      ),
      onTap: () {
        if (isLocked) {
          showFeatureLockedDialog(context, requiredFeature);
          return;
        }
        onTap();
      },
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(l10n.confirmLogout),
        description: Text(l10n.confirmLogoutDesc),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text(l10n.yesLogout),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(activeStoreProvider.notifier).clear();
      await ref.read(authProvider.notifier).signOut();
    }
  }
}
