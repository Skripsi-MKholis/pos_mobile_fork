import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: const SafeArea(
        child: Column(
          children: [
            // HEADER - STORE SWITCHER (Self-contained Consumer)
            _StoreHeaderSection(),

            Divider(height: 1),

            // MENU ITEMS (Surgical Rebuilds)
            Expanded(
              child: _DrawerMenuContent(),
            ),

            Divider(height: 1),
            _UserFooter(),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuContent extends ConsumerWidget {
  const _DrawerMenuContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const _SectionHeader(title: 'ANALYTICS'),
        const _DrawerItem(
          icon: TablerIcons.layout_dashboard,
          title: 'Dashboard',
          route: '/dashboard',
        ),
        const _DrawerItem(
          icon: TablerIcons.chart_dots,
          title: 'Analitik',
          route: '/reports',
        ),

        const _SectionSpacing(),
        const _SectionHeader(title: 'OPERASIONAL KASIR'),
        const _DrawerItem(
          icon: TablerIcons.shopping_cart,
          title: 'Kasir (POS)',
          route: '/pos',
        ),
        const _DrawerItem(
          icon: TablerIcons.history,
          title: 'Riwayat Transaksi',
          route: '/transactions',
        ),
        const _DrawerItem(
          icon: TablerIcons.armchair,
          title: 'Manajemen Meja',
          route: '/tables',
          isSoon: true,
        ),

        const _SectionSpacing(),
        const _SectionHeader(title: 'KATALOG & STOK'),
        const _DrawerItem(
          icon: TablerIcons.box,
          title: 'Daftar Produk',
          route: '/products',
        ),
        const _DrawerItem(
          icon: TablerIcons.category,
          title: 'Kategori',
          route: '/categories',
        ),

        const _SectionSpacing(),
        const _SectionHeader(title: 'PENGATURAN'),
        const _DrawerItem(
          icon: TablerIcons.printer,
          title: 'Cetak & Struk',
          route: '/printer-settings',
        ),
        const _DrawerItem(
          icon: TablerIcons.building_store,
          title: 'Informasi Toko',
          route: '/settings',
        ),

        if (user?.appMetadata['role'] == 'admin') ...[
          const _SectionSpacing(),
          const _SectionHeader(title: 'SUPER ADMIN'),
          const _DrawerItem(
            icon: TablerIcons.shield_check,
            title: 'Admin Panel',
            route: '/admin',
            isSoon: true,
          ),
        ],
      ],
    );
  }
}

class _StoreHeaderSection extends ConsumerWidget {
  const _StoreHeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStoreAsync = ref.watch(activeStoreProvider);
    final storesAsync = ref.watch(userStoresProvider); // Watch to ensure data is fetched
    final theme = ShadTheme.of(context);

    return activeStoreAsync.when(
      data: (store) => Container(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          onTap: () {
            _showStoreSwitcher(context, ref, storesAsync);
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              _StoreIcon(logoUrl: store?['logo_url']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store?['name'] ?? 'Pilih Toko',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap untuk ganti outlet',
                      style: theme.textTheme.muted.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Icon(TablerIcons.chevron_down, size: 16, color: Colors.black26),
            ],
          ),
        ),
      ),
      loading: () => Container(
        height: 84,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 100, height: 12, color: Colors.black.withOpacity(0.05)),
                const SizedBox(height: 6),
                Container(width: 60, height: 8, color: Colors.black.withOpacity(0.05)),
              ],
            )
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showStoreSwitcher(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> storesAsync,
  ) {
    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (context) => ShadSheet(
        title: const Text('Pilih Toko / Outlet'),
        description: const Text('Pilih toko yang ingin Anda kelola sekarang.'),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: storesAsync.when(
              data: (stores) => stores.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Tidak ada toko ditemukan')),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...stores.map(
                          (s) => ListTile(
                            leading: _StoreIcon(logoUrl: s['logo_url'], size: 32),
                            title: Text(s['name'] ?? ''),
                            onTap: () {
                              ref.read(activeStoreProvider.notifier).selectStore(s);
                              Navigator.pop(context);
                              Navigator.pop(context); // Close drawer too
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Gagal memuat: $err')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Colors.black38,
        ),
      ),
    );
  }
}

class _SectionSpacing extends StatelessWidget {
  const _SectionSpacing();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 16);
}

class _DrawerItem extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isSoon;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isSoon = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final bool isActive = route.isNotEmpty && location.startsWith(route);
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          selected: isActive,
          selectedTileColor: Warna.primary.withOpacity(0.1),
          leading: Icon(
            icon,
            size: 20,
            color: isActive ? Warna.primary : Colors.black45,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.black87,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          trailing: isSoon
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SOON',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                )
              : null,
          onTap: isSoon
              ? null
              : () {
                  Navigator.pop(context);
                  if ([
                    '/dashboard',
                    '/pos',
                    '/transactions',
                    '/reports',
                    '/settings',
                  ].contains(route)) {
                    context.go(route);
                  } else {
                    context.push(route);
                  }
                },
        ),
      ),
    );
  }
}

class _UserFooter extends ConsumerWidget {
  const _UserFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Warna.primary,
                      child: Text(
                        user?.email?[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email?.split('@')[0] ?? 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(fontSize: 10, color: Colors.black45),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              TablerIcons.logout,
              size: 18,
              color: Colors.redAccent,
            ),
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Konfirmasi Keluar'),
        description: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ShadButton.destructive(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.pop(context);
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }
}

class _StoreIcon extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const _StoreIcon({this.logoUrl, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Warna.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: Warna.primary.withOpacity(0.2), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                TablerIcons.building_store,
                color: Colors.black,
                size: size * 0.5,
              ),
            )
          : Icon(
              TablerIcons.building_store,
              color: Colors.black,
              size: size * 0.5,
            ),
    );
  }
}
