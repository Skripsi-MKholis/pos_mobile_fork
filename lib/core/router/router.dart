import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/features/auth/presentation/login_screen.dart';
import 'package:pos_mobile/features/auth/presentation/register_screen.dart';
import 'package:pos_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_list_screen.dart';
import 'package:pos_mobile/features/product/presentation/product_form_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const ProductFormScreen(),
          ),
        ],
      ),
    ],
  );
});
