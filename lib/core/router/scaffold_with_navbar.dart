import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:pos_mobile/core/widgets/app_drawer.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  DateTime? lastPressed;

  @override
  Widget build(BuildContext context) {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final now = DateTime.now();
        final backButtonHasNotBeenPressedRecently = lastPressed == null || 
            now.difference(lastPressed!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedRecently) {
          lastPressed = now;
          if (mounted) {
            ShadToaster.of(context).show(
              const ShadToast(
                description: Text('Tekan sekali lagi untuk keluar'),
              ),
            );
          }
          return;
        }
        
        // If pressed twice within 2 seconds
        // You can use SystemNavigator.pop() or just allow the pop by setting canPop to true
        // But since we are at the root, we want to exit the app.
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: theme.colorScheme.background,
          elevation: 0,
          centerTitle: true,
          title: Text(
            navItems[widget.navigationShell.currentIndex]['label'],
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
        body: widget.navigationShell,
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
                selectedIndex: widget.navigationShell.currentIndex,
                onTabChange: (index) {
                  widget.navigationShell.goBranch(index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
