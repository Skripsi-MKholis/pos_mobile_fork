import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: const Text('Menu Utama', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
            onPressed: () => context.go('/login'),
            child: const Text('Keluar Aplikasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(ShadThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.muted.copyWith(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, ShadThemeData theme, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.foreground, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
