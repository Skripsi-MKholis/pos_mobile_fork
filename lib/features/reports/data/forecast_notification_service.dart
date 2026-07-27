import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:pos_mobile/core/services/local_notification_service.dart';
import 'package:pos_mobile/features/reports/data/smart_analytics_repository.dart';
import 'package:pos_mobile/features/reports/domain/math_utils.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';
import 'package:pos_mobile/features/reports/models/forecast_snapshot.dart';

/// Isi notifikasi prediksi harian.
class ForecastNotificationContent {
  final String title;
  final String body;

  const ForecastNotificationContent(this.title, this.body);
}

/// Notifikasi proaktif berisi ringkasan prediksi esok hari (§8.7).
///
/// Kontennya dibangun dari **cache perangkat**, bukan dengan memanggil server
/// model, sehingga tetap terjadwal walau perangkat offline. Karena isi pesan
/// berubah tiap hari, jadwalnya ditulis ulang setiap aplikasi dibuka dan
/// setiap kali analisis baru dijalankan — bukan diulang otomatis dengan teks
/// yang sama seperti pengingat jam kerja.
class ForecastNotificationService {
  ForecastNotificationService._();
  static final ForecastNotificationService instance =
      ForecastNotificationService._();

  static const String keyEnabled = 'forecast_notification_enabled';
  static const String keyHour = 'forecast_notification_hour';

  static const bool defaultEnabled = true;

  /// Menjelang tutup toko — saat keputusan belanja untuk besok diambil.
  static const int defaultHour = 20;

  /// Id terpisah dari slot pengingat jam kerja (100–111).
  static const int _notificationId = 150;

  /// Ambang selisih dari rata-rata sebelum hari disebut "ramai"/"sepi".
  static const double _busyThreshold = 0.15;

  bool _tzInitialized = false;

  void _ensureTimezone() {
    if (_tzInitialized) return;
    tzdata.initializeTimeZones();
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final locationName = switch (offsetHours) {
      8 => 'Asia/Makassar',
      9 => 'Asia/Jayapura',
      _ => 'Asia/Jakarta',
    };
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      debugPrint('Gagal set lokasi timezone notifikasi prediksi: $e');
    }
    _tzInitialized = true;
  }

  /// Menyusun ulang jadwal dari prediksi terakhir milik [storeId].
  Future<void> syncFromCache(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(keyEnabled) ?? defaultEnabled)) {
        await cancel();
        return;
      }

      final repository = SmartAnalyticsRepository();
      final row = await repository.readCachedSnapshot(storeId);
      if (row == null) {
        await cancel();
        return;
      }

      final payload = ForecastSnapshotPayload.fromJson(
        row['forecast_payload'] is Map
            ? Map<String, dynamic>.from(row['forecast_payload'] as Map)
            : null,
      );
      if (payload == null) {
        await cancel();
        return;
      }

      final content = buildContent(
        forecast: payload.forecast,
        now: DateTime.now(),
      );
      if (content == null) {
        await cancel();
        return;
      }

      await _schedule(content, prefs.getInt(keyHour) ?? defaultHour);
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi prediksi: $e');
    }
  }

  /// Membangun isi notifikasi dari hasil prediksi.
  ///
  /// Fungsi murni — tidak menyentuh penyimpanan maupun plugin notifikasi,
  /// sehingga bisa diuji unit. Mengembalikan `null` bila tidak ada yang
  /// layak diberitahukan (lebih baik diam daripada mengirim pesan kosong).
  static ForecastNotificationContent? buildContent({
    required ForecastResult forecast,
    required DateTime now,
  }) {
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final point = forecast.pointForDate(tomorrow);
    if (point == null || point.revenue <= 0) return null;

    // Pembanding: rata-rata seluruh hari buka yang diprediksi.
    final openDays = forecast.daily.where((p) => p.revenue > 0).toList();
    final average = openDays.isEmpty
        ? null
        : openDays.fold<double>(0, (sum, p) => sum + p.revenue) /
              openDays.length;
    final delta = average == null
        ? null
        : safeDiv(point.revenue - average, average);

    String title;
    if (delta != null && delta >= _busyThreshold) {
      title = '📈 Besok diprediksi ramai (+${(delta * 100).round()}%)';
    } else if (delta != null && delta <= -_busyThreshold) {
      title = '📉 Besok diprediksi lebih sepi (${(delta * 100).round()}%)';
    } else {
      title = '📊 Prakiraan penjualan besok';
    }

    final parts = <String>[];

    final topProducts = forecast.productDemand
        .where((d) => d.predictedQty > 0)
        .take(2)
        .toList();
    if (topProducts.isNotEmpty) {
      parts.add(
        'Siapkan ${topProducts.map((d) => '${d.productName} ±${d.predictedQty}').join(', ')}.',
      );
    }

    final urgent = forecast.productDemand
        .where((d) => (d.daysOfStockLeft ?? 99) < 2)
        .take(2)
        .toList();
    if (urgent.isNotEmpty) {
      parts.add(
        'Stok ${urgent.map((d) => d.productName).join(' & ')} diprediksi habis < 2 hari.',
      );
    }

    final peak = forecast.peakHour;
    if (peak != null && parts.length < 2) {
      parts.add(
        'Jam tersibuk ${peak.hour.toString().padLeft(2, '0')}.00.',
      );
    }

    if (parts.isEmpty) {
      parts.add('Buka Smart Analitik untuk rincian prakiraan besok.');
    }

    return ForecastNotificationContent(title, parts.join(' '));
  }

  Future<void> _schedule(
    ForecastNotificationContent content,
    int hour,
  ) async {
    final service = LocalNotificationService.instance;
    await service.initialize();
    _ensureTimezone();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    // Bila jam tayang hari ini sudah lewat, isi pesan tidak lagi relevan
    // (menyebut "besok"), jadi jadwal dilewati sampai sinkronisasi berikutnya.
    if (!scheduled.isAfter(now)) {
      await cancel();
      return;
    }

    final channel = LocalNotificationService.reminderChannel;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: '@mipmap/ic_launcher',
        priority: Priority.defaultPriority,
        importance: channel.importance,
        styleInformation: BigTextStyleInformation(content.body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    final payload = jsonEncode({
      'type': 'forecast',
      'id': null,
      'metadata': null,
    });

    try {
      await service.plugin.zonedSchedule(
        id: _notificationId,
        title: content.title,
        body: content.body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (e) {
      debugPrint('Exact alarm ditolak ($e), memakai inexact.');
      await service.plugin.zonedSchedule(
        id: _notificationId,
        title: content.title,
        body: content.body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  Future<void> cancel() async {
    try {
      await LocalNotificationService.instance.plugin.cancel(
        id: _notificationId,
      );
    } catch (e) {
      debugPrint('Gagal membatalkan notifikasi prediksi: $e');
    }
  }
}
