import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/features/auth/presentation/login_screen.dart';
import 'package:pos_mobile/features/auth/presentation/register_screen.dart';
import 'package:pos_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_form_screen.dart';
import 'package:pos_mobile/features/pos/presentation/pos_screen.dart';
import 'package:pos_mobile/features/pos/presentation/payment_screen.dart';
import 'package:pos_mobile/features/pos/presentation/receipt_screen.dart';
import 'package:pos_mobile/features/pos/presentation/printer_settings_screen.dart';
import 'package:pos_mobile/features/pos/presentation/transaction_history_screen.dart';
import 'package:pos_mobile/features/settings/presentation/settings_screen.dart';
import 'package:pos_mobile/core/router/scaffold_with_navbar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorPOSKey = GlobalKey<NavigatorState>(debugLabel: 'shellPOS');
final GlobalKey<NavigatorState> _shellNavigatorHistoryKey = GlobalKey<NavigatorState>(debugLabel: 'shellHistory');
final GlobalKey<NavigatorState> _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // PERSISTENT NAVIGATION SHELL
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Dashboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 2: POS
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPOSKey,
            routes: [
              GoRoute(
                path: '/pos',
                builder: (context, state) => const POSScreen(),
              ),
            ],
          ),
          // Branch 3: History
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHistoryKey,
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionHistoryScreen(),
              ),
            ],
          ),
          // Branch 4: Settings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ROUTES WITHOUT BOTTOM NAV (Sub-pages)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/receipt',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReceiptScreen(
            transaction: extra['transaction'],
            items: extra['items'],
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/printer-settings',
        builder: (context, state) => const PrinterSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'add',
            builder: (context, state) => const ProductFormScreen(),
          ),
        ],
      ),
    ],
  );
});
