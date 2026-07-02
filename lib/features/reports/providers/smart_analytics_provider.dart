import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pos_mobile/core/env/env.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/database/isar_service.dart';
import 'package:pos_mobile/core/models/transaction_local.dart';
import 'package:pos_mobile/core/models/product.dart';
import 'package:pos_mobile/core/models/category.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/features/reports/presentation/smart_analytics_screen.dart';
import 'package:isar/isar.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilihan server prediksi yang dipakai fitur Smart Analitik.
enum ApiServerMode { huggingface, local }

class SmartAnalyticsState {
  final bool isLoading;
  final bool isCalibrated;
  final DateTime? lastCalibrationTime;
  final String businessType;
  final String storeName;

  // Selected Tab Data
  final double totalRevenue;
  final String revenueText;
  final String revenueDiff;
  final String trafficText;
  final String bestSellingName;

  // Chart Spots & Labels
  final List<FlSpot> actualSpots;
  final List<FlSpot> forecastSpots;
  final List<String> xLabels;
  final double maxY;

  // Lists
  final List<Map<String, dynamic>> projectedBestSellers;
  final List<Map<String, dynamic>> pricingRecommendations;

  // Insights
  final String coldStartWarning;

  // Status koneksi API
  final bool apiOnline; // true jika endpoint prediksi berhasil dipanggil
  final bool isLocalServer; // true = server lokal, false = HuggingFace Space
  final String apiServerLabel; // label server aktif untuk ditampilkan

  SmartAnalyticsState({
    required this.isLoading,
    required this.isCalibrated,
    this.lastCalibrationTime,
    required this.businessType,
    required this.storeName,
    required this.totalRevenue,
    required this.revenueText,
    required this.revenueDiff,
    required this.trafficText,
    required this.bestSellingName,
    required this.actualSpots,
    required this.forecastSpots,
    required this.xLabels,
    required this.maxY,
    required this.projectedBestSellers,
    required this.pricingRecommendations,
    this.coldStartWarning = "",
    this.apiOnline = false,
    this.isLocalServer = false,
    this.apiServerLabel = "HuggingFace Space",
  });

  factory SmartAnalyticsState.initial() => SmartAnalyticsState(
    isLoading: false,
    isCalibrated: false,
    businessType: "Retail",
    storeName: "Toko POS",
    totalRevenue: 0,
    revenueText: "Rp 0",
    revenueDiff: "0% vs rerata",
    trafficText: "0 Pelanggan",
    bestSellingName: "Belum ada produk",
    actualSpots: [],
    forecastSpots: [],
    xLabels: [],
    maxY: 1000000,
    projectedBestSellers: [],
    pricingRecommendations: [],
    coldStartWarning: "",
  );

  SmartAnalyticsState copyWith({
    bool? isLoading,
    bool? isCalibrated,
    DateTime? lastCalibrationTime,
    String? businessType,
    String? storeName,
    double? totalRevenue,
    String? revenueText,
    String? revenueDiff,
    String? trafficText,
    String? bestSellingName,
    List<FlSpot>? actualSpots,
    List<FlSpot>? forecastSpots,
    List<String>? xLabels,
    double? maxY,
    List<Map<String, dynamic>>? projectedBestSellers,
    List<Map<String, dynamic>>? pricingRecommendations,
    String? coldStartWarning,
    bool? apiOnline,
    bool? isLocalServer,
    String? apiServerLabel,
  }) {
    return SmartAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      lastCalibrationTime: lastCalibrationTime ?? this.lastCalibrationTime,
      businessType: businessType ?? this.businessType,
      storeName: storeName ?? this.storeName,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      revenueText: revenueText ?? this.revenueText,
      revenueDiff: revenueDiff ?? this.revenueDiff,
      trafficText: trafficText ?? this.trafficText,
      bestSellingName: bestSellingName ?? this.bestSellingName,
      actualSpots: actualSpots ?? this.actualSpots,
      forecastSpots: forecastSpots ?? this.forecastSpots,
      xLabels: xLabels ?? this.xLabels,
      maxY: maxY ?? this.maxY,
      projectedBestSellers: projectedBestSellers ?? this.projectedBestSellers,
      pricingRecommendations:
          pricingRecommendations ?? this.pricingRecommendations,
      coldStartWarning: coldStartWarning ?? this.coldStartWarning,
      apiOnline: apiOnline ?? this.apiOnline,
      isLocalServer: isLocalServer ?? this.isLocalServer,
      apiServerLabel: apiServerLabel ?? this.apiServerLabel,
    );
  }
}

class SmartAnalyticsNotifier extends StateNotifier<SmartAnalyticsState> {
  final Ref _ref;
  final SupabaseClient _client = Supabase.instance.client;

  SmartAnalyticsNotifier(this._ref) : super(SmartAnalyticsState.initial());

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // ================================================================
  // KONFIGURASI SERVER PREDIKSI — bisa dipilih (Cloud / Lokal)
  //
  // Endpoint yang dipakai (semua stateless, baseline statistik):
  //   → POST /api/predict/daily
  //   → POST /api/recommendations/stock
  //   → POST /api/recommendations/target
  //
  // [Cloud]  HuggingFace Space — selalu tersedia tanpa server lokal.
  //          URL diatur via Env.lstmHfUrl (override: --dart-define=LSTM_HF_URL=...).
  // [Lokal]  python app_public.py di komputer (port 5000).
  //   Emulator Android : 10.0.2.2 (otomatis).
  //   HP fisik Android : Env.lstmLocalPhysicalUrl — ganti dengan IP komputer
  //                      di jaringan yang sama (cek: ipconfig / ip addr) via
  //                      --dart-define=LSTM_LOCAL_PHYSICAL_URL=http://<ip>:5000
  // ================================================================
  static const String _prefsServerModeKey = 'smart_api_server_mode';

  ApiServerMode _serverMode = ApiServerMode.huggingface;

  /// URL server lokal sesuai platform.
  String _localBaseUrl({bool usePhysicalDevice = false}) {
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) {
      return usePhysicalDevice
          ? Env.lstmLocalPhysicalUrl
          : 'http://10.140.135.148:5000';
    }
    return 'http://localhost:5000';
  }

  /// URL server prediksi aktif sesuai [_serverMode].
  String getLstmBaseUrl() =>
      _serverMode == ApiServerMode.local ? _localBaseUrl() : Env.lstmHfUrl;

  /// Label server aktif untuk ditampilkan di UI.
  String get _serverLabel =>
      _serverMode == ApiServerMode.local ? "Server Lokal" : "HuggingFace Space";

  /// Baca pilihan server yang tersimpan (dipanggil di awal load).
  Future<void> _loadServerMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsServerModeKey);
    _serverMode = saved == 'local'
        ? ApiServerMode.local
        : ApiServerMode.huggingface;
  }

  /// Ganti server prediksi (Cloud/Lokal), simpan pilihan, lalu muat ulang.
  Future<void> setServerMode(bool useLocal, ForecastTab tab) async {
    _serverMode = useLocal ? ApiServerMode.local : ApiServerMode.huggingface;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsServerModeKey, useLocal ? 'local' : 'hf');
    state = state.copyWith(
      isLocalServer: useLocal,
      apiServerLabel: _serverLabel,
    );
    await loadSmartAnalytics(tab);
  }

  Future<void> loadSmartAnalytics(
    ForecastTab tab, {
    bool forceCalibrate = false,
  }) async {
    final activeStore = _ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    final storeName = activeStore?['name'] ?? "Toko POS";
    final businessType = activeStore?['business_type'] ?? "Retail";

    // Profil operasional toko — dapat dikonfigurasi via settings.operational.
    // Dipakai untuk menyelaraskan generasi hari-aktif di API model
    // (skip weekend / bulan tutup). Default: buka 7 hari, tanpa bulan tutup.
    final operational =
        (activeStore?['settings']?['operational'] as Map?) ?? const {};
    final openOnWeekends = operational['open_on_weekends'] as bool? ?? true;
    final closedMonths =
        (operational['closed_months'] as List?)?.cast<int>() ?? const <int>[];

    if (storeId == null) {
      state = SmartAnalyticsState.initial();
      return;
    }

    // Pakai pilihan server (Cloud/Lokal) yang tersimpan.
    await _loadServerMode();

    state = state.copyWith(
      isLoading: true,
      storeName: storeName,
      businessType: businessType,
    );

    try {
      final now = DateTime.now();
      // Fetch the last 45 days of transactions to cover the actual historical points
      final startDate = now.subtract(const Duration(days: 45));
      final dateStr = DateFormat('yyyy-MM-dd').format(startDate);

      final isOnline =
          _ref.read(connectivityNotifierProvider).value ==
          ConnectivityStatus.online;
      final isar = IsarService.instance;
      List<dynamic> data = [];

      if (isOnline) {
        try {
          final response = await _client
              .from('transactions')
              .select('*, transaction_items(*)')
              .eq('store_id', storeId)
              .filter('created_at', 'gte', dateStr)
              .order('created_at', ascending: true);

          final remoteData = List<Map<String, dynamic>>.from(response);
          data = remoteData;

          // Sync local database cache
          await isar.writeTxn(() async {
            for (var tx in remoteData) {
              final voucherInfoStr = tx['voucher_info'] != null
                  ? jsonEncode(tx['voucher_info'])
                  : null;
              final txLocal = TransactionLocal(
                supabaseId: tx['id'].toString(),
                storeId: tx['store_id'].toString(),
                cashierId: tx['cashier_id']?.toString() ?? '',
                totalAmount: (tx['total_amount'] as num).toDouble(),
                paymentMethod: tx['payment_method']?.toString() ?? 'Tunai',
                cashPaid:
                    (tx['cash_paid'] as num?)?.toDouble() ??
                    (tx['total_amount'] as num).toDouble(),
                changeAmount: (tx['change_amount'] as num?)?.toDouble() ?? 0.0,
                status: tx['status']?.toString() ?? 'Berhasil',
                tableId: tx['table_id']?.toString(),
                discountTotal:
                    (tx['discount_total'] as num?)?.toDouble() ?? 0.0,
                voucherInfo: voucherInfoStr,
                createdAt: DateTime.parse(tx['created_at']).toLocal(),
                isSynced: true,
              );

              await isar.collection<TransactionLocal>().putBySupabaseId(
                txLocal,
              );

              await isar
                  .collection<TransactionItemLocal>()
                  .filter()
                  .transactionSupabaseIdEqualTo(txLocal.supabaseId)
                  .deleteAll();

              final items = tx['transaction_items'] as List? ?? [];
              for (var item in items) {
                final itemLocal = TransactionItemLocal(
                  transactionSupabaseId: txLocal.supabaseId,
                  productId: item['product_id']?.toString() ?? '',
                  productName: item['product_name']?.toString() ?? 'Produk',
                  unitPrice: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
                  quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                  subtotal: (item['subtotal'] as num?)?.toDouble() ?? 0.0,
                );
                await isar.collection<TransactionItemLocal>().put(itemLocal);
              }
            }
          });
        } catch (e) {
          debugPrint('DEBUG: SmartAnalytics remote fetch failed: $e');
        }
      }

      if (data.isEmpty) {
        final localTxs = await isar
            .collection<TransactionLocal>()
            .filter()
            .storeIdEqualTo(storeId)
            .createdAtGreaterThan(
              startDate.subtract(const Duration(milliseconds: 1)),
              include: false,
            )
            .findAll();

        final List<dynamic> localDataList = [];
        for (var tx in localTxs) {
          final items = await isar
              .collection<TransactionItemLocal>()
              .filter()
              .transactionSupabaseIdEqualTo(tx.supabaseId)
              .findAll();

          localDataList.add({
            'id': tx.supabaseId,
            'total_amount': tx.totalAmount,
            'created_at': tx.createdAt.toIso8601String(),
            'transaction_items': items
                .map(
                  (item) => {
                    'product_id': item.productId,
                    'product_name': item.productName,
                    'unit_price': item.unitPrice,
                    'quantity': item.quantity,
                    'subtotal': item.subtotal,
                  },
                )
                .toList(),
          });
        }
        data = localDataList;
      }

      // Check if we have enough historical data for proper LSTM (30 days or at least 14 days)
      final uniqueDaysWithTransactions = data
          .map(
            (tx) => DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.parse(tx['created_at']).toLocal()),
          )
          .toSet()
          .length;

      String warningStr = "";
      if (uniqueDaysWithTransactions < 14) {
        warningStr =
            "Cold Start: Toko baru memiliki $uniqueDaysWithTransactions hari data transaksi. Model LSTM memerlukan minimal 14 hari transaksi teratur. Saat ini menggunakan estimasi pola bisnis retail/kafe umum.";
      }

      // Aggregate sales by date
      final Map<String, double> salesByDate =
          {}; // Format: yyyy-MM-dd -> Revenue
      final Map<String, int> trafficByDate =
          {}; // Format: yyyy-MM-dd -> Customer count
      final Map<String, int> productsSoldQty =
          {}; // Format: Product Name -> Qty

      for (var tx in data) {
        final date = DateTime.parse(tx['created_at']).toLocal();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final revenue = (tx['total_amount'] as num).toDouble();

        salesByDate[dateKey] = (salesByDate[dateKey] ?? 0) + revenue;
        trafficByDate[dateKey] = (trafficByDate[dateKey] ?? 0) + 1;

        final items = tx['transaction_items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final pName = item['product_name'] as String? ?? 'Produk';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          productsSoldQty[pName] = (productsSoldQty[pName] ?? 0) + qty;
        }
      }

      // 1. Get Top Products (Local calculation for simple references)
      final sortedProducts = productsSoldQty.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final String bestSellerProduct = sortedProducts.isNotEmpty
          ? sortedProducts[0].key
          : "Belum ada produk";

      // 2. Base averages for Mock LSTM (Extremely realistic simulation derived from real averages)
      double avgDailySales = 1200000;
      double avgDailyTraffic = 15;

      if (salesByDate.isNotEmpty) {
        avgDailySales =
            salesByDate.values.reduce((a, b) => a + b) / salesByDate.length;
      }
      if (trafficByDate.isNotEmpty) {
        avgDailyTraffic =
            trafficByDate.values.reduce((a, b) => a + b).toDouble() /
            trafficByDate.length;
      }

      // Simple trend calculation (slope of daily sales)
      double slope = 0;
      if (salesByDate.length > 1) {
        final sortedDates = salesByDate.keys.toList()..sort();
        double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
        final n = sortedDates.length;
        for (int i = 0; i < n; i++) {
          final x = i.toDouble();
          final y = salesByDate[sortedDates[i]]!;
          sumX += x;
          sumY += y;
          sumXY += x * y;
          sumXX += x * x;
        }
        final denominator = (n * sumXX - sumX * sumX);
        if (denominator != 0) {
          slope = (n * sumXY - sumX * sumY) / denominator;
        }
      }

      // Restrict slope from being overly negative/positive
      slope = slope.clamp(-avgDailySales * 0.05, avgDailySales * 0.05);

      // Model inference function mimicking the per-store LSTM (used as local fallback)
      double predictForDay(DateTime date) {
        // Seasonality Multiplier based on Business Type
        double multiplier = 1.0;
        final isWeekend =
            date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;
        if (businessType == "Restaurant" || businessType == "Cafe") {
          multiplier = isWeekend ? 1.45 : 0.85;
        } else {
          // Retail / Others
          multiplier = isWeekend ? 1.2 : 0.95;
        }

        // Add temperature / noise factor to mock deep learning prediction variance
        final randFactor =
            0.93 + (math.Random(date.day).nextDouble() * 0.14); // 0.93 to 1.07
        final baseProjection =
            avgDailySales + (slope * 5); // project forward slightly

        return baseProjection * multiplier * randFactor;
      }

      // ==========================================
      // INTEGRATING LSTM PYTHON SERVER API CALLS
      // ==========================================
      final baseUrl = getLstmBaseUrl();
      final List<Map<String, dynamic>> history = salesByDate.entries
          .map((e) => {'date': e.key, 'revenue': e.value})
          .toList();
      history.sort((a, b) => a['date'].compareTo(b['date']));

      // Load products & categories from Isar for stock allocations
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

      final Map<String, String> categoryMap = {};
      for (var cat in categories) {
        categoryMap[cat.supabaseId] = cat.name;
      }

      final Map<String, String> productCategoryMapById = {};
      final Map<String, String> productCategoryMapByName = {};
      final Map<String, double> productPriceMap = {};

      for (var prod in products) {
        final catName = categoryMap[prod.categoryId] ?? "Lain-lain";
        productCategoryMapById[prod.supabaseId] = catName;
        productCategoryMapByName[prod.name] = catName;
        productPriceMap[prod.name] = prod.price;
      }

      double totalItemRevenue = 0.0;
      final Map<String, double> categoryRevenues = {};
      final Map<String, int> productQuantities = {};
      final Map<String, double> productPrices = {};

      for (var tx in data) {
        final items = tx['transaction_items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final pName = item['product_name'] as String? ?? 'Produk';
          final pId = item['product_id']?.toString() ?? '';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
          final price =
              (item['unit_price'] as num?)?.toDouble() ??
              (qty > 0 ? subtotal / qty : 0.0);

          final catName =
              productCategoryMapById[pId] ??
              productCategoryMapByName[pName] ??
              "Lain-lain";

          categoryRevenues[catName] =
              (categoryRevenues[catName] ?? 0.0) + subtotal;
          totalItemRevenue += subtotal;

          productQuantities[pName] = (productQuantities[pName] ?? 0) + qty;
          productPrices[pName] = price;
        }
      }

      final Map<String, double> categoryShares = {};
      if (totalItemRevenue > 0) {
        categoryRevenues.forEach((cat, rev) {
          categoryShares[cat] = rev / totalItemRevenue;
        });
      } else {
        categoryShares["Makanan"] = 0.5;
        categoryShares["Minuman"] = 0.3;
        categoryShares["Lain-lain"] = 0.2;
      }

      final totalQty = productQuantities.values.isEmpty
          ? 0
          : productQuantities.values.reduce((a, b) => a + b);
      final sortedProductEntries = productQuantities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<Map<String, dynamic>> topProducts = [];
      for (int i = 0; i < math.min(10, sortedProductEntries.length); i++) {
        final entry = sortedProductEntries[i];
        final name = entry.key;
        final qty = entry.value;
        final cat = productCategoryMapByName[name] ?? "Lain-lain";
        final price = productPrices[name]?.round() ?? 10000;
        final qtyShare = totalQty > 0 ? qty / totalQty : 0.0;

        topProducts.add({
          "name": name,
          "category": cat,
          "price": price,
          "qty_share": qtyShare,
        });
      }

      if (topProducts.isEmpty) {
        topProducts.add({
          "name": "Kopi Susu Aren",
          "category": "Minuman",
          "price": 15000,
          "qty_share": 0.5,
        });
        topProducts.add({
          "name": "Croissant Cokelat",
          "category": "Makanan",
          "price": 20000,
          "qty_share": 0.5,
        });
      }

      bool isApiSuccess = false;
      Map<String, dynamic>? dailyForecastData;
      Map<String, dynamic>? stockRecommendationData;
      Map<String, dynamic>? targetRecommendationData;
      String apiConnectionWarning = "";

      try {
        // 1. POST /api/predict/daily (Forecast 30 days ahead)
        // Model (app_public.py) bersifat stateless — tidak memakai store_id.
        // Kirim profil operasional agar generasi hari-aktif konsisten.
        final dailyUrl = Uri.parse('$baseUrl/api/predict/daily');
        final dailyResponse = await http
            .post(
              dailyUrl,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'n_days': 30,
                'k': 4,
                'open_on_weekends': openOnWeekends,
                'closed_months': closedMonths,
                'history': history,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (dailyResponse.statusCode == 200) {
          dailyForecastData =
              jsonDecode(dailyResponse.body) as Map<String, dynamic>;
        }

        // 2. POST /api/recommendations/stock
        double? firstDayForecastRevenue;
        if (dailyForecastData != null &&
            dailyForecastData['predictions'] != null) {
          final preds = dailyForecastData['predictions'] as List<dynamic>;
          if (preds.isNotEmpty) {
            firstDayForecastRevenue =
                (preds.first['predicted_revenue_seasonal_naive'] as num)
                    .toDouble();
          }
        }

        final stockUrl = Uri.parse('$baseUrl/api/recommendations/stock');
        final stockResponse = await http
            .post(
              stockUrl,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                if (firstDayForecastRevenue != null)
                  'predicted_revenue': firstDayForecastRevenue,
                'open_on_weekends': openOnWeekends,
                'closed_months': closedMonths,
                'category_shares': categoryShares,
                'top_products': topProducts,
                'history': history,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (stockResponse.statusCode == 200) {
          stockRecommendationData =
              jsonDecode(stockResponse.body) as Map<String, dynamic>;
        }

        // 3. POST /api/recommendations/target
        if (history.length >= 15) {
          final targetUrl = Uri.parse('$baseUrl/api/recommendations/target');
          final targetResponse = await http
              .post(
                targetUrl,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'factor': 1.10, 'history': history}),
              )
              .timeout(const Duration(seconds: 10));

          if (targetResponse.statusCode == 200) {
            targetRecommendationData =
                jsonDecode(targetResponse.body) as Map<String, dynamic>;
          }
        }

        if (dailyForecastData != null && stockRecommendationData != null) {
          isApiSuccess = true;
          final modelUsed =
              dailyForecastData['metadata']?['model_used'] ?? 'unknown';
          debugPrint('DEBUG: API success — model=$modelUsed');
        } else {
          apiConnectionWarning =
              "Server prediksi mengembalikan status non-200. Menggunakan estimasi lokal sementara.";
        }
      } catch (e) {
        debugPrint("DEBUG: Failed to connect to forecasting server: $e");
        apiConnectionWarning =
            "Gagal terhubung ke server prediksi ($baseUrl). Periksa koneksi internet Anda; sementara menggunakan estimasi lokal.";
      }

      // Helper function to resolve predictions
      double getForecastValue(DateTime targetDate) {
        if (isApiSuccess && dailyForecastData != null) {
          final targetStr = DateFormat('yyyy-MM-dd').format(targetDate);
          final preds = dailyForecastData!['predictions'] as List<dynamic>;
          for (var p in preds) {
            if (p['date'] == targetStr) {
              return (p['predicted_revenue_seasonal_naive'] as num).toDouble();
            }
          }
          if (preds.isNotEmpty) {
            return (preds.last['predicted_revenue_seasonal_naive'] as num)
                .toDouble();
          }
        }
        return predictForDay(targetDate);
      }

      // Prepare UI states based on ForecastTab
      double totalRevenue = 0;
      String revenueText = "";
      String revenueDiff = "";
      String trafficText = "";
      String bestSellingName = bestSellerProduct;
      List<FlSpot> actualSpots = [];
      List<FlSpot> forecastSpots = [];
      List<String> xLabels = [];
      double maxY = 3500000;

      final indonesianDays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

      switch (tab) {
        case ForecastTab.daily:
          // Daily Forecast: Show 5 days actual, 2 days forecast
          for (int i = 4; i >= 0; i--) {
            final targetDate = now.subtract(Duration(days: i));
            final dateKey = DateFormat('yyyy-MM-dd').format(targetDate);
            final val =
                salesByDate[dateKey] ?? getForecastValue(targetDate) * 0.9;
            actualSpots.add(FlSpot((4 - i).toDouble(), val));
            xLabels.add(indonesianDays[targetDate.weekday % 7]);
          }

          final lastActualVal = actualSpots.last.y;
          forecastSpots.add(FlSpot(4, lastActualVal));

          for (int i = 1; i <= 2; i++) {
            final targetDate = now.add(Duration(days: i));
            final val = getForecastValue(targetDate);
            forecastSpots.add(FlSpot((4 + i).toDouble(), val));
            xLabels.add("${indonesianDays[targetDate.weekday % 7]}*");
          }

          final totalForecasted = forecastSpots
              .skip(1)
              .map((s) => s.y)
              .reduce((a, b) => a + b);
          totalRevenue = totalForecasted;
          revenueText = currencyFormat.format(totalForecasted);

          if (isApiSuccess && targetRecommendationData != null) {
            final avg =
                (targetRecommendationData!['historical_basis_15_active_days']['average_revenue']
                        as num)
                    .toDouble();
            if (avg > 0) {
              final diffPercent = ((totalRevenue / 2) - avg) / avg * 100;
              revenueDiff =
                  "${diffPercent >= 0 ? '+' : ''}${diffPercent.toStringAsFixed(1)}% vs rerata";
            } else {
              revenueDiff =
                  "${slope >= 0 ? '+' : ''}${(slope / avgDailySales * 100).toStringAsFixed(1)}% vs rerata";
            }
          } else {
            revenueDiff =
                "${slope >= 0 ? '+' : ''}${(slope / avgDailySales * 100).toStringAsFixed(1)}% vs rerata";
          }

          final estTraffic =
              (avgDailyTraffic *
                      (getForecastValue(now.add(const Duration(days: 1))) /
                          avgDailySales))
                  .round();
          trafficText = "$estTraffic Pelanggan";
          break;

        case ForecastTab.weekly:
          // Weekly Forecast: Show 3 weeks actual, 1 week forecast
          for (int w = 2; w >= 0; w--) {
            double weekSum = 0;
            for (int d = 0; d < 7; d++) {
              final targetDate = now.subtract(Duration(days: (w * 7) + d));
              final dateKey = DateFormat('yyyy-MM-dd').format(targetDate);
              weekSum +=
                  salesByDate[dateKey] ?? getForecastValue(targetDate) * 0.9;
            }
            actualSpots.add(FlSpot((2 - w).toDouble(), weekSum));
            xLabels.add("Minggu ${3 - w}");
          }

          forecastSpots.add(FlSpot(2, actualSpots.last.y));
          double nextWeekSum = 0;
          for (int d = 1; d <= 7; d++) {
            nextWeekSum += getForecastValue(now.add(Duration(days: d)));
          }
          forecastSpots.add(FlSpot(3, nextWeekSum));
          xLabels.add("Minggu 4*");

          totalRevenue = nextWeekSum;
          revenueText = currencyFormat.format(nextWeekSum);

          if (isApiSuccess && targetRecommendationData != null) {
            final avg =
                (targetRecommendationData!['historical_basis_15_active_days']['average_revenue']
                        as num)
                    .toDouble();
            if (avg > 0) {
              final diffPercent = ((nextWeekSum / 7) - avg) / avg * 100;
              revenueDiff =
                  "${diffPercent >= 0 ? '+' : ''}${diffPercent.toStringAsFixed(1)}% vs rerata";
            } else {
              revenueDiff =
                  "${slope >= 0 ? '+' : ''}${(slope / avgDailySales * 100 * 7).toStringAsFixed(1)}% vs rerata";
            }
          } else {
            revenueDiff =
                "${slope >= 0 ? '+' : ''}${(slope / avgDailySales * 100 * 7).toStringAsFixed(1)}% vs rerata";
          }

          final weeklyTraffic = (avgDailyTraffic * 7).round();
          trafficText = "$weeklyTraffic Pelanggan";
          break;

        case ForecastTab.monthly:
          // Monthly Forecast: Show 5 months actual, 1 month forecast
          final indonesianMonths = [
            'Des',
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agu',
            'Sep',
            'Okt',
            'Nov',
          ];

          for (int m = 4; m >= 0; m--) {
            final targetMonth = DateTime(now.year, now.month - m, 1);
            double monthSum = 0;
            final daysInMonth = DateTime(
              targetMonth.year,
              targetMonth.month + 1,
              0,
            ).day;

            for (int d = 0; d < daysInMonth; d++) {
              final targetDate = targetMonth.add(Duration(days: d));
              final dateKey = DateFormat('yyyy-MM-dd').format(targetDate);
              monthSum +=
                  salesByDate[dateKey] ?? getForecastValue(targetDate) * 0.85;
            }
            actualSpots.add(FlSpot((4 - m).toDouble(), monthSum));
            xLabels.add(indonesianMonths[(targetMonth.month - 1) % 12]);
          }

          forecastSpots.add(FlSpot(4, actualSpots.last.y));
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          final daysInNextMonth = DateTime(
            nextMonth.year,
            nextMonth.month + 1,
            0,
          ).day;
          double nextMonthSum = 0;
          for (int d = 0; d < daysInNextMonth; d++) {
            nextMonthSum += getForecastValue(now.add(Duration(days: d + 1)));
          }
          forecastSpots.add(FlSpot(5, nextMonthSum));
          xLabels.add("${indonesianMonths[(nextMonth.month - 1) % 12]}*");

          totalRevenue = nextMonthSum;
          revenueText = currencyFormat.format(nextMonthSum);

          if (isApiSuccess && targetRecommendationData != null) {
            final avg =
                (targetRecommendationData!['historical_basis_15_active_days']['average_revenue']
                        as num)
                    .toDouble();
            if (avg > 0) {
              final diffPercent =
                  ((nextMonthSum / daysInNextMonth) - avg) / avg * 100;
              revenueDiff =
                  "${diffPercent >= 0 ? '+' : ''}${diffPercent.toStringAsFixed(1)}% vs rerata";
            } else {
              revenueDiff =
                  "${slope >= 0 ? '+' : ''}${(slope / avgDailySales * 100 * 30).toStringAsFixed(1)}% vs rerata";
            }
          } else {
            revenueDiff =
                "${slope >= 0 ? '+' : ''}${(slope / avgDailySales * 100 * 30).toStringAsFixed(1)}% vs rerata";
          }

          final monthlyTraffic = (avgDailyTraffic * daysInNextMonth).round();
          trafficText = "$monthlyTraffic Pelanggan";
          break;

        case ForecastTab.custom:
          // Custom Forecast: Show 3 days actual, 3 days forecast
          for (int i = 2; i >= 0; i--) {
            final targetDate = now.subtract(Duration(days: i));
            final dateKey = DateFormat('yyyy-MM-dd').format(targetDate);
            final val =
                salesByDate[dateKey] ?? getForecastValue(targetDate) * 0.95;
            actualSpots.add(FlSpot((2 - i).toDouble(), val));
            xLabels.add(i == 0 ? "Hari Ini" : "H-$i");
          }

          forecastSpots.add(FlSpot(2, actualSpots.last.y));
          for (int i = 1; i <= 3; i++) {
            final targetDate = now.add(Duration(days: i));
            final val = getForecastValue(targetDate);
            forecastSpots.add(FlSpot((2 + i).toDouble(), val));
            xLabels.add(i == 1 ? "Besok*" : "H+$i*");
          }

          final customForecasted = forecastSpots
              .skip(1)
              .map((s) => s.y)
              .reduce((a, b) => a + b);
          totalRevenue = customForecasted;
          revenueText = currencyFormat.format(customForecasted);
          revenueDiff = "Proyeksi 3 hari ke depan";

          final customTraffic = (avgDailyTraffic * 3).round();
          trafficText = "$customTraffic Pelanggan";
          break;
      }

      final allSpots = [...actualSpots, ...forecastSpots];
      final maxVal = allSpots.map((s) => s.y).reduce(math.max);
      maxY = (maxVal * 1.25);
      if (maxY == 0) maxY = 1000000;

      // 3. Projected Best Sellers (dynamically using stock recommendations)
      final List<Map<String, dynamic>> projectedBestSellers = [];
      if (isApiSuccess &&
          stockRecommendationData != null &&
          stockRecommendationData['product_recommendations'] != null) {
        final recs =
            stockRecommendationData['product_recommendations'] as List<dynamic>;
        for (int i = 0; i < math.min(3, recs.length); i++) {
          final rec = recs[i];
          projectedBestSellers.add({
            'name': rec['product_name'] as String,
            'category': rec['category'] as String,
            'quantity': rec['recommended_stock_with_safety_buffer'] as int,
          });
        }
      } else {
        // Fallback lokal: proyeksi kuantitas dari rata-rata penjualan aktual toko
        for (int i = 0; i < math.min(3, sortedProducts.length); i++) {
          final p = sortedProducts[i];
          final projectedQty = (p.value / 30 * 1.2).ceil() + 2;
          projectedBestSellers.add({
            'name': p.key,
            'category': businessType == "Cafe" || businessType == "Restaurant"
                ? "Minuman/Makanan"
                : "Barang Retail",
            'quantity': projectedQty,
          });
        }
      }

      // 4. Rekomendasi — hanya Target Omzet dari model (bila online).
      final List<Map<String, dynamic>> recommendations = [];

      if (isApiSuccess && targetRecommendationData != null) {
        final targets = targetRecommendationData['targets'];
        final moderat = (targets['moderat_target'] as num).toInt();
        final agresif = (targets['agresif_target'] as num).toInt();
        recommendations.add({
          'title': 'Target Omzet Harian AI',
          'desc':
              'Target Moderat: ${currencyFormat.format(moderat)}. Target Agresif: ${currencyFormat.format(agresif)}.',
          'badge': 'TARGET AI 🎯',
          'color': const Color(0xFF6B4EFF),
          'rationale':
              'Dihitung berdasarkan rata-rata 15 hari terakhir dengan penyesuaian faktor pertumbuhan moderat.',
          'icon': TablerIcons.target,
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final lastCalTimeStr = prefs.getString("last_calibration_time_$storeId");
      final lastCalTime = lastCalTimeStr != null
          ? DateTime.parse(lastCalTimeStr)
          : null;

      // Append API warning to cold start warning if offline/unreachable
      String finalWarning = warningStr;
      if (apiConnectionWarning.isNotEmpty) {
        if (finalWarning.isNotEmpty) {
          finalWarning += "\n\n$apiConnectionWarning";
        } else {
          finalWarning = apiConnectionWarning;
        }
      }

      state = SmartAnalyticsState(
        isLoading: false,
        isCalibrated: forceCalibrate || lastCalTime != null,
        lastCalibrationTime: lastCalTime,
        businessType: businessType,
        storeName: storeName,
        totalRevenue: totalRevenue,
        revenueText: revenueText,
        revenueDiff: revenueDiff,
        trafficText: trafficText,
        bestSellingName: bestSellingName,
        actualSpots: actualSpots,
        forecastSpots: forecastSpots,
        xLabels: xLabels,
        maxY: maxY,
        projectedBestSellers: projectedBestSellers,
        pricingRecommendations: recommendations,
        coldStartWarning: finalWarning,
        apiOnline: isApiSuccess,
        isLocalServer: _serverMode == ApiServerMode.local,
        apiServerLabel: _serverLabel,
      );
    } catch (e, st) {
      debugPrint('DEBUG: General exception loading Smart Analytics: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Memuat ulang analisis dengan mengambil forecast terbaru dari model.
  /// Model produksi bersifat stateless (baseline statistik) — tidak ada
  /// training per toko, jadi ini murni menyegarkan data.
  Future<void> refreshAnalytics(ForecastTab tab) async {
    final activeStore = _ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];
    if (storeId == null) return;

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "last_calibration_time_$storeId",
      now.toIso8601String(),
    );

    await loadSmartAnalytics(tab, forceCalibrate: true);
  }
}

final smartAnalyticsProvider =
    StateNotifierProvider<SmartAnalyticsNotifier, SmartAnalyticsState>((ref) {
      return SmartAnalyticsNotifier(ref);
    });
