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
          _buildUserProfileCard(
            context,
            ref,
            theme,
            l10n,
            user,
            role,
            activeStore.value,
            isIndonesian,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),

          // 1. PENGATURAN SISTEM & AKUN
          _buildMenuSection(
            theme,
            isIndonesian ? 'PENGATURAN SISTEM & AKUN' : 'SYSTEM & ACCOUNT',
            [
              _buildMenuItem(
                context,
                theme,
                TablerIcons.user_circle,
                isIndonesian ? 'Pengaturan Akun' : 'Account Settings',
                () => context.push('/account-settings'),
              ),
              _buildMenuItem(
                context,
                theme,
                TablerIcons.adjustments_horizontal,
                isIndonesian ? 'Pengaturan Aplikasi' : 'App Settings',
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
          const SizedBox(height: 28),

          // 2. PENGELOLAAN TOKO (Owner / Admin)
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
                  TablerIcons.calculator,
                  isIndonesian ? 'Laba & HPP Toko' : 'Profit & COGS Report',
                  () => context.push('/reports'),
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

          // 3. OPERASIONAL & PERANGKAT
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

  Widget _buildUserProfileCard(
    BuildContext context,
    WidgetRef ref,
    ShadThemeData theme,
    AppLocalizations l10n,
    dynamic user,
    String? role,
    Map<String, dynamic>? store,
    bool isIndonesian,
  ) {
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final fullName = user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        (isIndonesian ? 'Pengguna' : 'User');
    final roleFormatted = (role ?? 'Staff').toUpperCase();
    final isOwnerOrAdmin = role?.toLowerCase() == 'owner' ||
        user?.appMetadata['role'] == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.border.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bagian User Profile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Warna.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Warna.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: Text(
                                        fullName.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(
                                        fullName.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      fullName.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 18,
                            width: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.5,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwnerOrAdmin
                                      ? Warna.primary.withValues(alpha: 0.22)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isOwnerOrAdmin
                                        ? Warna.primary.withValues(alpha: 0.5)
                                        : Colors.grey.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  roleFormatted,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: isOwnerOrAdmin
                                        ? Colors.black87
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      TablerIcons.chevron_right,
                      size: 20,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider pemisah tipis
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.border.withValues(alpha: 0.4),
          ),

          // Bagian Toko Aktif (Klik untuk buka Info Toko, tombol switch untuk ganti toko)
          Material(
            color: Warna.primary.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: InkWell(
              onTap: () {
                if (store != null) {
                  context.push('/store-info');
                }
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: store != null &&
                              store['logo_url'] != null &&
                              (store['logo_url'] as String).isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: store['logo_url'],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(
                                TablerIcons.building_store,
                                color: Colors.black87,
                                size: 18,
                              ),
                            )
                          : const Icon(
                              TablerIcons.building_store,
                              color: Colors.black87,
                              size: 18,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isIndonesian ? 'Toko Aktif' : 'Active Store',
                                style: theme.textTheme.muted.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                TablerIcons.chevron_right,
                                size: 12,
                                color: theme.colorScheme.mutedForeground.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                          Text(
                            store?['name'] ?? (isIndonesian ? 'Tidak ada toko' : 'No active store'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: () => _showStoreSwitcher(context, ref, l10n, isIndonesian),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(TablerIcons.switch_horizontal, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            isIndonesian ? 'Ganti' : 'Switch',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoreSwitcher(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isIndonesian,
  ) {
    // Invalidate userStoresProvider agar mengambil data toko terbaru
    ref.invalidate(userStoresProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Indicator Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectStoreOutlet,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.selectStoreDescription,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      TablerIcons.x,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // Daftar Toko (Reaktif dengan Consumer)
            Flexible(
              child: Consumer(
                builder: (context, consumerRef, child) {
                  final storesAsync = consumerRef.watch(userStoresProvider);
                  final activeStore = consumerRef.watch(activeStoreProvider).value;

                  return storesAsync.when(
                    data: (stores) {
                      if (stores.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  TablerIcons.building_store,
                                  size: 32,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n.noStoreFound,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        itemCount: stores.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final s = stores[index];
                          final isSelected = activeStore?['id'] == s['id'];

                          return InkWell(
                            onTap: () {
                              consumerRef
                                  .read(activeStoreProvider.notifier)
                                  .selectStore(s);
                              Navigator.pop(sheetContext);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Warna.primary.withValues(alpha: 0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Warna.primary.withValues(alpha: 0.6)
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 44,
                                    width: 44,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: s['logo_url'] != null &&
                                            (s['logo_url'] as String).isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: s['logo_url'],
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) =>
                                                const Icon(
                                              TablerIcons.building_store,
                                              size: 22,
                                              color: Colors.black54,
                                            ),
                                          )
                                        : const Icon(
                                            TablerIcons.building_store,
                                            size: 22,
                                            color: Colors.black54,
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.w700,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (s['address'] != null &&
                                            (s['address'] as String).isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            s['address'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Warna.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        TablerIcons.check,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Warna.primary,
                        ),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.failedToLoad(err.toString()),
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => consumerRef.invalidate(userStoresProvider),
                            icon: const Icon(TablerIcons.refresh, size: 16),
                            label: Text(isIndonesian ? 'Coba Lagi' : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Tombol Kelola / Daftarkan Toko Baru
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: SizedBox(
                width: double.infinity,
                child: ShadButton.outline(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push('/select-store');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(TablerIcons.settings, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        l10n.manageAddStore,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
