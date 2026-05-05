import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final activeStore = ref.watch(activeStoreProvider);
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: theme.colorScheme.background,
      child: Column(
        children: [
          // HEADER
          _buildHeader(context, theme, activeStore.value, user),
          
          // MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: [
                _buildSectionHeader(theme, 'ANALYTICS'),
                _buildDrawerItem(context, TablerIcons.layout_dashboard, 'Dashboard', '/dashboard'),
                
                const SizedBox(height: 20),
                _buildSectionHeader(theme, 'OPERASIONAL KASIR'),
                _buildDrawerItem(context, TablerIcons.shopping_cart, 'Kasir (POS)', '/pos'),
                _buildDrawerItem(context, TablerIcons.table_alias, 'Manajemen Meja', '/tables', isSoon: true),
                _buildDrawerItem(context, TablerIcons.calendar_event, 'Reservasi', '/reservations', isSoon: true),
                
                const SizedBox(height: 20),
                _buildSectionHeader(theme, 'KATALOG & STOK'),
                _buildDrawerItem(context, TablerIcons.package, 'Produk', '/products'),
                _buildDrawerItem(context, TablerIcons.category, 'Kategori', '/categories', isSoon: true),
                _buildDrawerItem(context, TablerIcons.ticket, 'Program Diskon', '/promotions', isSoon: true),
                
                const SizedBox(height: 20),
                _buildSectionHeader(theme, 'LAPORAN & AUDIT'),
                _buildDrawerItem(context, TablerIcons.history, 'Riwayat Transaksi', '/transactions'),
                _buildDrawerItem(context, TablerIcons.report_money, 'Laporan Laba Rugi', '/reports/profit', isSoon: true),
                
                const SizedBox(height: 20),
                _buildSectionHeader(theme, 'PENGATURAN'),
                _buildDrawerItem(context, TablerIcons.printer, 'Cetak & Struk', '/printer-settings'),
                _buildDrawerItem(context, TablerIcons.building_store, 'Informasi Toko', '/settings/store', isSoon: true),
                _buildDrawerItem(context, TablerIcons.settings, 'Modul & Fitur', '/settings/modules', isSoon: true),
                
                // ADMIN SECTION
                if (user?.appMetadata['role'] == 'admin') ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader(theme, 'SUPER ADMIN'),
                  _buildDrawerItem(
                    context, 
                    TablerIcons.shield_check, 
                    'Admin Dashboard', 
                    '/admin/dashboard',
                    isSoon: true, // Asumsi halaman ini belum dibuat
                  ),
                ],
              ],
            ),
          ),
          
          // FOOTER
          const Divider(),
          _buildLogoutTile(context, ref, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ShadThemeData theme, Map<String, dynamic>? store, dynamic user) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      color: theme.colorScheme.secondary.withOpacity(0.5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              (store?['name'] ?? 'P').toString().substring(0, 1).toUpperCase(),
              style: TextStyle(color: theme.colorScheme.primaryForeground, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store?['name'] ?? 'Pilih Toko',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.email ?? 'User',
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ShadThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
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
    final isSelected = GoRouterState.of(context).matchedLocation == route;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        icon, 
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.foreground,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.foreground,
        ),
      ),
      trailing: isSoon 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Soon', style: TextStyle(fontSize: 8)),
          )
        : null,
      onTap: isSoon ? null : () {
        context.pop(); // Close drawer
        context.go(route);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
    );
  }

  Widget _buildLogoutTile(BuildContext context, WidgetRef ref, ShadThemeData theme) {
    return ListTile(
      leading: const Icon(TablerIcons.logout, color: Colors.redAccent, size: 20),
      title: const Text('Keluar Aplikasi', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
      onTap: () async {
        context.pop(); // Close drawer
        final confirmed = await showShadDialog<bool>(
          context: context,
          builder: (context) => ShadDialog(
            title: const Text('Konfirmasi Keluar'),
            description: const Text('Sesi Anda akan dihentikan.'),
            actions: [
              ShadButton.outline(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              ShadButton.destructive(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Keluar')),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(activeStoreProvider.notifier).clear();
          await ref.read(authProvider.notifier).signOut();
        }
      },
    );
  }
}
