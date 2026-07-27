import 'package:intl/intl.dart';

final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');

/// Kunci tanggal standar (`yyyy-MM-dd`) yang dipakai di seluruh fitur forecast.
String forecastDateKey(DateTime date) => _dateKeyFormat.format(date);

/// Satu titik prediksi omzet harian.
class ForecastPoint {
  final DateTime date;
  final double revenue;

  /// Batas bawah/atas interval prediksi (kuantil 10/90 residual backtest).
  /// Null jika server tidak mengirimkannya.
  final double? revenueLow;
  final double? revenueHigh;

  final int? txCount;
  final double? confidence;

  const ForecastPoint({
    required this.date,
    required this.revenue,
    this.revenueLow,
    this.revenueHigh,
    this.txCount,
    this.confidence,
  });

  String get dateKey => forecastDateKey(date);

  bool get hasInterval => revenueLow != null && revenueHigh != null;

  Map<String, dynamic> toJson() => {
    'date': dateKey,
    'revenue': revenue,
    if (revenueLow != null) 'revenue_low': revenueLow,
    if (revenueHigh != null) 'revenue_high': revenueHigh,
    if (txCount != null) 'tx_count': txCount,
    if (confidence != null) 'confidence': confidence,
  };

  factory ForecastPoint.fromJson(Map<String, dynamic> json) {
    return ForecastPoint(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      revenueLow: (json['revenue_low'] as num?)?.toDouble(),
      revenueHigh: (json['revenue_high'] as num?)?.toDouble(),
      txCount: (json['tx_count'] as num?)?.toInt(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

/// Prediksi distribusi transaksi per jam (untuk perencanaan shift).
class HourlyTraffic {
  final int hour; // 0-23, waktu lokal toko
  final int txCount;
  final double share; // porsi terhadap total transaksi harian (0..1)
  final double? confidence;

  const HourlyTraffic({
    required this.hour,
    required this.txCount,
    required this.share,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'tx_count': txCount,
    'share': share,
    if (confidence != null) 'confidence': confidence,
  };

  factory HourlyTraffic.fromJson(Map<String, dynamic> json) {
    return HourlyTraffic(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      txCount: (json['tx_count'] as num?)?.toInt() ?? 0,
      share: (json['share'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

/// Arah tren permintaan sebuah produk.
enum DemandTrend {
  up,
  flat,
  down;

  static DemandTrend fromApi(String? value) {
    switch (value) {
      case 'up':
        return DemandTrend.up;
      case 'down':
        return DemandTrend.down;
      default:
        return DemandTrend.flat;
    }
  }

  String get apiValue => name;

  String get label {
    switch (this) {
      case DemandTrend.up:
        return 'Naik';
      case DemandTrend.down:
        return 'Melambat';
      case DemandTrend.flat:
        return 'Stabil';
    }
  }
}

/// Prediksi permintaan satu produk beserta turunannya untuk manajemen stok.
class ProductDemand {
  final String? productId;
  final String productName;
  final String category;

  /// Perkiraan kuantitas terjual untuk horizon harian (default: 1 hari).
  final int predictedQty;

  /// Perkiraan kuantitas terjual 7 hari ke depan.
  final int predictedQtyWeek;

  /// Sisa hari sebelum stok habis pada laju prediksi ini.
  /// Null jika stok tak terbatas atau permintaan diprediksi nol.
  final double? daysOfStockLeft;

  /// Saran jumlah pembelian agar stok cukup untuk horizon mingguan.
  final int recommendedQty;

  final double? confidence;
  final DemandTrend trend;

  const ProductDemand({
    this.productId,
    required this.productName,
    this.category = 'Lain-lain',
    required this.predictedQty,
    this.predictedQtyWeek = 0,
    this.daysOfStockLeft,
    this.recommendedQty = 0,
    this.confidence,
    this.trend = DemandTrend.flat,
  });

  ProductDemand copyWith({
    double? daysOfStockLeft,
    int? recommendedQty,
    DemandTrend? trend,
  }) {
    return ProductDemand(
      productId: productId,
      productName: productName,
      category: category,
      predictedQty: predictedQty,
      predictedQtyWeek: predictedQtyWeek,
      daysOfStockLeft: daysOfStockLeft ?? this.daysOfStockLeft,
      recommendedQty: recommendedQty ?? this.recommendedQty,
      confidence: confidence,
      trend: trend ?? this.trend,
    );
  }

  Map<String, dynamic> toJson() => {
    if (productId != null) 'product_id': productId,
    'product_name': productName,
    'category': category,
    'predicted_qty': predictedQty,
    'predicted_qty_week': predictedQtyWeek,
    if (daysOfStockLeft != null) 'days_of_stock_left': daysOfStockLeft,
    'recommended_qty': recommendedQty,
    if (confidence != null) 'confidence': confidence,
    'trend': trend.apiValue,
  };

  factory ProductDemand.fromJson(Map<String, dynamic> json) {
    // `quantity` dan `name` adalah bentuk snapshot lama
    // (`projected_best_sellers`) — tetap dibaca agar riwayat terdahulu
    // tidak kosong setelah refactor.
    final qty =
        (json['predicted_qty'] as num?)?.toInt() ??
        (json['quantity'] as num?)?.toInt() ??
        0;
    return ProductDemand(
      productId: json['product_id']?.toString(),
      productName:
          json['product_name']?.toString() ??
          json['name']?.toString() ??
          'Produk',
      category: json['category']?.toString() ?? 'Lain-lain',
      predictedQty: qty,
      predictedQtyWeek: (json['predicted_qty_week'] as num?)?.toInt() ?? qty * 7,
      daysOfStockLeft: (json['days_of_stock_left'] as num?)?.toDouble(),
      recommendedQty:
          (json['recommended_qty'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      confidence: (json['confidence'] as num?)?.toDouble(),
      trend: DemandTrend.fromApi(json['trend'] as String?),
    );
  }
}

/// Rekomendasi tindakan dari model. Disimpan JSON-safe (tanpa `Color`/
/// `IconData`) — pemetaan gaya visual dilakukan di lapisan presentasi.
class ForecastRecommendation {
  /// 'target_omzet' | 'restock' | 'happy_hour' | ...
  final String kind;
  final String title;
  final String desc;
  final String badge;
  final String rationale;
  final Map<String, dynamic> payload;

  const ForecastRecommendation({
    required this.kind,
    required this.title,
    required this.desc,
    this.badge = 'REKOMENDASI',
    this.rationale = '',
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'title': title,
    'desc': desc,
    'badge': badge,
    'rationale': rationale,
    'payload': payload,
  };

  factory ForecastRecommendation.fromJson(Map<String, dynamic> json) {
    return ForecastRecommendation(
      kind: json['kind']?.toString() ?? 'target_omzet',
      title: json['title']?.toString() ?? 'Rekomendasi',
      desc: json['desc']?.toString() ?? '',
      badge: json['badge']?.toString() ?? 'REKOMENDASI',
      rationale: json['rationale']?.toString() ?? '',
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
    );
  }
}
