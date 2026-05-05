import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: Text(
          'Parzello POS',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          ShadButton.ghost(
            child: const Icon(TablerIcons.bell),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(context, theme),
            const SizedBox(height: 32),
            Text(
              'Aksi Cepat',
              style: theme.textTheme.h4,
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context, theme),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.background,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.mutedForeground,
        onTap: (index) {
          if (index == 1) context.push('/products');
          if (index == 2) context.push('/pos');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(TablerIcons.layout_dashboard), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(TablerIcons.package), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(TablerIcons.shopping_cart), label: 'Kasir'),
          BottomNavigationBarItem(icon: Icon(TablerIcons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ShadThemeData theme) {
    return ShadCard(
      backgroundColor: theme.colorScheme.foreground, // Dark Stone background for contrast
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penjualan Hari Ini',
            style: TextStyle(
              color: theme.colorScheme.background.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp 0',
            style: TextStyle(
              color: theme.colorScheme.primary, // Using Lime for the amount
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMiniStat(theme, 'Pesanan', '0'),
              const SizedBox(width: 32),
              _buildMiniStat(theme, 'Pelanggan', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(ShadThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.background.withValues(alpha: 0.54),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.background,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ShadThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(context, theme, TablerIcons.plus, 'Transaksi Baru', () => context.push('/pos')),
        _buildActionCard(context, theme, TablerIcons.package, 'Kelola Produk', () => context.push('/products')),
        _buildActionCard(context, theme, TablerIcons.history, 'Riwayat', () {}),
        _buildActionCard(context, theme, TablerIcons.printer, 'Printer', () => context.push('/printer-settings')),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, ShadThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: theme.colorScheme.foreground),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
