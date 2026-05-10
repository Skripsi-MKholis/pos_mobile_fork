import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:pos_mobile/core/widgets/app_drawer.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';

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

        // Jika tidak di tab pertama (Dashboard), kembali ke tab pertama dulu
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
          return;
        }
        
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
        
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        extendBody: true,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
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
          height: 100, // Extra height to allow floating
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9), // Dark floating bar
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(.2),
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GNav(
                      rippleColor: Colors.white10,
                      hoverColor: Colors.white10,
                      gap: 4,
                      activeColor: Colors.white,
                      iconSize: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      duration: const Duration(milliseconds: 300),
                      tabBackgroundColor: Warna.primary.withOpacity(0.8),
                      color: Colors.white54,
                      tabs: navItems
                          .map((item) => GButton(
                                icon: item['icon'],
                                text: item['label'],
                                textStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ))
                          .toList(),
                      selectedIndex: widget.navigationShell.currentIndex,
                      onTabChange: (index) {
                        widget.navigationShell.goBranch(index);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
