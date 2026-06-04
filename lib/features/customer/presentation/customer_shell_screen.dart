import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:pos_mobile/configuration/configuration.dart';
import 'package:pos_mobile/features/customer/providers/customer_session_provider.dart';
import 'package:pos_mobile/features/customer/providers/customer_cart_provider.dart';
import 'package:pos_mobile/core/widgets/app_drawer.dart';
import 'package:pos_mobile/core/widgets/pill_app_bar.dart';

class CustomerShellScreen extends ConsumerWidget {
  const CustomerShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStoreId = ref.watch(customerStoreIdProvider);
    final cartItems = ref.watch(customerCartProvider);

    final totalItems = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    // Dynamic titles based on active tab index
    String pageTitle = 'Pelanggan';
    switch (navigationShell.currentIndex) {
      case 0:
        pageTitle = 'Pelanggan';
        break;
      case 1:
        pageTitle = 'Menu Digital';
        break;
      case 2:
        pageTitle = 'Keranjang';
        break;
      case 3:
        pageTitle = 'Riwayat';
        break;
      case 4:
        pageTitle = 'Profil';
        break;
    }

    // Dynamic AppBar actions based on active tab index
    List<Widget> actions = [];
    if (navigationShell.currentIndex == 0) {
      if (activeStoreId != null && activeStoreId.isNotEmpty) {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                label: Text(
                  activeStoreId,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                backgroundColor: Warna.primary.withValues(alpha: 0.18),
                side: BorderSide(color: Warna.primary.withValues(alpha: 0.3)),
              ),
            ),
          ),
        );
      }
    } else if (navigationShell.currentIndex == 1) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Badge(
              isLabelVisible: totalItems > 0,
              label: Text(totalItems.toString()),
              child: IconButton(
                onPressed: () => navigationShell.goBranch(2),
                icon: const Icon(TablerIcons.shopping_cart, color: Colors.black),
              ),
            ),
          ),
        ),
      );
    } else if (navigationShell.currentIndex == 2) {
      if (cartItems.isNotEmpty) {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => ref.read(customerCartProvider.notifier).clear(),
              child: const Text(
                'Kosongkan',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }

    final List<Map<String, dynamic>> navItems = [
      {'icon': TablerIcons.home, 'label': 'Beranda', 'branch': 0},
      {'icon': TablerIcons.menu_2, 'label': 'Menu', 'branch': 1},
      {'icon': TablerIcons.shopping_cart, 'label': 'Keranjang', 'branch': 2},
      {'icon': TablerIcons.history, 'label': 'Riwayat', 'branch': 3},
      {'icon': TablerIcons.user_circle, 'label': 'Profil', 'branch': 4},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      drawer: const AppDrawer(),
      appBar: PillAppBar(
        title: pageTitle,
        showDrawerButton: true,
        actions: actions,
      ),
      body: navigationShell,
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
                    activeColor: Warna.black,
                    iconSize: 20,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    duration: const Duration(milliseconds: 300),
                    tabBackgroundColor: Warna.primary,
                    color: Colors.white54,
                    tabs: navItems
                        .map(
                          (item) => GButton(
                            icon: item['icon'],
                            text: item['label'],
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Warna.black,
                            ),
                          ),
                        )
                        .toList(),
                    selectedIndex: navigationShell.currentIndex,
                    onTabChange: (index) {
                      navigationShell.goBranch(index);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
