import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final user = ref.watch(currentUserProvider);
    final activeStoreAsync = ref.watch(activeStoreProvider);
    final storesAsync = ref.watch(userStoresProvider);

    return Drawer(
      backgroundColor: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            // HEADER - STORE SWITCHER
            activeStoreAsync.when(
              data: (activeStore) => _StoreSwitcherHeader(
                activeStore: activeStore,
                storesAsync: storesAsync,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 12),

            // MENU ITEMS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildSectionHeader(theme, 'ANALYTICS'),
                  _buildDrawerItem(context, TablerIcons.layout_dashboard, 'Dashboard', '/dashboard'),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'OPERASIONAL KASIR'),
                  _buildDrawerItem(context, TablerIcons.shopping_cart, 'Kasir (POS)', '/pos'),
                  _buildDrawerItem(context, TablerIcons.armchair, 'Manajemen Meja', '/tables', isSoon: true),
                  _buildDrawerItem(context, TablerIcons.settings_2, 'Konfigurasi Meja', '/table-config', isSoon: true),
                  _buildDrawerItem(context, TablerIcons.calendar_event, 'Reservasi', '/reservations', isSoon: true),
                  _buildDrawerItem(context, TablerIcons.tools_kitchen_2, 'Dapur (KDS)', '/kds', isSoon: true),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'KATALOG & STOK'),
                  _buildDrawerItem(context, TablerIcons.box, 'Produk', '/products'),
                  _buildDrawerItem(context, TablerIcons.category, 'Kategori', '/categories', isSoon: true),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'LAPORAN'),
                  _buildDrawerItem(context, TablerIcons.report_money, 'Laba Rugi', '/reports/profit-loss', isSoon: true),
                  _buildDrawerItem(context, TablerIcons.history, 'Riwayat Transaksi', '/transactions'),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'PENGATURAN'),
                  _buildDrawerItem(context, TablerIcons.printer, 'Cetak & Struk', '/printer-settings'),
                  _buildDrawerItem(context, TablerIcons.building_store, 'Informasi Toko', '/settings/store', isSoon: true),
                  _buildDrawerItem(context, TablerIcons.settings, 'Modul & Fitur', '/settings/modules', isSoon: true),
                  
                  if (user?.appMetadata['role'] == 'admin') ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(theme, 'SUPER ADMIN'),
                    _buildDrawerItem(context, TablerIcons.shield_check, 'Admin Dashboard', '/admin/dashboard', isSoon: true),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),
            _buildUserFooter(context, ref, theme, user),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ShadThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: theme.textTheme.muted.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route, {bool isSoon = false}) {
    final theme = ShadTheme.of(context);
    final bool isActive = GoRouterState.of(context).matchedLocation == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isActive ? theme.colorScheme.primary : null,
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : theme.colorScheme.mutedForeground,
        ),
        title: Text(
          title,
          style: theme.textTheme.list.copyWith(
            color: isActive ? Colors.white : theme.colorScheme.foreground,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSoon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Soon', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              )
            : null,
        onTap: isSoon ? null : () {
          Navigator.pop(context);
          context.go(route);
        },
      ),
    );
  }

  Widget _buildUserFooter(BuildContext context, WidgetRef ref, ShadThemeData theme, dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.secondary,
            child: Text(user?.email?[0].toUpperCase() ?? 'U', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email?.split('@')[0] ?? 'User',
                  style: theme.textTheme.list.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(user?.email ?? '', style: theme.textTheme.muted.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(TablerIcons.dots_vertical, size: 18),
            onPressed: () => _showUserMenu(context, ref, theme),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref, ShadThemeData theme) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Akun Pengguna'),
        description: const Text('Kelola sesi Anda di perangkat ini.'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(TablerIcons.logout, color: Colors.red),
              title: const Text('Keluar Aplikasi', style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(authProvider.notifier).signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreSwitcherHeader extends StatefulWidget {
  final Map<String, dynamic>? activeStore;
  final AsyncValue<List<Map<String, dynamic>>> storesAsync;

  const _StoreSwitcherHeader({required this.activeStore, required this.storesAsync});

  @override
  State<_StoreSwitcherHeader> createState() => _StoreSwitcherHeaderState();
}

class _StoreSwitcherHeaderState extends State<_StoreSwitcherHeader> {
  final controller = ShadPopoverController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Consumer(
      builder: (context, ref, child) => ShadPopover(
        controller: controller,
        popover: (context) => Container(
          width: 250,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Stores', style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              widget.storesAsync.when(
                data: (stores) => Column(
                  children: [
                    ...stores.map((store) {
                      final isActive = store['id'] == widget.activeStore?['id'];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: (store['logo_url'] != null && store['logo_url'].toString().isNotEmpty == true)
                                ? Image.network(
                                    store['logo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(TablerIcons.building_store, size: 16, color: theme.colorScheme.primary),
                                  )
                                : Icon(TablerIcons.building_store, size: 16, color: theme.colorScheme.primary),
                          ),
                        ),
                        title: Text(store['name'], style: theme.textTheme.list.copyWith(fontSize: 14)),
                        trailing: isActive ? Icon(TablerIcons.check, size: 16, color: theme.colorScheme.primary) : null,
                        onTap: () {
                          ref.read(activeStoreProvider.notifier).selectStore(store);
                          controller.hide();
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const Divider(),
                    ListTile(
                      leading: const Icon(TablerIcons.layout_grid, size: 18),
                      title: const Text('Lihat Semua Toko', style: TextStyle(fontSize: 13)),
                      onTap: () {
                        controller.hide();
                        context.push('/select-store');
                      },
                    ),
                    ListTile(
                      leading: const Icon(TablerIcons.plus, size: 18),
                      title: const Text('Tambah Toko / Outlet', style: TextStyle(fontSize: 13)),
                      onTap: () {},
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Padding(padding: EdgeInsets.all(8.0), child: Text('Gagal memuat toko')),
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.toggle(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: (widget.activeStore?['logo_url'] != null && widget.activeStore?['logo_url'].toString().isNotEmpty == true)
                            ? Image.network(
                                widget.activeStore?['logo_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(TablerIcons.building_store, color: Colors.white, size: 20),
                              )
                            : const Icon(TablerIcons.building_store, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.activeStore?['name'] ?? 'Pilih Toko',
                            style: theme.textTheme.h4.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Outlet Active', style: theme.textTheme.muted.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(TablerIcons.chevron_down, size: 16, color: theme.colorScheme.mutedForeground),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
