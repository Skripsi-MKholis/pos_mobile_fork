import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/notification_local_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase diinisialisasi sebelum mengakses fiturnya di background isolate
  await Firebase.initializeApp();
  
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }

  // Catat ke Isar DB jika payload notifikasi valid
  final data = message.data;
  if (data.isNotEmpty) {
    try {
      await IsarService.init();
      final isar = IsarService.instance;
      
      final notif = NotificationLocalModel()
        ..supabaseId = data['id'] ?? message.messageId ?? ''
        ..storeId = data['store_id']
        ..userId = data['user_id']
        ..type = data['type'] ?? 'info'
        ..title = message.notification?.title ?? data['title'] ?? 'Pemberitahuan Baru'
        ..message = message.notification?.body ?? data['message'] ?? ''
        ..isRead = false
        ..createdAt = DateTime.now()
        ..imageUrl = data['image_url']
        ..metadataJson = data['metadata'];

      await isar.writeTxn(() => isar.notificationLocalModels.putBySupabaseId(notif));
    } catch (e) {
      if (kDebugMode) {
        print("Gagal menyimpan notifikasi latar belakang ke Isar: $e");
      }
    }
  }
}

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notifikasi Penting', // title
    description: 'Saluran ini digunakan untuk notifikasi penting sistem dan stok.', // description
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request Permission (iOS & Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User granted notification permission: ${settings.authorizationStatus}');
    }

    // 2. Setup Local Notification for Foreground Heads-Up
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Buat channel notifikasi khusus Android
    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // 3. Configure FCM Presentation Options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Setup Message Handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground Message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      final notification = message.notification;
      final android = message.notification?.android;
      final data = message.data;

      // Masukkan ke Isar Lokal secara real-time
      if (data.isNotEmpty) {
        try {
          final isar = IsarService.instance;
          final notif = NotificationLocalModel()
            ..supabaseId = data['id'] ?? message.messageId ?? ''
            ..storeId = data['store_id']
            ..userId = data['user_id']
            ..type = data['type'] ?? 'info'
            ..title = notification?.title ?? data['title'] ?? 'Pemberitahuan Baru'
            ..message = notification?.body ?? data['message'] ?? ''
            ..isRead = false
            ..createdAt = DateTime.now()
            ..imageUrl = data['image_url']
            ..metadataJson = data['metadata'];

          await isar.writeTxn(() => isar.notificationLocalModels.putBySupabaseId(notif));
        } catch (e) {
          if (kDebugMode) {
            print("Gagal menyimpan notifikasi foreground ke Isar: $e");
          }
        }
      }

      // Tampilkan Notifikasi Sistem di tray (Heads-Up)
      if (notification != null && !kIsWeb) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              priority: Priority.high,
              importance: Importance.max,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: data['type'],
        );
      }
    });

    // Handle App Opened from Notification State
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      _handleNotificationPayload(message.data['type']);
    });

    // Check if app was opened from terminated state via notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationPayload(initialMessage.data['type']);
    }

    // 5. Setup Token Listening and Uploading
    _messaging.onTokenRefresh.listen((token) {
      saveTokenToSupabase(token);
    });

    // Dapatkan token awal dan unggah
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        saveTokenToSupabase(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gagal mengambil token FCM awal: $e');
      }
    }

    _initialized = true;
  }

  // Callback ketika Local Notification di-tap
  void _onLocalNotificationTap(NotificationResponse response) {
    _handleNotificationPayload(response.payload);
  }

  // Arahkan navigasi berdasarkan payload tipe
  void _handleNotificationPayload(String? type) {
    if (type == null) return;
    
    // Gunakan static route redirection bila diperlukan, atau ditangani oleh router.
    // Di sini kita bisa menyimpan status atau mengirim event navigasi.
  }

  // Menyimpan Token FCM ke Supabase
  Future<void> saveTokenToSupabase(String token) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    final deviceInfo = Platform.isAndroid
        ? 'Android Device'
        : Platform.isIOS
            ? 'iOS Device'
            : 'Perangkat Desktop/Lainnya';

    try {
      await supabase.from('user_fcm_tokens').upsert({
        'user_id': currentUser.id,
        'fcm_token': token,
        'device_info': deviceInfo,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'fcm_token');
      
      if (kDebugMode) {
        print('FCM Token berhasil disimpan/diperbarui di Supabase.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error menyimpan FCM Token ke Supabase: $e');
      }
    }
  }

  // Menghapus Token FCM saat logout dari aplikasi
  Future<void> deleteTokenFromSupabase() async {
    final supabase = Supabase.instance.client;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await supabase.from('user_fcm_tokens').delete().eq('fcm_token', token);
        if (kDebugMode) {
          print('FCM Token berhasil dihapus dari Supabase.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error menghapus FCM Token dari Supabase: $e');
      }
    }
  }
}
