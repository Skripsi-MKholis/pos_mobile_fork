import 'dart:convert';
import 'dart:io';
import 'dart:ui';

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
  String _smallIcon = '@mipmap/launcher_icon';

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
      case 'warning':
        return stockChannel;
      case 'transaction':
      case 'transaction_void':
      case 'danger':
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

    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Coba gunakan @drawable/ic_stat_notify (ikon transparan siluet).
    // Jika sesi APK yang sedang berjalan belum di-rebuild, fallback ke @mipmap/launcher_icon agar tidak crash.
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
          iOS: darwinSettings,
        ),
        onDidReceiveNotificationResponse: (response) {
          NotificationDeepLink.handlePayload(response.payload);
        },
      );
      _smallIcon = '@drawable/ic_stat_notify';
    } catch (e) {
      if (kDebugMode) {
        print('Fallback initialize ke @mipmap/launcher_icon: $e');
      }
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: darwinSettings,
        ),
        onDidReceiveNotificationResponse: (response) {
          NotificationDeepLink.handlePayload(response.payload);
        },
      );
      _smallIcon = '@mipmap/launcher_icon';
    }

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
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();

    if (Platform.isAndroid) {
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final notifGranted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
      final exactAlarmGranted =
          await androidPlugin?.requestExactAlarmsPermission() ?? true;
      return notifGranted && exactAlarmGranted;
    }

    if (Platform.isIOS) {
      final iosPlugin = plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  /// Menampilkan notifikasi lokal sesuai kategori tipe pesan.
  Future<void> showForType({
    required String title,
    required String body,
    String? type,
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

    try {
      await plugin.show(
        id: supabaseId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: _smallIcon,
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
            color: const Color(0xFF9AE600),
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
    } catch (e) {
      // Fallback jika icon gagal dimuat
      await plugin.show(
        id: supabaseId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/launcher_icon',
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
  }

  /// Notifikasi uji dari layar Settings untuk memverifikasi izin perangkat.
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    try {
      await plugin.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannel.id,
            reminderChannel.name,
            channelDescription: reminderChannel.description,
            icon: _smallIcon,
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
            color: const Color(0xFF9AE600),
            priority: Priority.high,
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      // Fallback tanpa resource drawable baru
      await plugin.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannel.id,
            reminderChannel.name,
            channelDescription: reminderChannel.description,
            icon: '@mipmap/launcher_icon',
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
}
