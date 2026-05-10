import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/presentation/login_screen.dart';
import 'package:pos_mobile/features/auth/presentation/register_screen.dart';
import 'package:pos_mobile/features/auth/presentation/setup_password_screen.dart';
import 'package:pos_mobile/features/auth/presentation/store_selection_screen.dart';
import 'package:pos_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/category_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_form_screen.dart';
import 'package:pos_mobile/features/pos/presentation/pos_screen.dart';
import 'package:pos_mobile/features/pos/presentation/payment_screen.dart';
import 'package:pos_mobile/features/pos/presentation/receipt_screen.dart';
import 'package:pos_mobile/features/pos/presentation/printer_settings_screen.dart';
import 'package:pos_mobile/features/pos/presentation/transaction_history_screen.dart';
import 'package:pos_mobile/features/settings/presentation/settings_screen.dart';
import 'package:pos_mobile/features/reports/presentation/reports_screen.dart';
import 'package:pos_mobile/features/reports/presentation/smart_analytics_screen.dart';
import 'package:pos_mobile/features/auth/presentation/profile_screen.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/router/scaffold_with_navbar.dart';
import 'package:pos_mobile/core/models/product.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Instance GoRouter dibuat sekali dan tidak akan direbuild oleh perubahan state auth/store
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      // Gunakan ref.read di sini agar redirect bersifat reaktif terhadap data terbaru
      // tanpa memicu rebuild instance GoRouter
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn) {
        return isAuthPage ? null : '/login';
      }

      final activeStoreAsync = ref.read(activeStoreProvider);

      // Jika masih loading data toko dari storage, jangan redirect dulu
      if (activeStoreAsync.isLoading) return null;

      final hasSelectedStore = activeStoreAsync.value != null;
      final isSelectingStore = state.matchedLocation == '/select-store';

      if (!hasSelectedStore) {
        return isSelectingStore ? null : '/select-store';
      }

      if (hasSelectedStore && isAuthPage) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/setup-password',
        builder: (context, state) => const SetupPasswordScreen(),
      ),
      GoRoute(
        path: '/select-store',
        builder: (context, state) => const StoreSelectionScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pos',
                builder: (context, state) => const POSScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
                routes: [
                  GoRoute(
                    path: 'smart', // this will be /reports/smart
                    builder: (context, state) => const SmartAnalyticsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
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
        path: '/printer-settings',
        builder: (context, state) => const PrinterSettingsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final product = state.extra as Product?;
              return ProductFormScreen(product: product);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // Memantau perubahan tanpa merebuild notifier itu sendiri
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(activeStoreProvider, (_, __) => notifyListeners());
  }
}
