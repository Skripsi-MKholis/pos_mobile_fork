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
import 'package:pos_mobile/features/dashboard/providers/notification_provider.dart';

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
        pageTitle = 'Pesanan';
        break;
      case 4:
        pageTitle = 'Profil';
        break;
    }

    List<Widget> actions = [];

    // Add page-specific actions first
    if (navigationShell.currentIndex == 0) {
      if (activeStoreId != null && activeStoreId.isNotEmpty) {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
          padding: const EdgeInsets.only(right: 8),
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
            padding: const EdgeInsets.only(right: 8),
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

    // Always append the circular notification bell button at the far right
    actions.add(
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(
                    unreadNotificationCountProvider,
                  );
                  return Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    child: const Icon(
                      TablerIcons.bell,
                      size: 20,
                      color: Colors.black,
                    ),
                  );
                },
              ),
              onPressed: () => context.push('/customer/notifications'),
            ),
          ),
        ),
      ),
    );

    int getTabIndex(int branchIndex) {
      switch (branchIndex) {
        case 0:
        case 1:
          return 0;
        case 2:
        case 3:
          return 1;
        case 4:
          return 2;
        default:
          return 0;
      }
    }

    int getBranchIndex(int tabIndex) {
      switch (tabIndex) {
        case 0:
          return 0;
        case 1:
          return 3;
        case 2:
          return 4;
        default:
          return 0;
      }
    }

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
                  ),
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
                    tabs: const [
                      GButton(
                        icon: TablerIcons.home,
                        text: 'Beranda',
                        textStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Warna.black,
                        ),
                      ),
                      GButton(
                        icon: TablerIcons.history,
                        text: 'Pesanan',
                        textStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Warna.black,
                        ),
                      ),
                      GButton(
                        icon: TablerIcons.user_circle,
                        text: 'Profil',
                        textStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Warna.black,
                        ),
                      ),
                    ],
                    selectedIndex: getTabIndex(navigationShell.currentIndex),
                    onTabChange: (index) {
                      navigationShell.goBranch(getBranchIndex(index));
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
