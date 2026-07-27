import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

/// Realisasi penjualan hari ini — pembanding untuk kartu prediksi.
class TodayRevenue {
  final double revenue;
  final int txCount;

  /// True bila angka berasal dari agregasi server (bukan hanya cache device).
  final bool fromServer;

  const TodayRevenue({
    this.revenue = 0,
    this.txCount = 0,
    this.fromServer = false,
  });
}

/// Omzet berjalan hari ini. Memakai RPC agregat `get_analytics` yang sudah
/// dipakai layar Laporan bila online, dan jatuh ke cache Isar saat offline
/// sehingga kartu prediksi di Dashboard tetap terisi.
final todayRevenueProvider = FutureProvider.autoDispose<TodayRevenue>((
  ref,
) async {
  final storeId = ref.watch(activeStoreProvider).value?['id']?.toString();
  if (storeId == null) return const TodayRevenue();

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final isOnline =
      ref.watch(connectivityNotifierProvider).value == ConnectivityStatus.online;

  if (isOnline) {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_analytics',
        params: {
          'p_store_id': storeId,
          'p_date_from': startOfDay.toUtc().toIso8601String(),
          'p_date_to': null,
          'p_bucket': 'hour',
          'p_tz_offset_minutes': now.timeZoneOffset.inMinutes,
        },
      );
      final map = Map<String, dynamic>.from(response as Map);
      return TodayRevenue(
        revenue: (map['total_revenue'] as num?)?.toDouble() ?? 0,
        txCount: (map['total_transactions'] as num?)?.toInt() ?? 0,
        fromServer: true,
      );
    } catch (e) {
      debugPrint('DEBUG: get_analytics harian gagal, memakai cache lokal: $e');
    }
  }

  final transactions = await IsarService.instance
      .collection<TransactionLocal>()
      .filter()
      .storeIdEqualTo(storeId)
      .createdAtGreaterThan(
        startOfDay.subtract(const Duration(milliseconds: 1)),
      )
      .findAll();

  return TodayRevenue(
    revenue: transactions.fold<double>(0, (sum, t) => sum + t.totalAmount),
    txCount: transactions.length,
  );
});
