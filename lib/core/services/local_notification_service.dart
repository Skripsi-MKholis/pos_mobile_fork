import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pos_mobile/core/services/notification_deep_link.dart';

/// Service terpusat untuk seluruh notifikasi native (local notification).
/// Dipakai oleh: FCMService (push), NotificationNotifier (realtime), dan
/// NotificationSchedulerService (reminder jam kerja).
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ===== Channel Notifikasi (dipisah per kategori agar bisa diatur dari OS) =====
  static const AndroidNotificationChannel transactionChannel = AndroidNotificationChannel(
    'transaksi_channel',
    'Transaksi',
    description: 'Notifikasi pembayaran, pembatalan (void), dan pesanan meja.',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel stockChannel = AndroidNotificationChannel(
    'stok_channel',
    'Stok Produk',
    description: 'Peringatan stok menipis atau stok habis.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
    'sistem_channel',
    'Sistem & Broadcast',
    description: 'Pengumuman dari pemilik toko dan informasi sistem.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
    'reminder_channel',
    'Pengingat Jam Kerja',
    description: 'Pengingat rutin untuk mencatat penjualan selama jam kerja.',
    importance: Importance.defaultImportance,
  );

  static const List<AndroidNotificationChannel> _channels = [
    transactionChannel,
    stockChannel,
    systemChannel,
    reminderChannel,
  ];

  /// Memetakan `type` notifikasi (kolom notifications.type) ke channel Android.
  static AndroidNotificationChannel channelForType(String? type) {
    switch (type) {
      case 'stock':
      case 'low_stock':
      case 'out_of_stock':
        return stockChannel;
      case 'transaction':
      case 'transaction_void':
      case 'payment':
      case 'success':
        return transactionChannel;
      case 'reminder':
        return reminderChannel;
      default:
        return systemChannel;
    }
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        NotificationDeepLink.handlePayload(response.payload);
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      for (final channel in _channels) {
        await androidPlugin?.createNotificationChannel(channel);
      }
    }

    // Jika app dibuka dari tap notifikasi saat terminated, teruskan payload-nya
    final launchDetails = await plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      NotificationDeepLink.handlePayload(
        launchDetails?.notificationResponse?.payload,
      );
    }

    _initialized = true;
  }

  /// Meminta izin notifikasi (Android 13+) dan exact alarm (Android 12+).
  /// Dipanggil setelah login agar prompt muncul di momen yang tepat.
  Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) print('Gagal meminta izin notifikasi: $e');
    }
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      if (kDebugMode) print('Gagal meminta izin exact alarm: $e');
    }
  }

  /// Menampilkan notifikasi native berdasarkan `type` (otomatis memilih channel).
  /// [supabaseId] dipakai sebagai identitas tray agar jalur FCM dan Realtime
  /// tidak memunculkan notifikasi ganda untuk data yang sama.
  Future<void> showForType({
    required String? title,
    required String? body,
    required String? type,
    String? supabaseId,
    String? metadataJson,
  }) async {
    await initialize();
    final channel = channelForType(type);
    final payload = jsonEncode({
      'type': type,
      'id': supabaseId,
      'metadata': metadataJson,
    });

    await plugin.show(
      id: supabaseId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: channel.importance,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Notifikasi uji dari layar Settings untuk memverifikasi izin perangkat.
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    await plugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannel.id,
          reminderChannel.name,
          channelDescription: reminderChannel.description,
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }
}
