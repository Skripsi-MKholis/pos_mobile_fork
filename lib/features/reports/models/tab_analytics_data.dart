/// Satu titik pada grafik Smart Analitik.
///
/// [hasActual] membedakan "benar-benar tidak ada transaksi" (nilai 0 yang
/// jujur) dari titik prediksi. Implementasi lama mengisi hari kosong dengan
/// hasil forecast lalu menggambarnya sebagai data riil — perilaku itu sudah
/// dihapus, dan flag ini yang menggantikannya agar tooltip bisa menjelaskan.
class ChartPoint {
  final double x;
  final double y;

  /// Untuk titik aktual: true bila hari/periode itu memang punya transaksi.
  /// Untuk titik prediksi: selalu false.
  final bool hasActual;

  /// Batas interval prediksi (hanya untuk titik forecast).
  final double? low;
  final double? high;

  const ChartPoint({
    required this.x,
    required this.y,
    this.hasActual = true,
    this.low,
    this.high,
  });

  /// Bentuk ringkas `[x, y, hasActual, low, high]` agar snapshot JSON tetap
  /// kecil (satu snapshot menyimpan empat tab sekaligus).
  List<dynamic> toCompactJson() => [x, y, hasActual ? 1 : 0, low, high];

  factory ChartPoint.fromCompactJson(List<dynamic> raw) {
    return ChartPoint(
      x: (raw[0] as num).toDouble(),
      y: (raw[1] as num).toDouble(),
      hasActual: raw.length > 2 ? (raw[2] as num) == 1 : true,
      low: raw.length > 3 ? (raw[3] as num?)?.toDouble() : null,
      high: raw.length > 4 ? (raw[4] as num?)?.toDouble() : null,
    );
  }
}

/// Data siap-tampil untuk satu tab forecast (daily/weekly/monthly/custom).
class TabAnalyticsData {
  final double totalRevenue;
  final String revenueText;
  final String revenueDiff;
  final String trafficText;
  final List<ChartPoint> actualPoints;
  final List<ChartPoint> forecastPoints;
  final List<String> xLabels;
  final double maxY;

  /// Catatan kecil di bawah grafik, mis. penjelasan periode berjalan atau
  /// horizon prediksi yang tidak penuh. Kosong bila tidak perlu.
  final String note;

  const TabAnalyticsData({
    required this.totalRevenue,
    required this.revenueText,
    required this.revenueDiff,
    required this.trafficText,
    required this.actualPoints,
    required this.forecastPoints,
    required this.xLabels,
    required this.maxY,
    this.note = '',
  });

  factory TabAnalyticsData.empty() => const TabAnalyticsData(
    totalRevenue: 0,
    revenueText: 'Rp 0',
    revenueDiff: 'Belum ada pembanding',
    trafficText: '0 Pelanggan',
    actualPoints: [],
    forecastPoints: [],
    xLabels: [],
    maxY: 1000000,
  );

  bool get hasInterval => forecastPoints.any((p) => p.low != null);

  Map<String, dynamic> toJson() => {
    'total_revenue': totalRevenue,
    'revenue_text': revenueText,
    'revenue_diff': revenueDiff,
    'traffic_text': trafficText,
    'actual_points': actualPoints.map((p) => p.toCompactJson()).toList(),
    'forecast_points': forecastPoints.map((p) => p.toCompactJson()).toList(),
    'x_labels': xLabels,
    'max_y': maxY,
    'note': note,
  };

  factory TabAnalyticsData.fromJson(Map<String, dynamic> json) {
    List<ChartPoint> parsePoints(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<List>().map(ChartPoint.fromCompactJson).toList();
    }

    // Kompatibilitas snapshot lama: kunci `actual_spots`/`forecast_spots`
    // berisi pasangan [x, y] tanpa flag/interval.
    List<ChartPoint> legacy(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<List>().map((p) {
        return ChartPoint(
          x: (p[0] as num).toDouble(),
          y: (p[1] as num).toDouble(),
        );
      }).toList();
    }

    return TabAnalyticsData(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      revenueText: json['revenue_text'] as String? ?? 'Rp 0',
      revenueDiff: json['revenue_diff'] as String? ?? '',
      trafficText: json['traffic_text'] as String? ?? '0 Pelanggan',
      actualPoints: json.containsKey('actual_points')
          ? parsePoints(json['actual_points'])
          : legacy(json['actual_spots']),
      forecastPoints: json.containsKey('forecast_points')
          ? parsePoints(json['forecast_points'])
          : legacy(json['forecast_spots']),
      xLabels:
          (json['x_labels'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      maxY: (json['max_y'] as num?)?.toDouble() ?? 1000000,
      note: json['note'] as String? ?? '',
    );
  }
}
