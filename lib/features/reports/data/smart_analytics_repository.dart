import 'dart:convert';

// `Category` juga ada di flutter/foundation, sedangkan di sini yang dimaksud
// adalah model Isar milik aplikasi — impor dibatasi agar tidak bentrok.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/features/reports/domain/forecast_accuracy.dart';
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';
import 'package:pos_mobile/features/reports/models/forecast_snapshot.dart';

/// Akses data untuk fitur prediksi: input model, snapshot riwayat, cache
/// offline, dan titik evaluasi akurasi.
///
/// Semua objek database yang **baru** (RPC `get_forecast_input`, tabel
/// `ai_forecast_points`, kolom tambahan pada `smart_analytics_snapshots`)
/// diperlakukan sebagai opsional: bila migrasi belum diterapkan, kode jatuh ke
/// jalur lama tanpa membuat fitur gagal.
class SmartAnalyticsRepository {
  final SupabaseClient _client;

  SmartAnalyticsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String snapshotsTable = 'smart_analytics_snapshots';
  static const String forecastPointsTable = 'ai_forecast_points';

  /// Jendela histori untuk model. LSTM butuh musiman mingguan + bulanan,
  /// jauh di atas 45 hari yang dipakai implementasi lama (T-04).
  static const int defaultHistoryDays = 180;

  /// Batas hari untuk jalur fallback (query langsung tanpa RPC agregat),
  /// supaya perangkat tidak menarik puluhan ribu baris.
  static const int fallbackHistoryDays = 90;

  static const String _cachePrefix = 'smart_analytics_snapshot_';

  /// Kolom yang baru ada setelah migrasi 2026-07-28 dijalankan.
  static const List<String> _optionalSnapshotColumns = [
    'model_version',
    'fallback_reason',
    'input_days',
    'metrics',
    'hourly_traffic',
    'product_demand',
    'forecast_payload',
  ];

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // ================================================================
  // Input model
  // ================================================================

  /// Menyusun input model dari sumber terbaik yang tersedia:
  /// RPC agregat → query langsung → cache Isar.
  Future<ForecastInput> loadInput({
    required String storeId,
    required StoreOperationalProfile profile,
    required bool isOnline,
    int days = defaultHistoryDays,
  }) async {
    if (isOnline) {
      final viaRpc = await _loadInputViaRpc(storeId, profile, days);
      if (viaRpc != null) return viaRpc;

      final viaQuery = await _loadInputViaQuery(storeId, profile);
      if (viaQuery != null) return viaQuery;
    }
    return _loadInputFromIsar(storeId, profile);
  }

  /// Jalur utama: agregasi dikerjakan server, payload hanya beberapa KB.
  Future<ForecastInput?> _loadInputViaRpc(
    String storeId,
    StoreOperationalProfile profile,
    int days,
  ) async {
    try {
      final response = await _client.rpc(
        'get_forecast_input',
        params: {
          'p_store_id': storeId,
          'p_days': days,
          'p_tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
        },
      );
      if (response is! Map) return null;
      final map = Map<String, dynamic>.from(response);

      List<Map<String, dynamic>> rows(String key) =>
          (map[key] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      return ForecastInput(
        profile: profile,
        daily: rows('daily').map(DailySalesPoint.fromJson).toList(),
        hourly: rows('hourly').map(HourlySalesPoint.fromJson).toList(),
        products: rows('products').map(ProductSalesPoint.fromJson).toList(),
      );
    } catch (e) {
      debugPrint('DEBUG: RPC get_forecast_input belum tersedia ($e).');
      return null;
    }
  }

  /// Jalur cadangan bila RPC belum ada. Sengaja **tidak** menulis ulang cache
  /// Isar seperti implementasi lama (T-08) — sinkronisasi adalah tugas
  /// `sync_provider`, bukan layar analitik.
  Future<ForecastInput?> _loadInputViaQuery(
    String storeId,
    StoreOperationalProfile profile,
  ) async {
    try {
      final start = DateTime.now().subtract(
        const Duration(days: fallbackHistoryDays),
      );
      final response = await _client
          .from('transactions')
          .select(
            'id, total_amount, created_at, '
            'transaction_items(product_id, product_name, unit_price, quantity, subtotal)',
          )
          .eq('store_id', storeId)
          .filter('created_at', 'gte', _dateFormat.format(start))
          .order('created_at', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response);
      return _aggregate(
        profile: profile,
        transactions: rows
            .map(
              (tx) => _RawTransaction(
                createdAt: DateTime.parse(tx['created_at'] as String).toLocal(),
                totalAmount: (tx['total_amount'] as num?)?.toDouble() ?? 0,
                items: (tx['transaction_items'] as List? ?? [])
                    .whereType<Map>()
                    .map(
                      (item) => _RawItem(
                        productId: item['product_id']?.toString(),
                        productName:
                            item['product_name']?.toString() ?? 'Produk',
                        quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                        unitPrice:
                            (item['unit_price'] as num?)?.toDouble() ?? 0,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
        storeId: storeId,
      );
    } catch (e) {
      debugPrint('DEBUG: Query transaksi untuk forecast gagal: $e');
      return null;
    }
  }

  /// Jalur offline: agregasi dari cache Isar yang sudah ada di perangkat.
  Future<ForecastInput> _loadInputFromIsar(
    String storeId,
    StoreOperationalProfile profile,
  ) async {
    final isar = IsarService.instance;
    final start = DateTime.now().subtract(
      const Duration(days: defaultHistoryDays),
    );

    final transactions = await isar
        .collection<TransactionLocal>()
        .filter()
        .storeIdEqualTo(storeId)
        .createdAtGreaterThan(start)
        .findAll();

    if (transactions.isEmpty) {
      return ForecastInput(profile: profile);
    }

    // Satu query untuk seluruh item, lalu dikelompokkan di memori — jauh lebih
    // murah daripada satu query per transaksi seperti implementasi lama.
    final ids = transactions.map((t) => t.supabaseId).toSet();
    final allItems = await isar.collection<TransactionItemLocal>().where().findAll();
    final itemsByTx = <String, List<TransactionItemLocal>>{};
    for (final item in allItems) {
      if (!ids.contains(item.transactionSupabaseId)) continue;
      itemsByTx.putIfAbsent(item.transactionSupabaseId, () => []).add(item);
    }

    return _aggregate(
      profile: profile,
      storeId: storeId,
      transactions: [
        for (final tx in transactions)
          _RawTransaction(
            createdAt: tx.createdAt,
            totalAmount: tx.totalAmount,
            items: [
              for (final item in itemsByTx[tx.supabaseId] ?? const [])
                _RawItem(
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                ),
            ],
          ),
      ],
    );
  }

  /// Agregasi transaksi mentah menjadi seri harian, per jam, dan per produk.
  Future<ForecastInput> _aggregate({
    required StoreOperationalProfile profile,
    required List<_RawTransaction> transactions,
    required String storeId,
  }) async {
    final categoryByProduct = await _categoryByProduct(storeId);

    final revenueByDate = <String, double>{};
    final txByDate = <String, int>{};
    final itemsByDate = <String, int>{};
    final hourly = <String, _HourBucket>{};

    final qtyByProduct = <String, int>{};
    final priceByProduct = <String, double>{};
    final idByProduct = <String, String?>{};
    final daysByProduct = <String, Set<String>>{};

    for (final tx in transactions) {
      final key = _dateFormat.format(tx.createdAt);
      revenueByDate[key] = (revenueByDate[key] ?? 0) + tx.totalAmount;
      txByDate[key] = (txByDate[key] ?? 0) + 1;

      final hourKey = '$key#${tx.createdAt.hour}';
      final bucket = hourly.putIfAbsent(
        hourKey,
        () => _HourBucket(tx.createdAt, tx.createdAt.hour),
      );
      bucket.revenue += tx.totalAmount;
      bucket.txCount += 1;

      for (final item in tx.items) {
        itemsByDate[key] = (itemsByDate[key] ?? 0) + item.quantity;
        final name = item.productName;
        qtyByProduct[name] = (qtyByProduct[name] ?? 0) + item.quantity;
        priceByProduct[name] = item.unitPrice;
        idByProduct[name] ??= item.productId;
        daysByProduct.putIfAbsent(name, () => <String>{}).add(key);
      }
    }

    final daily = revenueByDate.entries
        .map(
          (e) => DailySalesPoint(
            date: DateTime.parse(e.key),
            revenue: e.value,
            txCount: txByDate[e.key] ?? 0,
            itemCount: itemsByDate[e.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    final activeDays = daily.length;

    final products =
        qtyByProduct.entries.map((e) {
          final id = idByProduct[e.key];
          return ProductSalesPoint(
            productId: id,
            productName: e.key,
            category:
                (id != null ? categoryByProduct[id] : null) ?? 'Lain-lain',
            price: priceByProduct[e.key] ?? 0,
            qty: e.value,
            avgDailyQty: activeDays > 0 ? e.value / activeDays : 0,
          );
        }).toList()
          ..sort((a, b) => b.qty.compareTo(a.qty));

    return ForecastInput(
      profile: profile,
      daily: daily,
      hourly: hourly.values
          .map(
            (b) => HourlySalesPoint(
              date: b.date,
              hour: b.hour,
              revenue: b.revenue,
              txCount: b.txCount,
            ),
          )
          .toList(),
      products: products,
    );
  }

  Future<Map<String, String>> _categoryByProduct(String storeId) async {
    try {
      final isar = IsarService.instance;
      final products = await isar
          .collection<Product>()
          .filter()
          .storeIdEqualTo(storeId)
          .findAll();
      final categories = await isar
          .collection<Category>()
          .filter()
          .storeIdEqualTo(storeId)
          .findAll();

      final categoryNames = {for (final c in categories) c.supabaseId: c.name};
      return {
        for (final p in products)
          p.supabaseId: categoryNames[p.categoryId] ?? 'Lain-lain',
      };
    } catch (e) {
      debugPrint('DEBUG: Gagal memetakan kategori produk: $e');
      return const {};
    }
  }

  // ================================================================
  // Snapshot
  // ================================================================

  Future<Map<String, dynamic>?> fetchLatestSnapshot(String storeId) async {
    try {
      final rows = await _client
          .from(snapshotsTable)
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      final row = Map<String, dynamic>.from(rows.first);
      await cacheSnapshot(storeId, row);
      return row;
    } catch (e) {
      debugPrint('DEBUG: Gagal memuat snapshot terbaru: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSnapshot(String id) async {
    try {
      final row = await _client
          .from(snapshotsTable)
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(row);
    } catch (e) {
      debugPrint('DEBUG: Gagal memuat snapshot $id: $e');
      return null;
    }
  }

  Future<List<SmartAnalyticsHistoryItem>> fetchHistory(String storeId) async {
    final rows = await _client
        .from(snapshotsTable)
        .select(
          'id, created_at, revenue_text, total_revenue, model_used, '
          'api_server_label, api_online, best_selling_name',
        )
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map(
          (r) => SmartAnalyticsHistoryItem.fromMap(
            Map<String, dynamic>.from(r as Map),
          ),
        )
        .toList();
  }

  /// Menyimpan snapshot. Bila kolom hasil migrasi belum ada di database,
  /// otomatis mencoba ulang tanpa kolom tersebut agar fitur tetap jalan.
  Future<Map<String, dynamic>?> saveSnapshot(
    Map<String, dynamic> payload,
  ) async {
    try {
      final inserted = await _client
          .from(snapshotsTable)
          .insert(payload)
          .select()
          .single();
      return Map<String, dynamic>.from(inserted);
    } catch (e) {
      if (!_isMissingColumn(e)) {
        debugPrint('DEBUG: Gagal menyimpan snapshot: $e');
        return null;
      }

      debugPrint(
        'DEBUG: Kolom snapshot baru belum ada — migrasi 2026-07-28 belum '
        'dijalankan. Menyimpan tanpa kolom opsional.',
      );
      final reduced = Map<String, dynamic>.from(payload)
        ..removeWhere((key, _) => _optionalSnapshotColumns.contains(key));
      try {
        final inserted = await _client
            .from(snapshotsTable)
            .insert(reduced)
            .select()
            .single();
        return Map<String, dynamic>.from(inserted);
      } catch (e2) {
        debugPrint('DEBUG: Gagal menyimpan snapshot (tanpa kolom baru): $e2');
        return null;
      }
    }
  }

  bool _isMissingColumn(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('pgrst204') ||
        (message.contains('column') &&
            (message.contains('not find') || message.contains('does not exist')));
  }

  // ================================================================
  // Cache offline (SharedPreferences)
  //
  // Rencana awal memakai koleksi Isar `AiForecastLocal`, tetapi berkas
  // `.g.dart` Isar di proyek ini harus digenerate manual di proyek terpisah
  // (lihat CLAUDE.md). Mitigasi yang sudah disetujui di §13 dokumen rencana
  // adalah menyimpan cache sebagai JSON — itu yang dipakai di sini.
  // ================================================================

  Future<void> cacheSnapshot(String storeId, Map<String, dynamic> row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$storeId', jsonEncode(row));
    } catch (e) {
      debugPrint('DEBUG: Gagal menyimpan cache snapshot: $e');
    }
  }

  Future<Map<String, dynamic>?> readCachedSnapshot(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$storeId');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (e) {
      debugPrint('DEBUG: Gagal membaca cache snapshot: $e');
      return null;
    }
  }

  Future<void> clearCache(String storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$storeId');
    } catch (_) {}
  }

  // ================================================================
  // Titik evaluasi akurasi (ai_forecast_points)
  // ================================================================

  /// Menyimpan setiap titik prediksi agar akurasinya bisa dievaluasi setelah
  /// tanggalnya lewat. Best-effort: diabaikan bila tabel belum dibuat.
  Future<void> saveForecastPoints({
    required String storeId,
    String? snapshotId,
    required ForecastResult forecast,
    required DateTime now,
  }) async {
    if (forecast.daily.isEmpty) return;

    final today = DateTime(now.year, now.month, now.day);
    final rows = <Map<String, dynamic>>[];

    for (final point in forecast.daily) {
      final horizon = point.date.difference(today).inDays;
      if (horizon <= 0 || horizon > 30) continue;
      rows.add({
        'store_id': storeId,
        if (snapshotId != null) 'snapshot_id': snapshotId,
        'target_date': point.dateKey,
        'horizon_days': horizon,
        'model_used': forecast.metadata.mode.apiValue,
        'predicted_revenue': point.revenue,
        if (point.txCount != null) 'predicted_tx': point.txCount,
      });
    }
    if (rows.isEmpty) return;

    try {
      await _client.from(forecastPointsTable).insert(rows);
    } catch (e) {
      debugPrint(
        'DEBUG: Tabel $forecastPointsTable belum tersedia atau insert gagal '
        '($e). Evaluasi akurasi dilewati.',
      );
    }
  }

  /// Mengisi kolom realisasi untuk tanggal yang sudah lewat.
  Future<void> evaluateForecastPoints(String storeId) async {
    try {
      await _client.rpc(
        'evaluate_forecast_points',
        params: {
          'p_store_id': storeId,
          'p_tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
        },
      );
    } catch (e) {
      debugPrint('DEBUG: RPC evaluate_forecast_points belum tersedia ($e).');
    }
  }

  Future<List<ForecastEvaluationPoint>> fetchEvaluationPoints(
    String storeId, {
    int days = 60,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final rows = await _client
          .from(forecastPointsTable)
          .select(
            'target_date, horizon_days, model_used, predicted_revenue, '
            'predicted_tx, actual_revenue, actual_tx',
          )
          .eq('store_id', storeId)
          .gte('target_date', _dateFormat.format(since))
          .order('target_date', ascending: true);

      return (rows as List)
          .map(
            (r) => ForecastEvaluationPoint.fromMap(
              Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('DEBUG: Gagal memuat titik evaluasi: $e');
      return const [];
    }
  }
}

class _RawTransaction {
  final DateTime createdAt;
  final double totalAmount;
  final List<_RawItem> items;

  const _RawTransaction({
    required this.createdAt,
    required this.totalAmount,
    required this.items,
  });
}

class _RawItem {
  final String? productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const _RawItem({
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}

class _HourBucket {
  final DateTime date;
  final int hour;
  double revenue = 0;
  int txCount = 0;

  _HourBucket(DateTime date, this.hour)
    : date = DateTime(date.year, date.month, date.day);
}
