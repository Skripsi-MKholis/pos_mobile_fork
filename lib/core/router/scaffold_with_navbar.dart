import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:pos_mobile/core/widgets/app_drawer.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/features/pos/providers/transaction_history_provider.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? lastPressed;
  int? _lastIndex;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin =
        role?.toLowerCase() == 'owner' || user?.appMetadata['role'] == 'admin';

    // Auto-refresh transaction history when switching to Riwayat tab/branch (index 2)
    final currentIndex = widget.navigationShell.currentIndex;
    if (_lastIndex != currentIndex) {
      _lastIndex = currentIndex;
      if (currentIndex == 2) {
        Future.microtask(() {
          if (mounted) {
            ref.read(transactionHistoryProvider.notifier).refresh();
          }
        });
      }
    }

    // Reset ke Dashboard saat ganti toko
    ref.listen(activeStoreProvider, (previous, next) {
      if (previous?.value != null && next.value != null) {
        if (previous?.value?['id'] != next.value?['id']) {
          widget.navigationShell.goBranch(0);
        }
      }
    });

    // Tentukan item navigasi berdasarkan Role dengan pemetaan Branch yang eksplisit
    final List<Map<String, dynamic>> navItems = isAdmin
        ? [
            {'icon': TablerIcons.chart_pie, 'label': 'Home', 'branch': 0},
            {'icon': TablerIcons.shopping_cart, 'label': 'Kasir', 'branch': 1},
            {'icon': TablerIcons.history, 'label': 'Riwayat', 'branch': 2},
            {'icon': TablerIcons.report_money, 'label': 'Laporan', 'branch': 3},
            {'icon': TablerIcons.layout_grid, 'label': 'Menu', 'branch': 4},
          ]
        : [
            {
              'icon': TablerIcons.layout_dashboard,
              'label': 'Home',
              'branch': 0,
            },
            {'icon': TablerIcons.shopping_cart, 'label': 'Kasir', 'branch': 1},
            {'icon': TablerIcons.history, 'label': 'Riwayat', 'branch': 2},
            {'icon': TablerIcons.layout_grid, 'label': 'Menu', 'branch': 4},
          ];

    // Judul AppBar berdasarkan branch yang aktif (bukan berdasarkan index bottom bar)
    final String pageTitle;
    switch (widget.navigationShell.currentIndex) {
      case 0:
        pageTitle = 'Dashboard';
        break;
      case 1:
        pageTitle = 'Kasir';
        break;
      case 2:
        pageTitle = 'Riwayat Transaksi';
        break;
      case 3:
        pageTitle = 'Laporan Analitik';
        break;
      case 4:
        pageTitle = 'Pengaturan';
        break;
      default:
        pageTitle = 'POS Mobile';
    }

    // Cari index yang terpilih di GNav berdasarkan branch yang aktif di GoRouter
    final int selectedIndex = navItems.indexWhere(
      (item) => item['branch'] == widget.navigationShell.currentIndex,
    );

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
        final backButtonHasNotBeenPressedRecently =
            lastPressed == null ||
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
        key: _scaffoldKey,
        extendBody: true,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            pageTitle,
            style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(TablerIcons.menu_2),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(icon: const Icon(TablerIcons.bell), onPressed: () {}),
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
                    color: Colors.black.withValues(
                      alpha: 0.9,
                    ), // Modern opacity
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withValues(alpha: .2),
                        offset: const Offset(0, 10),
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      duration: const Duration(milliseconds: 300),
                      tabBackgroundColor: Warna.primary.withValues(alpha: 0.8),
                      color: Colors.white54,
                      tabs: navItems
                          .map(
                            (item) => GButton(
                              icon: item['icon'],
                              text: item['label'],
                              textStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                      selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
                      onTabChange: (index) {
                        final item = navItems[index];
                        if (item['branch'] != null) {
                          widget.navigationShell.goBranch(
                            item['branch'] as int,
                          );
                        }
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
