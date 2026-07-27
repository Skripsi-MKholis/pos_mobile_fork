import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';

/// Kegagalan pemanggilan server model, lengkap dengan alasan yang bisa
/// ditampilkan ke pengguna dan dicatat di snapshot (`fallback_reason`).
class LstmApiException implements Exception {
  final String reason;
  final String message;

  const LstmApiException(this.reason, this.message);

  @override
  String toString() => 'LstmApiException($reason): $message';
}

/// Klien HTTP untuk server model prediksi.
///
/// Menangani tiga hal yang dulu tidak ada (T-07):
/// 1. **Warmup** — `GET /api/health` lebih dulu agar HuggingFace Space yang
///    sedang tidur sempat bangun sebelum request berat dikirim.
/// 2. **Timeout adaptif** — 20 detik bila server sudah hangat, 60 detik bila
///    dingin. Sebelumnya tiga request berturut-turut masing-masing 10 detik,
///    sehingga cold start hampir selalu jatuh ke fallback tanpa disadari.
/// 3. **Satu panggilan batch** ke `/api/v2/forecast`, dengan fallback otomatis
///    ke trio endpoint v1 lama agar server yang belum diperbarui tetap jalan.
class LstmApiClient {
  final http.Client _http;

  LstmApiClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const Duration healthTimeout = Duration(seconds: 3);
  static const Duration warmTimeout = Duration(seconds: 20);
  static const Duration coldTimeout = Duration(seconds: 60);
  static const Duration legacyTimeout = Duration(seconds: 20);

  static const int dailyHorizon = 30;

  /// Mengecek kesiapan server. Tidak pernah melempar — kegagalan health check
  /// hanya berarti "anggap dingin", bukan gagal total.
  Future<bool> warmup(String baseUrl) async {
    try {
      final response = await _http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(healthTimeout);
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      if (body is! Map) return false;
      return (body['warm'] as bool?) ?? (body['model_loaded'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil forecast lengkap. Melempar [LstmApiException] bila semua jalur
  /// (v2 lalu v1) gagal — pemanggil yang memutuskan memakai estimasi lokal.
  Future<ForecastResult> fetchForecast({
    required String baseUrl,
    required ForecastInput input,
    required DateTime now,
  }) async {
    final warm = await warmup(baseUrl);
    final timeout = warm ? warmTimeout : coldTimeout;

    try {
      return await _fetchV2(baseUrl, input, timeout);
    } on _EndpointMissing {
      debugPrint('DEBUG: /api/v2/forecast tidak tersedia, memakai endpoint v1.');
      return _fetchLegacy(baseUrl, input, now);
    }
  }

  // ================================================================
  // Jalur v2 (kontrak baru)
  // ================================================================
  Future<ForecastResult> _fetchV2(
    String baseUrl,
    ForecastInput input,
    Duration timeout,
  ) async {
    final uri = Uri.parse('$baseUrl/api/v2/forecast');
    final body = jsonEncode(input.toJson(dailyHorizon: dailyHorizon));

    http.Response? response;
    Object? lastError;

    // Satu kali percobaan ulang: cold start dan hiccup jaringan sering pulih
    // pada percobaan kedua.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        response = await _http
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(timeout);

        if (response.statusCode == 404 || response.statusCode == 405) {
          throw const _EndpointMissing();
        }
        if (response.statusCode == 200) break;
        if (response.statusCode < 500) {
          throw LstmApiException(
            'http_${response.statusCode}',
            'Server prediksi menolak permintaan (${response.statusCode}).',
          );
        }
        lastError = LstmApiException(
          'http_${response.statusCode}',
          'Server prediksi bermasalah (${response.statusCode}).',
        );
      } on _EndpointMissing {
        rethrow;
      } on TimeoutException {
        lastError = const LstmApiException(
          'timeout',
          'Server prediksi tidak merespons tepat waktu.',
        );
      } catch (e) {
        lastError = LstmApiException('network_error', e.toString());
      }
    }

    if (response == null || response.statusCode != 200) {
      throw lastError is LstmApiException
          ? lastError
          : const LstmApiException(
              'network_error',
              'Gagal menghubungi server prediksi.',
            );
    }

    try {
      final json = jsonDecode(response.body);
      if (json is! Map) {
        throw const LstmApiException(
          'bad_response',
          'Format response server tidak dikenali.',
        );
      }
      return ForecastResult.fromJson(Map<String, dynamic>.from(json));
    } on LstmApiException {
      rethrow;
    } catch (e) {
      throw LstmApiException('parse_error', e.toString());
    }
  }

  // ================================================================
  // Jalur v1 (kompatibilitas dengan server yang sedang berjalan)
  // ================================================================
  Future<ForecastResult> _fetchLegacy(
    String baseUrl,
    ForecastInput input,
    DateTime now,
  ) async {
    final history = input.toLegacyHistory();
    final profile = input.profile;

    Future<Map<String, dynamic>?> post(String path, Object payload) async {
      try {
        final response = await _http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(legacyTimeout);
        if (response.statusCode != 200) return null;
        final json = jsonDecode(response.body);
        return json is Map ? Map<String, dynamic>.from(json) : null;
      } catch (e) {
        debugPrint('DEBUG: v1 $path gagal: $e');
        return null;
      }
    }

    final daily = await post('/api/predict/daily', {
      'n_days': dailyHorizon,
      'k': 4,
      'open_on_weekends': profile.openOnWeekends,
      'closed_months': profile.closedMonths,
      'history': history,
    });

    if (daily == null) {
      throw const LstmApiException(
        'model_unavailable',
        'Server prediksi tidak mengembalikan hasil.',
      );
    }

    final parsed = _parseLegacyDaily(daily);
    final points = parsed.points;
    if (points.isEmpty) {
      throw const LstmApiException(
        'empty_forecast',
        'Server prediksi mengembalikan hasil kosong.',
      );
    }

    final firstRevenue = points.first.revenue;
    final stock = await post('/api/recommendations/stock', {
      'predicted_revenue': firstRevenue,
      'open_on_weekends': profile.openOnWeekends,
      'closed_months': profile.closedMonths,
      'category_shares': _categoryShares(input),
      'top_products': _topProducts(input),
      'history': history,
    });

    Map<String, dynamic>? target;
    if (history.length >= 15) {
      target = await post('/api/recommendations/target', {
        'factor': 1.10,
        'history': history,
      });
    }

    return ForecastResult(
      metadata: ForecastMetadata(
        mode: parsed.mode,
        modelUsedRaw: parsed.modelUsedRaw,
        modelVersion: daily['metadata']?['model_version']?.toString(),
        fallbackReason: 'legacy_v1_endpoint',
        inputDays: input.activeDays,
        generatedAt: now,
      ),
      daily: points,
      productDemand: _legacyProductDemand(stock, input),
      recommendations: _legacyRecommendations(target),
    );
  }

  _LegacyDaily _parseLegacyDaily(Map<String, dynamic> json) {
    final raw = json['predictions'];
    if (raw is! List) return const _LegacyDaily([], ForecastMode.seasonalNaive, null);

    final metaModel = json['metadata']?['model_used']?.toString();
    ForecastMode? detected;
    final points = <ForecastPoint>[];

    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final date = map['date']?.toString();
      if (date == null) continue;

      // Nama field menentukan model apa yang sebenarnya menghasilkan angka.
      // Ini yang mencegah baseline dilabeli "LSTM" (T-01).
      num? value;
      if (map['predicted_revenue_lstm'] is num) {
        value = map['predicted_revenue_lstm'] as num;
        detected ??= ForecastMode.lstm;
      } else if (map['predicted_revenue'] is num) {
        value = map['predicted_revenue'] as num;
        detected ??= ForecastMode.fromApi(metaModel);
      } else if (map['predicted_revenue_seasonal_naive'] is num) {
        value = map['predicted_revenue_seasonal_naive'] as num;
        detected ??= ForecastMode.seasonalNaive;
      }
      if (value == null) continue;

      points.add(
        ForecastPoint(
          date: DateTime.parse(date),
          revenue: value.toDouble(),
          revenueLow: (map['predicted_revenue_low'] as num?)?.toDouble(),
          revenueHigh: (map['predicted_revenue_high'] as num?)?.toDouble(),
          txCount: (map['predicted_tx_count'] as num?)?.toInt(),
          confidence: (map['confidence'] as num?)?.toDouble(),
        ),
      );
    }

    return _LegacyDaily(
      points,
      detected ?? ForecastMode.seasonalNaive,
      metaModel,
    );
  }

  Map<String, double> _categoryShares(ForecastInput input) {
    final revenueByCategory = <String, double>{};
    double total = 0;
    for (final p in input.products) {
      final revenue = p.price * p.qty;
      revenueByCategory[p.category] =
          (revenueByCategory[p.category] ?? 0) + revenue;
      total += revenue;
    }
    if (total <= 0) return const {};
    return revenueByCategory.map((k, v) => MapEntry(k, v / total));
  }

  List<Map<String, dynamic>> _topProducts(ForecastInput input) {
    final totalQty = input.products.fold<int>(0, (s, p) => s + p.qty);
    final sorted = [...input.products]..sort((a, b) => b.qty.compareTo(a.qty));
    return [
      for (final p in sorted.take(10))
        {
          'name': p.productName,
          'category': p.category,
          'price': p.price.round(),
          'qty_share': totalQty > 0 ? p.qty / totalQty : 0.0,
        },
    ];
  }

  List<ProductDemand> _legacyProductDemand(
    Map<String, dynamic>? stock,
    ForecastInput input,
  ) {
    final raw = stock?['product_recommendations'];
    if (raw is! List) return const [];

    final byName = {
      for (final p in input.products) p.productName.toLowerCase(): p,
    };

    return [
      for (final entry in raw.whereType<Map>())
        () {
          final map = Map<String, dynamic>.from(entry);
          final name = map['product_name']?.toString() ?? 'Produk';
          final source = byName[name.toLowerCase()];
          final qty =
              (map['recommended_stock_with_safety_buffer'] as num?)?.toInt() ??
              (map['recommended_stock'] as num?)?.toInt() ??
              0;
          return ProductDemand(
            productId: source?.productId,
            productName: name,
            category: map['category']?.toString() ?? source?.category ?? 'Lain-lain',
            predictedQty: (map['predicted_qty'] as num?)?.toInt() ?? qty,
            predictedQtyWeek: (map['predicted_qty'] as num?)?.toInt() != null
                ? ((map['predicted_qty'] as num).toInt() * 7)
                : qty * 7,
            recommendedQty: qty,
          );
        }(),
    ];
  }

  List<ForecastRecommendation> _legacyRecommendations(
    Map<String, dynamic>? target,
  ) {
    final targets = target?['targets'];
    if (targets is! Map) return const [];

    final moderate = (targets['moderat_target'] as num?)?.toInt();
    final aggressive = (targets['agresif_target'] as num?)?.toInt();
    if (moderate == null && aggressive == null) return const [];

    return [
      ForecastRecommendation(
        kind: 'target_omzet',
        title: 'Target Omzet Harian',
        desc: '',
        badge: 'TARGET',
        rationale:
            'Dihitung dari rata-rata 15 hari aktif terakhir dengan faktor '
            'pertumbuhan moderat.',
        payload: {
          if (moderate != null) 'moderate': moderate,
          if (aggressive != null) 'aggressive': aggressive,
        },
      ),
    ];
  }

  void dispose() => _http.close();
}

/// Penanda internal bahwa endpoint v2 belum ada di server.
class _EndpointMissing implements Exception {
  const _EndpointMissing();
}

class _LegacyDaily {
  final List<ForecastPoint> points;
  final ForecastMode mode;
  final String? modelUsedRaw;

  const _LegacyDaily(this.points, this.mode, this.modelUsedRaw);
}
