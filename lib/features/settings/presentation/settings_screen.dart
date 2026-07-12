import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';
import 'package:pos_mobile/core/ads/banner_ad_widget.dart';

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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeStore.value != null)
                    _buildStoreHeader(context, theme, activeStore.value!)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
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
                      TablerIcons.packages,
                      l10n.manageStock,
                      () => context.push('/stock'),
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
                      TablerIcons.history,
                      Localizations.localeOf(context).languageCode == 'id'
                          ? 'Riwayat Stok'
                          : 'Stock History',
                      () => context.push('/stock/history'),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildMenuSection(theme, l10n.storeSettings, [
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
                      TablerIcons.bell_ringing,
                      l10n.notificationSettings,
                      () => context.push('/notification-settings'),
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
                      TablerIcons.speakerphone,
                      l10n.broadcastNotification,
                      () => context.push('/broadcast-notification'),
                    ),
                    if (isAdmin) ...[
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
                      ),
                    ],
                  ]),
                  const SizedBox(height: 32),
                  _buildMenuSection(theme, l10n.accountAndSecurity, [
                    _buildMenuItem(
                      context,
                      theme,
                      TablerIcons.user,
                      l10n.myProfile,
                      () => context.push('/profile'),
                    ),
                    _buildMenuItem(
                      context,
                      theme,
                      TablerIcons.lock,
                      l10n.changePassword,
                      () => context.push('/setup-password'),
                    ),
                    _buildMenuItem(
                      context,
                      theme,
                      TablerIcons.refresh,
                      l10n.dataSynchronization,
                      () => context.push('/settings/sync-monitoring'),
                    ),
                    _buildMenuItem(
                      context,
                      theme,
                      TablerIcons.language,
                      l10n.language,
                      () => _showLanguageSelector(context, ref, currentLocale),
                      trailingText: l10n.languageName,
                    ),
                    if (role?.toLowerCase() == 'karyawan')
                      _buildMenuItem(
                        context,
                        theme,
                        TablerIcons.logout,
                        l10n.logoutStore,
                        () => _handleLeaveStore(context, ref, l10n),
                        color: Colors.redAccent,
                      ),
                  ]),
                  const SizedBox(height: 48),
                  ShadButton.destructive(
                    width: double.infinity,
                    onPressed: () => _handleLogout(context, ref, l10n),
                    child: Text(l10n.logoutApp),
                  ).animate().fadeIn(delay: 400.ms),
                  const Center(
                    child: BannerAdWidget(padding: EdgeInsets.only(top: 24)),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Antigravity POS • ${l10n.version} 1.0.0',
                      style: theme.textTheme.muted.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 85),
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
        color: Warna.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.primary.withOpacity(0.2)),
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
              color: theme.colorScheme.mutedForeground.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.border.withOpacity(0.5),
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
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              color?.withOpacity(0.1) ??
              theme.colorScheme.muted.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Colors.black, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.black,
        ),
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
            color: color?.withOpacity(0.5) ?? Colors.black26,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);

    await showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(l10n.selectLanguage),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(
                  context: context,
                  title: l10n.indonesian,
                  isSelected: currentLocale.languageCode == 'id',
                  theme: theme,
                  onTap: () {
                    ref.read(localeNotifierProvider.notifier).changeLocale('id');
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  context: context,
                  title: l10n.english,
                  isSelected: currentLocale.languageCode == 'en',
                  theme: theme,
                  onTap: () {
                    ref.read(localeNotifierProvider.notifier).changeLocale('en');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required ShadThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
            if (isSelected)
              Icon(
                TablerIcons.check,
                color: theme.colorScheme.primary,
                size: 18,
              )
            else
              const SizedBox(width: 18, height: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLeaveStore(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final user = ref.read(currentUserProvider);
    if (activeStore == null || user == null) return;

    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(l10n.logoutStore),
        description: Text(
          l10n.confirmLeaveStore(activeStore['name'] ?? ''),
        ),
        actions: [
          ShadButton.outline(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text(l10n.yesLeave),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final supabase = sb.Supabase.instance.client;
        await supabase
            .from('store_members')
            .delete()
            .eq('store_id', activeStore['id'])
            .eq('user_id', user.id);

        await ref.read(activeStoreProvider.notifier).clear();
        ref.invalidate(userStoresProvider);

        if (context.mounted) {
          context.go('/select-store');
          mySnackBar(
            context: context,
            text: l10n.leaveSuccess,
            status: ToastStatus.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          mySnackBar(
            context: context,
            text: l10n.leaveFailed(e.toString()),
            status: ToastStatus.error,
          );
        }
      }
    }
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
