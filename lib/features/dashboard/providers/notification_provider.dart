import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';

part 'notification_provider.g.dart';

// Provider untuk menampung notifikasi terbaru yang masuk secara real-time guna memicu UI Toast
final lastReceivedNotificationProvider = StateProvider<NotificationLocalModel?>((ref) => null);

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  final NotificationRepository _repository = NotificationRepository();
  RealtimeChannel? _channel;

  @override
  FutureOr<List<NotificationLocalModel>> build() async {

    // Memantau store aktif
    final activeStore = ref.watch(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return [];

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    // Memantau status koneksi internet
    final connectivity = ref.watch(connectivityNotifierProvider).value;

    // Muat data lokal dari Isar DB terlebih dahulu (offline-first)
    final localList = await _repository.getLocalNotifications();

    // Jika online, sinkronkan data baru dan pasang listener realtime
    if (connectivity == ConnectivityStatus.online) {
      try {
        await Supabase.instance.client.ensureValidSession();
        final syncedList = await _repository.fetchAndSyncNotifications(storeId, userId);
        
        // Pasang realtime listener
        _setupRealtimeListener(storeId, userId);
        
        return syncedList;
      } catch (e) {
        print('Error menyinkronkan notifikasi pada build: $e');
        return localList;
      }
    }

    return localList;
  }

  void _setupRealtimeListener(String storeId, String? userId) {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }

    _channel = Supabase.instance.client.channel('notifications_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'store_id',
            value: storeId,
          ),
          callback: (payload) async {
            final data = payload.newRecord;
            
            // Cek apakah notifikasi untuk pengguna ini (bila user_id diset) atau broadcast (user_id = null)
            final targetUserId = data['user_id'];
            if (targetUserId != null && targetUserId != userId) {
              return; // Bukan notifikasi untuk kita
            }

            final notif = NotificationLocalModel()
              ..supabaseId = data['id']
              ..storeId = data['store_id']
              ..userId = data['user_id']
              ..type = data['type'] ?? 'info'
              ..title = data['title'] ?? ''
              ..message = data['message'] ?? ''
              ..isRead = data['is_read'] ?? false
              ..createdAt = data['created_at'] == null ? null : DateTime.parse(data['created_at'] as String).toLocal()
              ..imageUrl = data['image_url']
              ..metadataJson = data['metadata']?.toString();

            // Simpan ke Isar lokal
            final isar = IsarService.instance;
            await isar.writeTxn(() => isar.notificationLocalModels.putBySupabaseId(notif));

            // Perbarui state Riverpod dengan me-invalidate self (memuat ulang dari lokal)
            ref.invalidateSelf();

            // Picu dialog/toast dengan menyimpan notifikasi di StateProvider
            ref.read(lastReceivedNotificationProvider.notifier).state = notif;
          },
        )
        .subscribe();

    // Hapus channel saat provider di-dispose
    ref.onDispose(() {
      if (_channel != null) {
        Supabase.instance.client.removeChannel(_channel!);
      }
    });
  }

  // Menandai notifikasi sebagai telah dibaca
  Future<void> markAsRead(String supabaseId) async {
    await _repository.markAsRead(supabaseId);
    ref.invalidateSelf();
  }

  // Menandai semua notifikasi milik toko saat ini sebagai telah dibaca
  Future<void> markAllAsRead() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    await _repository.markAllAsRead(storeId, userId);
    ref.invalidateSelf();
  }

  // Menghapus notifikasi
  Future<void> deleteNotification(String supabaseId) async {
    await _repository.deleteNotification(supabaseId);
    ref.invalidateSelf();
  }

  // Menghapus seluruh notifikasi
  Future<void> clearAll() async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    await _repository.clearAllNotifications(storeId);
    ref.invalidateSelf();
  }

  // Mengirim notifikasi broadcast ke seluruh staf toko
  Future<void> sendBroadcast({
    required String title,
    required String message,
    required String type,
  }) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) throw 'Toko aktif tidak ditemukan';

    await _repository.sendBroadcastNotification(
      storeId: storeId,
      title: title,
      message: message,
      type: type,
    );

    // Refresh state notifikasi agar langsung muncul di pengirim juga
    ref.invalidateSelf();
  }
}

// Provider helper untuk menghitung jumlah notifikasi yang belum dibaca
@riverpod
int unreadNotificationCount(UnreadNotificationCountRef ref) {
  final notificationsAsync = ref.watch(notificationNotifierProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
}
