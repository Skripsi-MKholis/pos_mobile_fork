import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:pos_mobile/core/services/local_notification_service.dart';

/// Menjadwalkan notifikasi native pengingat pemakaian aplikasi selama jam
/// kerja. Murni lokal (flutter_local_notifications + zonedSchedule), sehingga
/// tetap berjalan offline dan bertahan setelah reboot (via boot receiver).
class NotificationSchedulerService {
  NotificationSchedulerService._();
  static final NotificationSchedulerService instance = NotificationSchedulerService._();

  // ===== Kunci SharedPreferences =====
  static const String keyEnabled = 'work_reminder_enabled';
  static const String keyStartMinutes = 'work_reminder_start_minutes';
  static const String keyEndMinutes = 'work_reminder_end_minutes';
  static const String keyIntervalHours = 'work_reminder_interval_hours';

  // ===== Nilai default =====
  static const bool defaultEnabled = true;
  static const int defaultStartMinutes = 8 * 60; // 08:00
  static const int defaultEndMinutes = 21 * 60; // 21:00
  static const int defaultIntervalHours = 4;

  /// Basis id notifikasi terjadwal; slot ke-n memakai id [_baseId] + n.
  static const int _baseId = 100;
  static const int _maxSlots = 12;

  bool _tzInitialized = false;

  void _ensureTimezone() {
    if (_tzInitialized) return;
    tzdata.initializeTimeZones();
    // Deteksi zona waktu Indonesia dari offset perangkat (WIB/WITA/WIT).
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    String locationName;
    switch (offsetHours) {
      case 7:
        locationName = 'Asia/Jakarta';
        break;
      case 8:
        locationName = 'Asia/Makassar';
        break;
      case 9:
        locationName = 'Asia/Jayapura';
        break;
      default:
        locationName = 'Asia/Jakarta';
    }
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      if (kDebugMode) print('Gagal set lokasi timezone: $e');
    }
    _tzInitialized = true;
  }

  /// Konten pengingat bervariasi mengikuti jam slot agar tidak monoton.
  static Map<String, String> messageForHour(int hour) {
    if (hour < 10) {
      return {
        'title': '☀️ Selamat pagi!',
        'body': 'Buka Parzello POS dan mulai catat penjualan hari ini.',
      };
    } else if (hour < 14) {
      return {
        'title': '🍽️ Jam sibuk siang!',
        'body': 'Pastikan semua transaksi tercatat di Parzello POS.',
      };
    } else if (hour < 18) {
      return {
        'title': '📊 Waktunya cek performa',
        'body': 'Lihat ringkasan penjualan sore ini di dashboard Parzello POS.',
      };
    } else {
      return {
        'title': '🌙 Menjelang tutup toko',
        'body': 'Rekap transaksi hari ini dan cek stok untuk besok di Parzello POS.',
      };
    }
  }

  /// Membaca preferensi lalu menerapkan jadwal (dipanggil saat app dibuka
  /// setelah login dan setiap kali pengaturan diubah).
  Future<void> syncFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(keyEnabled) ?? defaultEnabled;
      if (!enabled) {
        await cancelAllReminders();
        return;
      }
      await scheduleWorkHourReminders(
        startMinutes: prefs.getInt(keyStartMinutes) ?? defaultStartMinutes,
        endMinutes: prefs.getInt(keyEndMinutes) ?? defaultEndMinutes,
        intervalHours: prefs.getInt(keyIntervalHours) ?? defaultIntervalHours,
      );
    } catch (e) {
      if (kDebugMode) print('Gagal sinkronisasi jadwal reminder: $e');
    }
  }

  /// Menjadwalkan pengingat harian berulang pada slot jam kerja:
  /// mulai [startMinutes], berulang tiap [intervalHours] jam, hingga [endMinutes].
  Future<void> scheduleWorkHourReminders({
    required int startMinutes,
    required int endMinutes,
    required int intervalHours,
  }) async {
    final service = LocalNotificationService.instance;
    await service.initialize();
    _ensureTimezone();

    // Bersihkan jadwal lama agar perubahan setting tidak meninggalkan slot usang
    await cancelAllReminders();

    if (intervalHours <= 0 || endMinutes <= startMinutes) return;

    final channel = LocalNotificationService.reminderChannel;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: '@mipmap/ic_launcher',
        priority: Priority.defaultPriority,
        importance: channel.importance,
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    int slot = 0;
    for (int minutes = startMinutes;
        minutes <= endMinutes && slot < _maxSlots;
        minutes += intervalHours * 60, slot++) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      final message = messageForHour(hour);
      final payload = jsonEncode({'type': 'reminder', 'id': null, 'metadata': null});

      final scheduledDate = _nextInstanceOf(hour, minute);

      try {
        await service.plugin.zonedSchedule(
          id: _baseId + slot,
          title: message['title'],
          body: message['body'],
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } on PlatformException catch (e) {
        // Izin exact alarm ditolak (Android 14+ default menolak) → pakai inexact
        if (kDebugMode) print('Exact alarm ditolak ($e), fallback ke inexact.');
        await service.plugin.zonedSchedule(
          id: _baseId + slot,
          title: message['title'],
          body: message['body'],
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      }
    }

    if (kDebugMode) {
      print('Reminder jam kerja terjadwal: $slot slot '
          '(${startMinutes ~/ 60}:${(startMinutes % 60).toString().padLeft(2, '0')}'
          ' - ${endMinutes ~/ 60}:${(endMinutes % 60).toString().padLeft(2, '0')},'
          ' tiap $intervalHours jam).');
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Membatalkan seluruh slot reminder (toggle off / logout).
  Future<void> cancelAllReminders() async {
    final plugin = LocalNotificationService.instance.plugin;
    for (int i = 0; i < _maxSlots; i++) {
      try {
        await plugin.cancel(id: _baseId + i);
      } catch (e) {
        if (kDebugMode) print('Gagal membatalkan reminder ${_baseId + i}: $e');
      }
    }
  }
}
