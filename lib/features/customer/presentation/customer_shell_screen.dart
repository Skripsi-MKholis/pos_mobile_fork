import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class CustomerShellScreen extends StatelessWidget {
  const CustomerShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F1),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(TablerIcons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(TablerIcons.menu_2), label: 'Menu'),
          NavigationDestination(icon: Icon(TablerIcons.shopping_cart), label: 'Keranjang'),
          NavigationDestination(icon: Icon(TablerIcons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(TablerIcons.user_circle), label: 'Profil'),
        ],
      ),
    );
  }
}
