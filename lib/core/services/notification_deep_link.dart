import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_repository.dart';

/// Menangani navigasi (deep link) ketika sebuah notifikasi ditap.
///
/// Payload notifikasi berupa JSON string: `{"type": ..., "id": ..., "store_id": ..., "metadata": ...}`.
/// Router diset sekali dari `routerProvider`; bila tap terjadi sebelum router
/// siap (app dibuka dari terminated), rute disimpan sebagai pending dan
/// dieksekusi oleh `consumePendingRoute()` saat shell utama tampil.
class NotificationDeepLink {
  NotificationDeepLink._();

  static GoRouter? router;
  static ProviderContainer? container;
  static String? _pendingRoute;
  static String? _pendingStoreId;

  /// Parse payload notifikasi lalu beralih store (jika berbeda) dan navigasi ke layar yang sesuai.
  static void handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    String? type;
    String? supabaseId;
    String? storeId;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        type = decoded['type'] as String?;
        supabaseId = decoded['id'] as String?;
        storeId = decoded['store_id']?.toString();
        // Fallback store_id dari metadata jika di top-level kosong
        if (storeId == null && decoded['metadata'] != null) {
          try {
            final meta = decoded['metadata'] is String
                ? jsonDecode(decoded['metadata'] as String)
                : decoded['metadata'];
            if (meta is Map) {
              storeId = meta['store_id']?.toString();
            }
          } catch (_) {}
        }
      }
    } catch (_) {
      // Payload lama yang hanya berisi string `type` polos
      type = payload;
    }

    // Tandai notifikasi sebagai dibaca (best-effort, jangan blokir navigasi)
    if (supabaseId != null && supabaseId.isNotEmpty) {
      Future(() async {
        try {
          await NotificationRepository().markAsRead(supabaseId!);
        } catch (e) {
          if (kDebugMode) print('Gagal menandai notifikasi dibaca: $e');
        }
      });
    }

    // Jika notifikasi berasal dari toko tertentu, alihkan store aktif
    if (storeId != null && storeId.isNotEmpty) {
      final c = container;
      if (c != null) {
        c.read(activeStoreProvider.notifier).switchStoreById(storeId);
      } else {
        _pendingStoreId = storeId;
      }
    }

    navigateTo(routeForType(type));
  }

  /// Memetakan `type` notifikasi ke rute go_router.
  static String routeForType(String? type) {
    switch (type) {
      case 'stock':
      case 'low_stock':
      case 'out_of_stock':
        return '/stock';
      case 'transaction':
      case 'transaction_void':
      case 'payment':
        return '/transactions';
      case 'reminder':
        return '/dashboard';
      default:
        return '/notifications';
    }
  }

  static void navigateTo(String route) {
    final r = router;
    if (r == null) {
      _pendingRoute = route;
      return;
    }
    try {
      r.push(route);
    } catch (e) {
      if (kDebugMode) print('Gagal navigasi deep link notifikasi: $e');
      _pendingRoute = route;
    }
  }

  /// Dipanggil setelah shell utama (pasca-login) tampil untuk mengeksekusi
  /// rute dan pergantian toko yang tertunda dari tap notifikasi saat app masih terminated.
  static void consumePendingRoute() {
    final pendingStore = _pendingStoreId;
    if (pendingStore != null) {
      _pendingStoreId = null;
      container?.read(activeStoreProvider.notifier).switchStoreById(pendingStore);
    }

    final route = _pendingRoute;
    if (route == null) return;
    _pendingRoute = null;
    try {
      router?.push(route);
    } catch (e) {
      if (kDebugMode) print('Gagal mengeksekusi pending route notifikasi: $e');
    }
  }
}
