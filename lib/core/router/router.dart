import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/features/auth/presentation/login_screen.dart';
import 'package:pos_mobile/features/auth/presentation/register_screen.dart';
import 'package:pos_mobile/features/auth/presentation/confirm_email_screen.dart';
import 'package:pos_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:pos_mobile/features/auth/presentation/setup_password_screen.dart';
import 'package:pos_mobile/features/auth/presentation/store_selection_screen.dart';
import 'package:pos_mobile/features/auth/presentation/create_store_screen.dart';
import 'package:pos_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/category_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/category_products_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_form_screen.dart';
import 'package:pos_mobile/features/product/presentation/stock_management_screen.dart';
import 'package:pos_mobile/features/product/presentation/stock_history_screen.dart';
import 'package:pos_mobile/features/pos/presentation/pos_screen.dart';
import 'package:pos_mobile/features/pos/presentation/payment_screen.dart';
import 'package:pos_mobile/features/pos/presentation/receipt_screen.dart';
import 'package:pos_mobile/features/pos/presentation/printer_settings_screen.dart';
import 'package:pos_mobile/features/pos/presentation/transaction_history_screen.dart';
import 'package:pos_mobile/features/settings/presentation/settings_screen.dart';
import 'package:pos_mobile/features/settings/presentation/sync_monitoring_screen.dart';
import 'package:pos_mobile/features/reports/presentation/reports_screen.dart';
import 'package:pos_mobile/features/reports/presentation/smart_analytics_screen.dart';
import 'package:pos_mobile/features/reports/presentation/sales_performance_screen.dart';
import 'package:pos_mobile/features/reports/presentation/smart_analytics_history_screen.dart';
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
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pos_mobile/features/onboarding/providers/onboarding_provider.dart';
import 'package:pos_mobile/features/dashboard/presentation/notification_center_screen.dart';
import 'package:pos_mobile/features/dashboard/presentation/broadcast_notification_screen.dart';
import 'package:pos_mobile/features/customer/presentation/customer_shell_screen.dart';
import 'package:pos_mobile/features/customer/presentation/customer_screens.dart';
import 'package:pos_mobile/features/customer/presentation/customer_store_detail_screen.dart';
import 'package:pos_mobile/features/customer/presentation/customer_checkout_page.dart';
import 'package:pos_mobile/features/customer/presentation/customer_scan_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Instance GoRouter dibuat sekali dan tidak akan direbuild oleh perubahan state auth/store
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: _RouterRefreshNotifier(ref),
    observers: [AnalyticsService.instance.observer],
    redirect: (context, state) {
      // Gunakan ref.read di sini agar redirect bersifat reaktif terhadap data terbaru
      // tanpa memicu rebuild instance GoRouter
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isCustomerRoute = state.matchedLocation.startsWith('/customer');
      final isAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/confirm-email' ||
          state.matchedLocation == '/setup-password';

      final isFirstRunAsync = ref.read(onboardingNotifierProvider);

      if (isFirstRunAsync.isLoading) return null;

      final isFirstRun = isFirstRunAsync.value ?? true;

      if (isFirstRun && !isCustomerRoute) {
        if (state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
        return null;
      } else {
        if (state.matchedLocation == '/onboarding') {
          return '/login';
        }
      }

      if (isCustomerRoute) {
        return null;
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
          '/sales-performance',
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/confirm-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ConfirmEmailScreen(email: email);
        },
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

      GoRoute(
        path: '/customer',
        redirect: (context, state) => '/customer/home',
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/home',
                builder: (context, state) {
                  final storeId = state.uri.queryParameters['store_id'];
                  return CustomerHomeScreen(storeId: storeId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/history',
                builder: (context, state) => const CustomerHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                builder: (context, state) => const CustomerProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/customer/checkout',
        builder: (context, state) {
          final table = state.uri.queryParameters['table'];
          final notes = state.uri.queryParameters['notes'];
          return CustomerCheckoutPage(
            prefilledTableNumber: table,
            prefilledNotes: notes,
          );
        },
      ),
      GoRoute(
        path: '/customer/cart',
        builder: (context, state) => const CustomerCartScreen(),
      ),
      GoRoute(
        path: '/customer/scan',
        builder: (context, state) => const CustomerScanScreen(),
      ),
      GoRoute(
        path: '/customer/search',
        builder: (context, state) => const CustomerSearchScreen(),
      ),
      GoRoute(
        path: '/customer/select-location',
        builder: (context, state) => const CustomerSelectLocationScreen(),
      ),
      GoRoute(
        path: '/customer/all-stores',
        builder: (context, state) => const CustomerAllStoresScreen(),
      ),
      GoRoute(
        path: '/customer/store-detail',
        builder: (context, state) {
          final storeName = state.uri.queryParameters['store_name'] ?? 'Toko';
          final storeId = state.uri.queryParameters['store_id'];
          final category = state.uri.queryParameters['category'];
          final distance = state.uri.queryParameters['distance'];
          final bannerColorHex = state.uri.queryParameters['banner_color'];
          return CustomerStoreDetailScreen(
            storeName: storeName,
            storeId: storeId,
            category: category,
            distance: distance,
            bannerColorHex: bannerColorHex,
          );
        },
      ),
      GoRoute(
        path: '/customer/order/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return CustomerOrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/customer/receipt/:transactionId',
        builder: (context, state) {
          final transactionId = state.pathParameters['transactionId']!;
          return CustomerReceiptScreen(transactionId: transactionId);
        },
      ),
      GoRoute(
        path: '/customer/loyalty',
        builder: (context, state) => const CustomerLoyaltyScreen(),
      ),
      GoRoute(
        path: '/customer/notifications',
        builder: (context, state) => const CustomerNotificationsScreen(),
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
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final category = extra['category'] as Category;
              return CategoryProductsScreen(category: category);
            },
          ),
        ],
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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialCategoryId = extra?['categoryId'] as String?;
          return ProductListScreen(initialCategoryId: initialCategoryId);
        },
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
        routes: [
          GoRoute(
            path: 'history',
            builder: (context, state) => const StockHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/smart-analytics',
        builder: (context, state) => const SmartAnalyticsScreen(),
      ),
      GoRoute(
        path: '/sales-performance',
        builder: (context, state) => const SalesPerformanceScreen(),
      ),
      GoRoute(
        path: '/smart-analytics/history',
        builder: (context, state) => const SmartAnalyticsHistoryScreen(),
      ),
      GoRoute(
        path: '/smart-analytics/history/:id',
        builder: (context, state) => SmartAnalyticsScreen(
          snapshotId: state.pathParameters['id'],
        ),
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
