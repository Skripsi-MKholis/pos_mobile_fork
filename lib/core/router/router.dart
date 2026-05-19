import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/presentation/login_screen.dart';
import 'package:pos_mobile/features/auth/presentation/register_screen.dart';
import 'package:pos_mobile/features/auth/presentation/setup_password_screen.dart';
import 'package:pos_mobile/features/auth/presentation/store_selection_screen.dart';
import 'package:pos_mobile/features/auth/presentation/create_store_screen.dart';
import 'package:pos_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/category_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_form_screen.dart';
import 'package:pos_mobile/features/product/presentation/stock_management_screen.dart';
import 'package:pos_mobile/features/pos/presentation/pos_screen.dart';
import 'package:pos_mobile/features/pos/presentation/payment_screen.dart';
import 'package:pos_mobile/features/pos/presentation/receipt_screen.dart';
import 'package:pos_mobile/features/pos/presentation/printer_settings_screen.dart';
import 'package:pos_mobile/features/pos/presentation/transaction_history_screen.dart';
import 'package:pos_mobile/features/settings/presentation/settings_screen.dart';
import 'package:pos_mobile/features/settings/presentation/sync_monitoring_screen.dart';
import 'package:pos_mobile/features/reports/presentation/reports_screen.dart';
import 'package:pos_mobile/features/reports/presentation/smart_analytics_screen.dart';
import 'package:pos_mobile/features/auth/presentation/profile_screen.dart';
import 'package:pos_mobile/features/settings/presentation/store_info_screen.dart';
import 'package:pos_mobile/features/settings/presentation/staff_management_screen.dart';
import 'package:pos_mobile/features/settings/presentation/manage_tables_screen.dart';
import 'package:pos_mobile/features/settings/presentation/receipt_customization_screen.dart';
import 'package:pos_mobile/features/pos/presentation/table_monitoring_screen.dart';
import 'package:pos_mobile/features/pos/presentation/split_bill_screen.dart';
import 'package:pos_mobile/features/pos/providers/table_monitoring_provider.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/router/scaffold_with_navbar.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pos_mobile/features/onboarding/providers/onboarding_provider.dart';
import 'package:pos_mobile/features/dashboard/presentation/notification_center_screen.dart';
import 'package:pos_mobile/features/dashboard/presentation/broadcast_notification_screen.dart';
import 'package:pos_mobile/features/kds/presentation/kds_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Instance GoRouter dibuat sekali dan tidak akan direbuild oleh perubahan state auth/store
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      // Gunakan ref.read di sini agar redirect bersifat reaktif terhadap data terbaru
      // tanpa memicu rebuild instance GoRouter
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final isFirstRunAsync = ref.read(onboardingNotifierProvider);

      if (isFirstRunAsync.isLoading) return null;

      final isFirstRun = isFirstRunAsync.value ?? true;

      if (isFirstRun) {
        if (state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
        return null;
      } else {
        if (state.matchedLocation == '/onboarding') {
          return '/login';
        }
      }

      if (!isLoggedIn) {
        return isAuthPage ? null : '/login';
      }

      final activeStoreAsync = ref.read(activeStoreProvider);

      // Jika masih loading data toko dari storage, jangan redirect dulu
      if (activeStoreAsync.isLoading) return null;

      final hasSelectedStore = activeStoreAsync.value != null;
      final isOnboardingPage =
          state.matchedLocation == '/select-store' ||
          state.matchedLocation == '/create-store';

      if (!hasSelectedStore) {
        return isOnboardingPage ? null : '/select-store';
      }

      if (hasSelectedStore && isAuthPage) {
        return '/dashboard';
      }

      // Role-based Access Control (RBAC)
      final role = activeStoreAsync.value?['user_role']
          ?.toString()
          .toLowerCase();
      final isOwner =
          role == 'owner' ||
          Supabase.instance.client.auth.currentUser?.appMetadata['role'] ==
              'admin';

      if (!isOwner) {
        final restrictedRoutes = [
          '/reports',
          '/products',
          '/categories',
          '/staff-management',
          '/manage-tables',
          '/store-info',
          '/broadcast-notification',
          '/smart-analytics',
        ];

        final isRestricted = restrictedRoutes.any(
          (route) => state.matchedLocation.startsWith(route),
        );
        if (isRestricted) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
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
      GoRoute(
        path: '/create-store',
        builder: (context, state) => const CreateStoreScreen(),
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'sync-monitoring',
                    builder: (context, state) => const SyncMonitoringScreen(),
                  ),
                ],
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
            autoPrint: extra['autoPrint'] ?? false,
          );
        },
      ),
      GoRoute(
        path: '/printer-settings',
        builder: (context, state) => const PrinterSettingsScreen(),
      ),
      GoRoute(
        path: '/receipt-customization',
        builder: (context, state) => const ReceiptCustomizationScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/store-info',
        builder: (context, state) => const StoreInfoScreen(),
      ),
      GoRoute(
        path: '/staff-management',
        builder: (context, state) => const StaffManagementScreen(),
      ),
      GoRoute(
        path: '/manage-tables',
        builder: (context, state) => const ManageTablesScreen(),
      ),
      GoRoute(
        path: '/table-monitoring',
        builder: (context, state) => const TableMonitoringScreen(),
      ),
      GoRoute(
        path: '/split-bill',
        builder: (context, state) {
          final order = state.extra as TableOrder;
          return SplitBillScreen(order: order);
        },
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
        path: '/stock',
        builder: (context, state) => const StockManagementScreen(),
      ),
      GoRoute(
        path: '/kds',
        builder: (context, state) => const KDSScreen(),
      ),
      GoRoute(
        path: '/smart-analytics',
        builder: (context, state) => const SmartAnalyticsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/broadcast-notification',
        builder: (context, state) => const BroadcastNotificationScreen(),
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // Memantau perubahan tanpa merebuild notifier itu sendiri
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(activeStoreProvider, (_, __) => notifyListeners());
    ref.listen(onboardingNotifierProvider, (_, __) => notifyListeners());
  }
}
