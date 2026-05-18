import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider);
    final activeStore = ref.watch(activeStoreProvider);
    final isAdmin =
        role?.toLowerCase() == 'owner' || user?.appMetadata['role'] == 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeStore.value != null)
                    _buildStoreHeader(context, theme, activeStore.value!)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
                  if (isAdmin) ...[
                    _buildMenuSection(theme, 'KATALOG & STOK', [
                      _buildMenuItem(
                        context,
                        theme,
                        TablerIcons.package,
                        'Daftar Produk',
                        () => context.push('/products'),
                      ),
                      _buildMenuItem(
                        context,
                        theme,
                        TablerIcons.category,
                        'Kategori Produk',
                        () => context.push('/categories'),
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],
                  _buildMenuSection(theme, 'PENGATURAN TOKO', [
                    _buildMenuItem(
                      context,
                      theme,
                      TablerIcons.printer,
                      'Koneksi Printer',
                      () => context.push('/printer-settings'),
                    ),
                    if (isAdmin) ...[
                      _buildMenuItem(
                        context,
                        theme,
                        TablerIcons.receipt,
                        'Kustomisasi Struk',
                        () => context.push('/receipt-customization'),
                      ),
                      _buildMenuItem(
                        context,
                        theme,
                        TablerIcons.building_store,
                        'Informasi Toko',
                        () => context.push('/store-info'),
                      ),
                      _buildMenuItem(
                        context,
                        theme,
                        TablerIcons.users,
                        'Manajemen Karyawan',
                        () => context.push('/staff-management'),
                      ),
                      // _buildMenuItem(context, theme, TablerIcons.table, 'Manajemen Meja', () => context.push('/manage-tables')),
                    ],
                  ]),
                  const SizedBox(height: 32),
                  _buildMenuSection(theme, 'AKUN & KEAMANAN', [
                    _buildMenuItem(
                      context,
                      theme,
                      TablerIcons.user,
                      'Profil Saya',
                      () => context.push('/profile'),
                    ),
                    _buildMenuItem(
                      context,
                      theme,
                      TablerIcons.lock,
                      'Ganti Kata Sandi',
                      () => context.push('/setup-password'),
                    ),
                    if (role?.toLowerCase() == 'karyawan')
                      _buildMenuItem(
                        context,
                        theme,
                        TablerIcons.logout,
                        'Keluar dari Toko',
                        () => _handleLeaveStore(context, ref),
                        color: Colors.redAccent,
                      ),
                  ]),
                  const SizedBox(height: 48),
                  ShadButton.destructive(
                    width: double.infinity,
                    onPressed: () => _handleLogout(context, ref),
                    child: const Text('Keluar Aplikasi'),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Antigravity POS • Versi 1.0.0',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ShadThemeData theme) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        centerTitle: false,
        title: Text(
          'Menu',
          style: theme.textTheme.h3.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: theme.colorScheme.border.withOpacity(0.5),
        ),
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
      trailing: Icon(
        TablerIcons.chevron_right,
        size: 16,
        color: color?.withOpacity(0.5) ?? Colors.black26,
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleLeaveStore(BuildContext context, WidgetRef ref) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final user = ref.read(currentUserProvider);
    if (activeStore == null || user == null) return;

    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Keluar dari Toko'),
        description: Text(
          'Apakah Anda yakin ingin keluar dari toko ${activeStore['name']}? Anda tidak akan bisa mengakses toko ini lagi tanpa kode undangan baru.',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Ya, Keluar'),
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
          ShadToaster.of(context).show(
            const ShadToast(
              title: Text('Berhasil'),
              description: Text('Anda telah keluar dari toko.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('Error'),
              description: Text('Gagal keluar dari toko: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Konfirmasi Keluar'),
        description: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi? Sesi Anda akan dihentikan.',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Ya, Keluar'),
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
