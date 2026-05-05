import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final activeStore = ref.watch(activeStoreProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (activeStore.value != null)
          _buildStoreHeader(theme, activeStore.value!),
        
        const SizedBox(height: 24),
        _buildMenuSection(theme, 'Katalog & Stok', [
          _buildMenuItem(context, theme, TablerIcons.package, 'Daftar Produk', () => context.push('/products')),
          _buildMenuItem(context, theme, TablerIcons.category, 'Kategori', () {}),
        ]),
        const SizedBox(height: 24),
        _buildMenuSection(theme, 'Pengaturan Toko', [
          _buildMenuItem(context, theme, TablerIcons.printer, 'Printer & Struk', () => context.push('/printer-settings')),
          _buildMenuItem(context, theme, TablerIcons.building_store, 'Informasi Toko', () {}),
          _buildMenuItem(context, theme, TablerIcons.user, 'Profil Saya', () {}),
        ]),
        const SizedBox(height: 32),
        ShadButton.destructive(
          width: double.infinity,
          onPressed: () => _handleLogout(context, ref),
          child: const Text('Keluar Aplikasi'),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Versi 1.0.0',
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreHeader(ShadThemeData theme, Map<String, dynamic> store) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(TablerIcons.building_store, color: theme.colorScheme.primaryForeground, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store['name'] ?? 'Toko Aktif', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(store['address'] ?? 'Alamat tidak diatur', style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () {
              // Fungsi ganti toko
            },
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Konfirmasi Keluar'),
        description: const Text('Apakah Anda yakin ingin keluar dari aplikasi? Sesi Anda akan dihentikan.'),
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
      // Router akan otomatis mengarahkan ke /login karena status auth berubah
    }
  }

  Widget _buildMenuSection(ShadThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.muted.copyWith(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, ShadThemeData theme, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.foreground, size: 18),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}
