import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:pos_mobile/core/widgets/app_drawer.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.appMetadata['role'] == 'admin';

    // Tentukan item navigasi berdasarkan Role
    final List<Map<String, dynamic>> navItems = isAdmin 
      ? [
          {'icon': TablerIcons.chart_pie, 'label': 'Home'},
          {'icon': TablerIcons.building_store, 'label': 'Toko'},
          {'icon': TablerIcons.report_money, 'label': 'Laporan'},
          {'icon': TablerIcons.users, 'label': 'User'},
          {'icon': TablerIcons.menu_2, 'label': 'Menu'},
        ]
      : [
          {'icon': TablerIcons.layout_dashboard, 'label': 'Dashboard'},
          {'icon': TablerIcons.shopping_cart, 'label': 'Kasir'},
          {'icon': TablerIcons.history, 'label': 'History'},
          {'icon': TablerIcons.chart_dots, 'label': 'Analitik'},
          {'icon': TablerIcons.menu_2, 'label': 'Menu'},
        ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          navItems[navigationShell.currentIndex]['label'],
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(TablerIcons.menu_2),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.bell),
            onPressed: () {},
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            child: GNav(
              rippleColor: theme.colorScheme.primary.withOpacity(0.1),
              hoverColor: theme.colorScheme.primary.withOpacity(0.05),
              gap: 6,
              activeColor: theme.colorScheme.primary,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              color: theme.colorScheme.mutedForeground,
              tabs: navItems.map((item) => GButton(
                icon: item['icon'],
                text: item['label'],
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              )).toList(),
              selectedIndex: navigationShell.currentIndex,
              onTabChange: (index) {
                navigationShell.goBranch(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
