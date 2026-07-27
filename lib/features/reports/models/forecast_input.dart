import 'package:pos_mobile/features/reports/models/forecast_point.dart';

/// Profil operasional toko yang memengaruhi pola penjualan.
/// Diisi dari `stores.settings.operational` (lihat layar Info Toko).
class StoreOperationalProfile {
  final String businessType;
  final bool openOnWeekends;

  /// Bulan (1-12) di mana toko tutup total, mis. libur panjang musiman.
  final List<int> closedMonths;

  /// Hari buka dalam format ISO: 1 = Senin … 7 = Minggu.
  final List<int> openWeekdays;

  final int openHour;
  final int closeHour;

  const StoreOperationalProfile({
    this.businessType = 'Retail',
    this.openOnWeekends = true,
    this.closedMonths = const [],
    this.openWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.openHour = 8,
    this.closeHour = 21,
  });

  /// Membaca profil dari map `settings.operational` milik toko aktif.
  factory StoreOperationalProfile.fromStoreSettings(
    Map<String, dynamic>? store,
  ) {
    final settings = store?['settings'];
    final operational = settings is Map ? settings['operational'] : null;
    final map = operational is Map
        ? Map<String, dynamic>.from(operational)
        : <String, dynamic>{};

    final weekdays =
        (map['open_weekdays'] as List?)
            ?.map((e) => (e as num).toInt())
            .where((d) => d >= 1 && d <= 7)
            .toList() ??
        const [1, 2, 3, 4, 5, 6, 7];

    // `open_on_weekends` tetap dibaca demi kompatibilitas dengan data lama,
    // tapi bila `open_weekdays` tersedia nilainya diturunkan dari sana.
    final openWeekends = weekdays.contains(6) || weekdays.contains(7);

    return StoreOperationalProfile(
      businessType: store?['business_type']?.toString() ?? 'Retail',
      openOnWeekends: map.containsKey('open_weekdays')
          ? openWeekends
          : (map['open_on_weekends'] as bool? ?? true),
      closedMonths:
          (map['closed_months'] as List?)
              ?.map((e) => (e as num).toInt())
              .where((m) => m >= 1 && m <= 12)
              .toList() ??
          const [],
      openWeekdays: weekdays.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : weekdays,
      openHour: (map['open_hour'] as num?)?.toInt() ?? 8,
      closeHour: (map['close_hour'] as num?)?.toInt() ?? 21,
    );
  }

  /// Membaca profil dari bentuk datar hasil [toJson].
  factory StoreOperationalProfile.fromJson(Map<String, dynamic> json) {
    final weekdays =
        (json['open_weekdays'] as List?)
            ?.map((e) => (e as num).toInt())
            .where((d) => d >= 1 && d <= 7)
            .toList() ??
        const [1, 2, 3, 4, 5, 6, 7];

    return StoreOperationalProfile(
      businessType: json['business_type']?.toString() ?? 'Retail',
      openOnWeekends: json['open_on_weekends'] as bool? ?? true,
      closedMonths:
          (json['closed_months'] as List?)
              ?.map((e) => (e as num).toInt())
              .where((m) => m >= 1 && m <= 12)
              .toList() ??
          const [],
      openWeekdays: weekdays.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : weekdays,
      openHour: (json['open_hour'] as num?)?.toInt() ?? 8,
      closeHour: (json['close_hour'] as num?)?.toInt() ?? 21,
    );
  }

  bool isOpenOn(DateTime date) {
    if (closedMonths.contains(date.month)) return false;
    return openWeekdays.contains(date.weekday);
  }

  Map<String, dynamic> toJson() => {
    'business_type': businessType,
    'open_on_weekends': openOnWeekends,
    'closed_months': closedMonths,
    'open_weekdays': openWeekdays,
    'open_hour': openHour,
    'close_hour': closeHour,
  };
}

/// Agregat penjualan satu hari — satuan input utama model.
class DailySalesPoint {
  final DateTime date;
  final double revenue;
  final int txCount;
  final int itemCount;

  const DailySalesPoint({
    required this.date,
    required this.revenue,
    this.txCount = 0,
    this.itemCount = 0,
  });

  String get dateKey => forecastDateKey(date);

  Map<String, dynamic> toJson() => {
    'date': dateKey,
    'revenue': revenue,
    'tx_count': txCount,
    'item_count': itemCount,
  };

  factory DailySalesPoint.fromJson(Map<String, dynamic> json) {
    return DailySalesPoint(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      txCount: (json['tx_count'] as num?)?.toInt() ?? 0,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Agregat penjualan per jam (input target `hourly_traffic`).
class HourlySalesPoint {
  final DateTime date;
  final int hour;
  final double revenue;
  final int txCount;

  const HourlySalesPoint({
    required this.date,
    required this.hour,
    required this.revenue,
    this.txCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'date': forecastDateKey(date),
    'hour': hour,
    'revenue': revenue,
    'tx_count': txCount,
  };

  factory HourlySalesPoint.fromJson(Map<String, dynamic> json) {
    return HourlySalesPoint(
      date: DateTime.parse(json['date'] as String),
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      txCount: (json['tx_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Riwayat penjualan per produk (input target `product_demand`).
class ProductSalesPoint {
  final String? productId;
  final String productName;
  final String category;
  final double price;
  final int qty;

  /// Rata-rata kuantitas terjual per hari aktif (dipakai server & fallback).
  final double avgDailyQty;

  const ProductSalesPoint({
    this.productId,
    required this.productName,
    this.category = 'Lain-lain',
    this.price = 0,
    required this.qty,
    this.avgDailyQty = 0,
  });

  Map<String, dynamic> toJson() => {
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    'category': category,
    'price': price,
    'qty': qty,
    'avg_daily_qty': avgDailyQty,
  };

  factory ProductSalesPoint.fromJson(Map<String, dynamic> json) {
    return ProductSalesPoint(
      productId: json['product_id']?.toString(),
      productName: json['product_name']?.toString() ?? 'Produk',
      category: json['category']?.toString() ?? 'Lain-lain',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      avgDailyQty: (json['avg_daily_qty'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Statistik ringkas dari riwayat — dipakai untuk KPI pembanding dan sebagai
/// dasar estimasi lokal saat server model tidak tersedia.
class ForecastInputStats {
  /// Rata-rata omzet per **hari aktif** (hari yang benar-benar ada transaksi).
  final double avgDailyRevenue;

  /// Rata-rata jumlah transaksi per hari aktif.
  final double avgDailyTraffic;

  /// Kemiringan tren linear omzet harian (rupiah per hari).
  final double slope;

  /// Jumlah hari berbeda yang punya transaksi.
  final int activeDays;

  const ForecastInputStats({
    this.avgDailyRevenue = 0,
    this.avgDailyTraffic = 0,
    this.slope = 0,
    this.activeDays = 0,
  });

  bool get hasData => activeDays > 0 && avgDailyRevenue > 0;
}

/// Payload lengkap yang dikirim ke server model.
class ForecastInput {
  final StoreOperationalProfile profile;
  final List<DailySalesPoint> daily;
  final List<HourlySalesPoint> hourly;
  final List<ProductSalesPoint> products;

  const ForecastInput({
    required this.profile,
    this.daily = const [],
    this.hourly = const [],
    this.products = const [],
  });

  /// Jumlah hari berbeda yang memiliki transaksi.
  int get activeDays => daily.where((d) => d.revenue > 0).length;

  Map<String, double> get salesByDate {
    return {for (final d in daily) d.dateKey: d.revenue};
  }

  Map<String, int> get trafficByDate {
    return {for (final d in daily) d.dateKey: d.txCount};
  }

  /// Menghitung statistik ringkas dari seri harian.
  ForecastInputStats get stats {
    final active = daily.where((d) => d.revenue > 0).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    if (active.isEmpty) return const ForecastInputStats();

    final totalRevenue = active.fold<double>(0, (s, d) => s + d.revenue);
    final totalTx = active.fold<int>(0, (s, d) => s + d.txCount);
    final avgRevenue = totalRevenue / active.length;

    // Regresi linear sederhana pada omzet hari aktif (indeks sebagai x).
    double slope = 0;
    if (active.length > 1) {
      double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
      final n = active.length;
      for (int i = 0; i < n; i++) {
        final x = i.toDouble();
        final y = active[i].revenue;
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumXX += x * x;
      }
      final denominator = n * sumXX - sumX * sumX;
      if (denominator != 0) {
        slope = (n * sumXY - sumX * sumY) / denominator;
      }
    }

    // Batasi tren agar proyeksi tidak meledak/negatif berlebihan.
    if (avgRevenue > 0) {
      slope = slope.clamp(-avgRevenue * 0.05, avgRevenue * 0.05);
    }

    return ForecastInputStats(
      avgDailyRevenue: avgRevenue,
      avgDailyTraffic: totalTx / active.length,
      slope: slope,
      activeDays: active.length,
    );
  }

  Map<String, dynamic> toJson({int dailyHorizon = 30, int hourlyHorizon = 24}) {
    return {
      'store_profile': profile.toJson(),
      'history': {
        'daily': daily.map((e) => e.toJson()).toList(),
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'products': products.map((e) => e.toJson()).toList(),
      },
      'horizon': {'daily': dailyHorizon, 'hourly': hourlyHorizon},
      'targets': const [
        'revenue',
        'traffic',
        'hourly_traffic',
        'product_demand',
      ],
      'model': 'auto',
    };
  }

  /// Payload untuk endpoint v1 lama (`/api/predict/daily` dkk) yang hanya
  /// menerima daftar `{date, revenue}`.
  List<Map<String, dynamic>> toLegacyHistory() {
    final sorted = [...daily]..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return sorted
        .map((d) => {'date': d.dateKey, 'revenue': d.revenue})
        .toList();
  }
}
