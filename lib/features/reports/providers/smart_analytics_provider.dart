import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_mobile/core/env/env.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/reports/data/forecast_notification_service.dart';
import 'package:pos_mobile/features/reports/data/lstm_api_client.dart';
import 'package:pos_mobile/features/reports/data/smart_analytics_repository.dart';
import 'package:pos_mobile/features/reports/domain/local_forecast_estimator.dart';
import 'package:pos_mobile/features/reports/domain/tab_aggregator.dart';
import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_mode.dart';
import 'package:pos_mobile/features/reports/models/forecast_point.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';
import 'package:pos_mobile/features/reports/models/forecast_snapshot.dart';
import 'package:pos_mobile/features/reports/models/forecast_tab.dart';
import 'package:pos_mobile/features/reports/models/tab_analytics_data.dart';

export 'package:pos_mobile/features/reports/models/forecast_snapshot.dart'
    show SmartAnalyticsHistoryItem;

/// Pilihan server prediksi yang dipakai fitur Smart Analitik.
enum ApiServerMode { huggingface, local }

/// Ambang jumlah hari data sebelum peringatan cold-start ditampilkan.
const int kColdStartMinDays = 14;

class SmartAnalyticsState {
  final bool isLoading;

  /// Toko belum pernah menjalankan analisis sama sekali.
  final bool isEmpty;

  /// Sedang menampilkan snapshot riwayat (read-only).
  final bool isHistoryView;

  /// Hasil dibaca dari cache perangkat karena Supabase tidak bisa dihubungi.
  final bool isFromCache;

  final String? snapshotId;
  final DateTime? snapshotCreatedAt;
  final String businessType;
  final String storeName;

  /// Data siap-tampil untuk tab yang sedang dipilih.
  final TabAnalyticsData tab;
  final ForecastTab selectedTab;

  final String bestSellingName;
  final List<ProductDemand> projectedBestSellers;
  final List<ForecastRecommendation> recommendations;

  /// Model yang benar-benar menghasilkan angka — penentu label di UI.
  final ForecastMode mode;
  final String? modelVersion;
  final String? fallbackReason;
  final ForecastMetrics metrics;
  final int inputDays;

  final String coldStartWarning;
  final bool apiOnline;
  final bool isLocalServer;
  final String apiServerLabel;

  /// Hasil model mentah — dipakai untuk menghitung ulang tab kustom dan
  /// dibagikan ke fitur lain lewat [forecastProvider].
  final ForecastResult? forecast;

  /// Riwayat yang menjadi input model, untuk menggambar garis aktual.
  final ForecastInput? input;

  final DateTime? customFrom;
  final DateTime? customTo;

  const SmartAnalyticsState({
    required this.isLoading,
    this.isEmpty = false,
    this.isHistoryView = false,
    this.isFromCache = false,
    this.snapshotId,
    this.snapshotCreatedAt,
    this.businessType = 'Retail',
    this.storeName = 'Toko POS',
    required this.tab,
    this.selectedTab = ForecastTab.daily,
    this.bestSellingName = 'Belum ada produk',
    this.projectedBestSellers = const [],
    this.recommendations = const [],
    this.mode = ForecastMode.offlineLocal,
    this.modelVersion,
    this.fallbackReason,
    this.metrics = const ForecastMetrics(),
    this.inputDays = 0,
    this.coldStartWarning = '',
    this.apiOnline = false,
    this.isLocalServer = false,
    this.apiServerLabel = 'HuggingFace Space',
    this.forecast,
    this.input,
    this.customFrom,
    this.customTo,
  });

  factory SmartAnalyticsState.initial() =>
      SmartAnalyticsState(isLoading: false, isEmpty: true, tab: TabAnalyticsData.empty());

  /// True bila angka yang ditampilkan benar-benar keluar dari LSTM.
  bool get isLstm => mode.isLstm;

  SmartAnalyticsState copyWith({
    bool? isLoading,
    bool? isEmpty,
    bool? isHistoryView,
    bool? isFromCache,
    String? snapshotId,
    DateTime? snapshotCreatedAt,
    String? businessType,
    String? storeName,
    TabAnalyticsData? tab,
    ForecastTab? selectedTab,
    String? bestSellingName,
    List<ProductDemand>? projectedBestSellers,
    List<ForecastRecommendation>? recommendations,
    ForecastMode? mode,
    String? modelVersion,
    String? fallbackReason,
    ForecastMetrics? metrics,
    int? inputDays,
    String? coldStartWarning,
    bool? apiOnline,
    bool? isLocalServer,
    String? apiServerLabel,
    ForecastResult? forecast,
    ForecastInput? input,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    return SmartAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      isEmpty: isEmpty ?? this.isEmpty,
      isHistoryView: isHistoryView ?? this.isHistoryView,
      isFromCache: isFromCache ?? this.isFromCache,
      snapshotId: snapshotId ?? this.snapshotId,
      snapshotCreatedAt: snapshotCreatedAt ?? this.snapshotCreatedAt,
      businessType: businessType ?? this.businessType,
      storeName: storeName ?? this.storeName,
      tab: tab ?? this.tab,
      selectedTab: selectedTab ?? this.selectedTab,
      bestSellingName: bestSellingName ?? this.bestSellingName,
      projectedBestSellers: projectedBestSellers ?? this.projectedBestSellers,
      recommendations: recommendations ?? this.recommendations,
      mode: mode ?? this.mode,
      modelVersion: modelVersion ?? this.modelVersion,
      fallbackReason: fallbackReason ?? this.fallbackReason,
      metrics: metrics ?? this.metrics,
      inputDays: inputDays ?? this.inputDays,
      coldStartWarning: coldStartWarning ?? this.coldStartWarning,
      apiOnline: apiOnline ?? this.apiOnline,
      isLocalServer: isLocalServer ?? this.isLocalServer,
      apiServerLabel: apiServerLabel ?? this.apiServerLabel,
      forecast: forecast ?? this.forecast,
      input: input ?? this.input,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
    );
  }
}

class SmartAnalyticsNotifier extends StateNotifier<SmartAnalyticsState> {
  final Ref _ref;
  final SmartAnalyticsRepository _repository;
  final LstmApiClient _api;

  SmartAnalyticsNotifier(
    this._ref, {
    SmartAnalyticsRepository? repository,
    LstmApiClient? api,
  }) : _repository = repository ?? SmartAnalyticsRepository(),
       _api = api ?? LstmApiClient(),
       super(SmartAnalyticsState.initial());

  static const String _prefsServerModeKey = 'smart_api_server_mode';

  ApiServerMode _serverMode = ApiServerMode.huggingface;

  /// Baris snapshot terakhir yang ditampilkan, di-cache agar pindah tab tidak
  /// perlu query ulang.
  Map<String, dynamic>? _cachedRow;
  String? _cachedRowKey;

  // ================================================================
  // Konfigurasi server prediksi
  // ================================================================

  String _localBaseUrl() {
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return Env.lstmLocalPhysicalUrl;
    return 'http://localhost:5000';
  }

  String getLstmBaseUrl() =>
      _serverMode == ApiServerMode.local ? _localBaseUrl() : Env.lstmHfUrl;

  String get _serverLabel =>
      _serverMode == ApiServerMode.local ? 'Server Lokal' : 'HuggingFace Space';

  Future<void> _loadServerMode() async {
    final prefs = await SharedPreferences.getInstance();
    _serverMode = prefs.getString(_prefsServerModeKey) == 'local'
        ? ApiServerMode.local
        : ApiServerMode.huggingface;
  }

  Future<void> setServerMode(bool useLocal, ForecastTab tab) async {
    _serverMode = useLocal ? ApiServerMode.local : ApiServerMode.huggingface;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsServerModeKey, useLocal ? 'local' : 'hf');
    state = state.copyWith(
      isLocalServer: useLocal,
      apiServerLabel: _serverLabel,
    );
    await refreshAnalytics(tab);
  }

  // ================================================================
  // Membaca snapshot (tanpa memanggil model)
  // ================================================================

  /// Memuat analisis terbaru toko aktif. Tidak memanggil server model —
  /// hanya membaca snapshot terakhir dari Supabase, atau dari cache perangkat
  /// bila sedang offline (T-06).
  Future<void> loadSmartAnalytics(ForecastTab tab) async {
    final store = _ref.read(activeStoreProvider).value;
    final storeId = store?['id']?.toString();
    final storeName = store?['name']?.toString() ?? 'Toko POS';
    final businessType = store?['business_type']?.toString() ?? 'Retail';

    if (storeId == null) {
      state = SmartAnalyticsState.initial();
      return;
    }

    await _loadServerMode();

    final cacheKey = 'live:$storeId';
    if (_cachedRow != null && _cachedRowKey == cacheKey) {
      state = _stateFromRow(
        _cachedRow!,
        tab,
        storeName: storeName,
        businessType: businessType,
        isFromCache: state.isFromCache,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      storeName: storeName,
      businessType: businessType,
      isHistoryView: false,
      selectedTab: tab,
    );

    var row = await _repository.fetchLatestSnapshot(storeId);
    var fromCache = false;
    if (row == null) {
      row = await _repository.readCachedSnapshot(storeId);
      fromCache = row != null;
    }

    if (row == null) {
      _cachedRow = null;
      _cachedRowKey = null;
      state = SmartAnalyticsState.initial().copyWith(
        storeName: storeName,
        businessType: businessType,
        isLocalServer: _serverMode == ApiServerMode.local,
        apiServerLabel: _serverLabel,
        selectedTab: tab,
      );
      return;
    }

    _cachedRow = row;
    _cachedRowKey = cacheKey;
    state = _stateFromRow(
      row,
      tab,
      storeName: storeName,
      businessType: businessType,
      isFromCache: fromCache,
    );

    // Isi realisasi untuk prediksi yang tanggalnya sudah lewat (best-effort).
    if (!fromCache) {
      _fireAndForget(_repository.evaluateForecastPoints(storeId));
    }
  }

  Future<List<SmartAnalyticsHistoryItem>> fetchHistory() async {
    final storeId = _ref.read(activeStoreProvider).value?['id']?.toString();
    if (storeId == null) return [];
    return _repository.fetchHistory(storeId);
  }

  Future<void> viewSnapshot(String id, ForecastTab tab) async {
    if (_cachedRow != null && _cachedRowKey == id) {
      state = _stateFromRow(_cachedRow!, tab, isHistoryView: true);
      return;
    }

    state = state.copyWith(isLoading: true, isHistoryView: true, selectedTab: tab);
    final row = await _repository.fetchSnapshot(id);
    if (row == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    _cachedRow = row;
    _cachedRowKey = id;
    state = _stateFromRow(row, tab, isHistoryView: true);
  }

  /// Mengubah rentang tab kustom tanpa memanggil model — cukup menghitung
  /// ulang dari hasil forecast yang sudah tersimpan.
  void setCustomRange(DateTime from, DateTime to) {
    final forecast = state.forecast;
    final input = state.input;
    if (forecast == null || input == null) return;

    final tabData = TabAggregator.compute(
      tab: ForecastTab.custom,
      now: state.snapshotCreatedAt ?? DateTime.now(),
      input: input,
      forecast: forecast,
      customFrom: from,
      customTo: to,
    );

    state = state.copyWith(
      tab: tabData,
      selectedTab: ForecastTab.custom,
      customFrom: from,
      customTo: to,
    );
  }

  // ================================================================
  // Menjalankan analisis baru (satu-satunya jalur yang memanggil model)
  // ================================================================

  Future<void> refreshAnalytics(ForecastTab tab) async {
    final store = _ref.read(activeStoreProvider).value;
    final storeId = store?['id']?.toString();
    if (storeId == null) return;

    final storeName = store?['name']?.toString() ?? 'Toko POS';
    final businessType = store?['business_type']?.toString() ?? 'Retail';
    final profile = StoreOperationalProfile.fromStoreSettings(store);

    await _loadServerMode();

    state = state.copyWith(
      isLoading: true,
      storeName: storeName,
      businessType: businessType,
      isHistoryView: false,
      isFromCache: false,
      selectedTab: tab,
    );

    try {
      final now = DateTime.now();
      final isOnline =
          _ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;

      final input = await _repository.loadInput(
        storeId: storeId,
        profile: profile,
        isOnline: isOnline,
      );

      final baseUrl = getLstmBaseUrl();
      ForecastResult forecast;
      String apiWarning = '';

      if (!isOnline) {
        forecast = LocalForecastEstimator.estimate(
          now: now,
          input: input,
          reason: 'offline',
        );
        apiWarning =
            'Perangkat sedang offline. Angka di bawah adalah estimasi '
            'statistik dari riwayat toko, bukan hasil model.';
      } else {
        try {
          forecast = await _api.fetchForecast(
            baseUrl: baseUrl,
            input: input,
            now: now,
          );
        } on LstmApiException catch (e) {
          debugPrint('DEBUG: Server prediksi gagal: $e');
          forecast = LocalForecastEstimator.estimate(
            now: now,
            input: input,
            reason: e.reason,
          );
          apiWarning =
              'Gagal terhubung ke server prediksi ($baseUrl): ${e.message} '
              'Sementara menggunakan estimasi statistik lokal.';
        }
      }

      // Lengkapi permintaan produk bila server tidak mengirimkannya.
      if (forecast.productDemand.isEmpty) {
        forecast = forecast.copyWith(
          productDemand: LocalForecastEstimator.productDemandFromHistory(input),
        );
      }

      // Endpoint v1 belum mengenal rekomendasi promo. Turunkan dari jam sepi
      // toko sendiri agar rekomendasi tetap bisa ditindaklanjuti; labelnya
      // tetap mengikuti mode yang berlaku, bukan diklaim sebagai LSTM.
      if (forecast.recommendationOfKind('happy_hour') == null) {
        final quietHour = LocalForecastEstimator.quietHourRecommendation(input);
        if (quietHour != null) {
          forecast = forecast.copyWith(
            recommendations: [...forecast.recommendations, quietHour],
          );
        }
      }

      final tabs = TabAggregator.computeAll(
        now: now,
        input: input,
        forecast: forecast,
      );

      final warning = _buildWarning(input, forecast, apiWarning);
      final bestSeller = input.products.isNotEmpty
          ? input.products.first.productName
          : 'Belum ada produk';

      final payload = _buildSnapshotPayload(
        storeId: storeId,
        storeName: storeName,
        businessType: businessType,
        profile: profile,
        input: input,
        forecast: forecast,
        tabs: tabs,
        warning: warning,
        bestSeller: bestSeller,
      );

      final saved = await _repository.saveSnapshot(payload);
      final row = saved ?? _localRow(payload, now);

      _cachedRow = row;
      _cachedRowKey = saved != null ? 'live:$storeId' : null;
      await _repository.cacheSnapshot(storeId, row);

      // Perbarui notifikasi prediksi esok hari dari cache yang baru ditulis.
      _fireAndForget(
        ForecastNotificationService.instance.syncFromCache(storeId),
      );

      if (saved != null) {
        _fireAndForget(
          _repository.saveForecastPoints(
            storeId: storeId,
            snapshotId: saved['id']?.toString(),
            forecast: forecast,
            now: now,
          ),
        );
      }

      state = _stateFromRow(
        row,
        tab,
        storeName: storeName,
        businessType: businessType,
        isFromCache: saved == null,
      );
    } catch (e, stack) {
      debugPrint('DEBUG: Gagal menjalankan analisis: $e\n$stack');
      state = state.copyWith(isLoading: false);
    }
  }

  String _buildWarning(
    ForecastInput input,
    ForecastResult forecast,
    String apiWarning,
  ) {
    final parts = <String>[];
    final activeDays = input.activeDays;

    if (activeDays < kColdStartMinDays) {
      parts.add(
        'Toko baru memiliki $activeDays hari data transaksi. Prediksi LSTM '
        'memerlukan minimal $kColdStartMinDays hari data teratur; sementara '
        'ini angka dihitung dari pola yang ada.',
      );
    } else if (!forecast.mode.isLstm &&
        forecast.metadata.fallbackReason == 'insufficient_history') {
      final remaining = forecast.metadata.daysUntilLstmReady;
      parts.add(
        'Model masih memakai baseline statistik. Prediksi LSTM aktif setelah '
        '$remaining hari data lagi.',
      );
    }

    if (apiWarning.isNotEmpty) parts.add(apiWarning);
    return parts.join('\n\n');
  }

  Map<String, dynamic> _buildSnapshotPayload({
    required String storeId,
    required String storeName,
    required String businessType,
    required StoreOperationalProfile profile,
    required ForecastInput input,
    required ForecastResult forecast,
    required Map<ForecastTab, TabAnalyticsData> tabs,
    required String warning,
    required String bestSeller,
  }) {
    final dailyTab = tabs[ForecastTab.daily]!;
    final topDemand = forecast.productDemand.take(3).toList();

    return {
      'store_id': storeId,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
      'business_type': businessType,
      'store_name': storeName,
      'model_used': forecast.metadata.mode.apiValue,
      'api_online': forecast.metadata.mode.isFromServer,
      'is_local_server': _serverMode == ApiServerMode.local,
      'api_server_label': _serverLabel,
      'cold_start_warning': warning,
      'best_selling_name': bestSeller,
      'total_revenue': dailyTab.totalRevenue,
      'revenue_text': dailyTab.revenueText,
      // Bentuk superset: kunci lama (`name`/`quantity`) tetap ada agar
      // snapshot bisa dibaca klien versi sebelumnya.
      'projected_best_sellers': [
        for (final d in topDemand)
          {
            'name': d.productName,
            'quantity': d.recommendedQty > 0 ? d.recommendedQty : d.predictedQty,
            ...d.toJson(),
          },
      ],
      'pricing_recommendations': [
        for (final r in forecast.recommendations) r.toJson(),
      ],
      'tab_data': {
        for (final entry in tabs.entries) entry.key.name: entry.value.toJson(),
      },
      // ---- Kolom hasil migrasi 2026-07-28 (opsional) ----
      'model_version': forecast.metadata.modelVersion,
      'fallback_reason': forecast.metadata.fallbackReason,
      'input_days': input.activeDays,
      'metrics': forecast.metrics.toJson(),
      'hourly_traffic': [for (final h in forecast.hourly) h.toJson()],
      'product_demand': [for (final d in forecast.productDemand) d.toJson()],
      'forecast_payload': ForecastSnapshotPayload(
        forecast: forecast,
        inputDaily: input.daily,
        profile: profile,
      ).toJson(),
    };
  }

  /// Baris tiruan saat penyimpanan ke Supabase gagal (mis. offline) sehingga
  /// hasil tetap bisa ditampilkan dan disimpan ke cache perangkat.
  Map<String, dynamic> _localRow(Map<String, dynamic> payload, DateTime now) {
    return {
      ...payload,
      'id': null,
      'created_at': now.toUtc().toIso8601String(),
    };
  }

  // ================================================================
  // Membangun state dari satu baris snapshot
  // ================================================================

  SmartAnalyticsState _stateFromRow(
    Map<String, dynamic> row,
    ForecastTab tab, {
    String? storeName,
    String? businessType,
    bool isHistoryView = false,
    bool isFromCache = false,
  }) {
    final createdAt = row['created_at'] != null
        ? DateTime.parse(row['created_at'] as String).toLocal()
        : null;

    final payload = ForecastSnapshotPayload.fromJson(
      row['forecast_payload'] is Map
          ? Map<String, dynamic>.from(row['forecast_payload'] as Map)
          : null,
    );

    TabAnalyticsData tabData;
    if (payload != null) {
      // Snapshot baru: hitung ulang dari hasil model + riwayat aslinya,
      // memakai waktu pembuatan snapshot sebagai acuan "sekarang".
      tabData = TabAggregator.compute(
        tab: tab,
        now: createdAt ?? DateTime.now(),
        input: payload.toInput(),
        forecast: payload.forecast,
      );
    } else {
      // Snapshot lama: pakai `tab_data` yang sudah terhitung.
      final tabJson = (row['tab_data'] as Map?)?[tab.name];
      tabData = tabJson is Map
          ? TabAnalyticsData.fromJson(Map<String, dynamic>.from(tabJson))
          : TabAnalyticsData.empty();
    }

    List<Map<String, dynamic>> listOf(String key) =>
        (row[key] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    final demandRows = listOf('product_demand');
    final bestSellerRows = listOf('projected_best_sellers');

    return SmartAnalyticsState(
      isLoading: false,
      isEmpty: false,
      isHistoryView: isHistoryView,
      isFromCache: isFromCache,
      snapshotId: row['id']?.toString(),
      snapshotCreatedAt: createdAt,
      businessType:
          businessType ?? row['business_type']?.toString() ?? 'Retail',
      storeName: storeName ?? row['store_name']?.toString() ?? 'Toko POS',
      tab: tabData,
      selectedTab: tab,
      bestSellingName:
          row['best_selling_name']?.toString() ?? 'Belum ada produk',
      projectedBestSellers: (demandRows.isNotEmpty ? demandRows : bestSellerRows)
          .map(ProductDemand.fromJson)
          .toList(),
      recommendations: listOf(
        'pricing_recommendations',
      ).map(ForecastRecommendation.fromJson).toList(),
      mode: ForecastMode.fromApi(row['model_used']?.toString()),
      modelVersion: row['model_version']?.toString(),
      fallbackReason: row['fallback_reason']?.toString(),
      metrics: row['metrics'] is Map
          ? ForecastMetrics.fromJson(
              Map<String, dynamic>.from(row['metrics'] as Map),
            )
          : const ForecastMetrics(),
      inputDays: (row['input_days'] as num?)?.toInt() ?? 0,
      coldStartWarning: row['cold_start_warning']?.toString() ?? '',
      apiOnline: row['api_online'] as bool? ?? false,
      isLocalServer: row['is_local_server'] as bool? ?? false,
      apiServerLabel:
          row['api_server_label']?.toString() ?? 'HuggingFace Space',
      forecast: payload?.forecast,
      input: payload?.toInput(),
    );
  }
}

/// Menjalankan future latar tanpa menunggu, tetap mencatat kegagalannya
/// supaya error tidak hilang diam-diam.
void _fireAndForget(Future<void> future) {
  future.catchError((Object e) {
    debugPrint('DEBUG: operasi latar gagal: $e');
  });
}

final smartAnalyticsProvider =
    StateNotifierProvider<SmartAnalyticsNotifier, SmartAnalyticsState>((ref) {
      return SmartAnalyticsNotifier(ref);
    });
