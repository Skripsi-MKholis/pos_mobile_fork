import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/services/local_notification_service.dart';
import 'package:pos_mobile/core/utils/supabase_helper.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_provider.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MailboxNotifier extends AutoDisposeAsyncNotifier<List<NotificationLocalModel>> {
  final NotificationRepository _repository = NotificationRepository();
  RealtimeChannel? _channel;

  @override
  Future<List<NotificationLocalModel>> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    final connectivity = ref.watch(connectivityNotifierProvider).value;
    final localList = await _repository.getLocalAccountNotifications();

    if (connectivity == ConnectivityStatus.online) {
      try {
        await Supabase.instance.client.ensureValidSession();
        final syncedList = await _repository.fetchAndSyncAccountMailbox(userId);
        _setupRealtimeListener(userId);
        return syncedList;
      } catch (e) {
        print('Error menyinkronkan mailbox pada build: $e');
        return localList;
      }
    }

    return localList;
  }

  void _setupRealtimeListener(String? userId) {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }

    _channel = Supabase.instance.client
        .channel('mailbox_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) async {
            final data = payload.newRecord;

            // Pastikan ini adalah notifikasi akun (store_id == null)
            if (data['store_id'] != null) return;

            final targetUserId = data['user_id'];
            if (targetUserId != null && targetUserId != userId) {
              return;
            }

            final notif = NotificationLocalModel()
              ..supabaseId = data['id']
              ..storeId = null
              ..userId = data['user_id']
              ..type = data['type'] ?? 'info'
              ..title = data['title'] ?? ''
              ..message = data['message'] ?? ''
              ..isRead = data['is_read'] ?? false
              ..createdAt = data['created_at'] == null
                  ? null
                  : DateTime.parse(data['created_at'] as String).toLocal()
              ..imageUrl = data['image_url']
              ..metadataJson = data['metadata']?.toString();

            final isar = IsarService.instance;
            await isar.writeTxn(
              () => isar.notificationLocalModels.putBySupabaseId(notif),
            );

            ref.invalidateSelf();
            ref.read(lastReceivedNotificationProvider.notifier).state = notif;

            LocalNotificationService.instance.showForType(
              title: notif.title,
              body: notif.message,
              type: notif.type,
              supabaseId: notif.supabaseId,
              metadataJson: notif.metadataJson,
            );
          },
        )
        .subscribe();

    ref.onDispose(() {
      if (_channel != null) {
        Supabase.instance.client.removeChannel(_channel!);
      }
    });
  }

  Future<void> markAsRead(String supabaseId) async {
    await _repository.markAsRead(supabaseId);
    ref.invalidateSelf();
  }

  Future<void> markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    await _repository.markAllAccountMailboxAsRead(user?.id);
    ref.invalidateSelf();
  }

  Future<void> deleteNotification(String supabaseId) async {
    await _repository.deleteNotification(supabaseId);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    await _repository.clearAllAccountNotifications(user?.id);
    ref.invalidateSelf();
  }
}

final mailboxNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MailboxNotifier, List<NotificationLocalModel>>(
  MailboxNotifier.new,
);

final unreadMailboxCountProvider = AutoDisposeProvider<int>((ref) {
  final mailboxAsync = ref.watch(mailboxNotifierProvider);
  return mailboxAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
