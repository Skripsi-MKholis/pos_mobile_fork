import 'package:isar/isar.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final _supabase = Supabase.instance.client;
  final _isar = IsarService.instance;

  // Mengambil data dari Supabase dan menyinkronkan ke Isar secara lokal
  Future<List<NotificationLocalModel>> fetchAndSyncNotifications(String storeId, String? userId) async {
    try {
      // 1. Ambil notifikasi dari remote
      var query = _supabase.from('notifications').select().eq('store_id', storeId);
      
      // Jika user_id dikirimkan, filter notifikasi broadcast (user_id is null) atau yang ditargetkan khusus ke user tersebut
      if (userId != null) {
        query = query.or('user_id.is.null,user_id.eq.$userId');
      } else {
        query = query.isFilter('user_id', null);
      }

      final response = await query.order('created_at', ascending: false).limit(50);
      final remoteList = response as List;

      // 2. Petakan dan simpan ke Isar
      final List<NotificationLocalModel> notifications = [];
      
      await _isar.writeTxn(() async {
        for (var data in remoteList) {
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
          
          await _isar.notificationLocalModels.putBySupabaseId(notif);
          notifications.add(notif);
        }
      });

      return notifications;
    } catch (e) {
      print('Error dalam fetchAndSyncNotifications: $e');
      rethrow;
    }
  }

  // Mendapatkan daftar notifikasi lokal dari Isar DB
  Future<List<NotificationLocalModel>> getLocalNotifications() async {
    return await _isar.notificationLocalModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  // Menandai satu notifikasi sebagai dibaca
  Future<void> markAsRead(String supabaseId) async {
    try {
      // Perbarui lokal terlebih dahulu agar UI responsif seketika
      final localNotif = await _isar.notificationLocalModels
          .filter()
          .supabaseIdEqualTo(supabaseId)
          .findFirst();

      if (localNotif != null) {
        localNotif.isRead = true;
        await _isar.writeTxn(() => _isar.notificationLocalModels.putBySupabaseId(localNotif));
      }

      // Perbarui di database remote Supabase
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', supabaseId);
    } catch (e) {
      print('Error dalam markAsRead: $e');
    }
  }

  // Menandai semua notifikasi di toko sebagai dibaca
  Future<void> markAllAsRead(String storeId, String? userId) async {
    try {
      // 1. Perbarui lokal
      final unreadNotifs = await _isar.notificationLocalModels
          .filter()
          .storeIdEqualTo(storeId)
          .and()
          .isReadEqualTo(false)
          .findAll();

      await _isar.writeTxn(() async {
        for (var notif in unreadNotifs) {
          notif.isRead = true;
          await _isar.notificationLocalModels.putBySupabaseId(notif);
        }
      });

      // 2. Perbarui remote
      var query = _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('store_id', storeId)
          .eq('is_read', false);

      if (userId != null) {
        query = query.or('user_id.is.null,user_id.eq.$userId');
      } else {
        query = query.isFilter('user_id', null);
      }

      await query;
    } catch (e) {
      print('Error dalam markAllAsRead: $e');
    }
  }

  // Menghapus notifikasi tertentu
  Future<void> deleteNotification(String supabaseId) async {
    try {
      // 1. Hapus secara lokal
      final localNotif = await _isar.notificationLocalModels
          .filter()
          .supabaseIdEqualTo(supabaseId)
          .findFirst();

      if (localNotif != null) {
        await _isar.writeTxn(() => _isar.notificationLocalModels.delete(localNotif.id));
      }

      // 2. Hapus di remote
      await _supabase.from('notifications').delete().eq('id', supabaseId);
    } catch (e) {
      print('Error dalam deleteNotification: $e');
    }
  }

  // Menghapus seluruh notifikasi milik toko
  Future<void> clearAllNotifications(String storeId) async {
    try {
      // 1. Hapus lokal
      final localNotifs = await _isar.notificationLocalModels
          .filter()
          .storeIdEqualTo(storeId)
          .findAll();

      await _isar.writeTxn(() async {
        for (var notif in localNotifs) {
          await _isar.notificationLocalModels.delete(notif.id);
        }
      });

      // 2. Hapus remote
      await _supabase.from('notifications').delete().eq('store_id', storeId);
    } catch (e) {
      print('Error dalam clearAllNotifications: $e');
    }
  }

  // Mengirim notifikasi broadcast ke seluruh anggota toko
  Future<void> sendBroadcastNotification({
    required String storeId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'store_id': storeId,
        'user_id': null, // null menunjukkan broadcast ke semua store members
        'type': type,
        'title': title,
        'message': message,
        'is_read': false,
        'metadata': {},
      });
    } catch (e) {
      print('Error dalam sendBroadcastNotification: $e');
      rethrow;
    }
  }
}

