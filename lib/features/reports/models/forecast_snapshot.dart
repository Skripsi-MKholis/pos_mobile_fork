import 'package:pos_mobile/features/reports/models/forecast_input.dart';
import 'package:pos_mobile/features/reports/models/forecast_result.dart';

/// Isi kolom `smart_analytics_snapshots.forecast_payload`.
///
/// Menyimpan hasil model **beserta** seri historis yang dipakai sebagai input,
/// sehingga sebuah snapshot bisa digambar ulang sepenuhnya — termasuk untuk
/// rentang tab kustom yang belum dihitung saat snapshot dibuat. Kolom
/// `tab_data` lama tetap ditulis demi kompatibilitas snapshot terdahulu.
class ForecastSnapshotPayload {
  final ForecastResult forecast;
  final List<DailySalesPoint> inputDaily;
  final StoreOperationalProfile profile;

  const ForecastSnapshotPayload({
    required this.forecast,
    this.inputDaily = const [],
    this.profile = const StoreOperationalProfile(),
  });

  /// Membangun kembali [ForecastInput] untuk dipakai ulang oleh agregator.
  ForecastInput toInput() =>
      ForecastInput(profile: profile, daily: inputDaily);

  Map<String, dynamic> toJson() => {
    'forecast': forecast.toJson(),
    'input_daily': inputDaily.map((e) => e.toJson()).toList(),
    'profile': profile.toJson(),
  };

  static ForecastSnapshotPayload? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final forecastJson = json['forecast'];
    if (forecastJson is! Map) return null;

    return ForecastSnapshotPayload(
      forecast: ForecastResult.fromJson(
        Map<String, dynamic>.from(forecastJson),
      ),
      inputDaily: (json['input_daily'] as List? ?? [])
          .whereType<Map>()
          .map((e) => DailySalesPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      profile: json['profile'] is Map
          ? StoreOperationalProfile.fromJson(
              Map<String, dynamic>.from(json['profile'] as Map),
            )
          : const StoreOperationalProfile(),
    );
  }
}

/// Ringkasan satu entri riwayat analisis untuk layar daftar riwayat.
class SmartAnalyticsHistoryItem {
  final String id;
  final DateTime createdAt;
  final String revenueText;
  final double totalRevenue;
  final String? modelUsed;
  final String apiServerLabel;
  final bool apiOnline;
  final String bestSellingName;

  const SmartAnalyticsHistoryItem({
    required this.id,
    required this.createdAt,
    required this.revenueText,
    required this.totalRevenue,
    required this.modelUsed,
    required this.apiServerLabel,
    required this.apiOnline,
    required this.bestSellingName,
  });

  factory SmartAnalyticsHistoryItem.fromMap(Map<String, dynamic> map) {
    return SmartAnalyticsHistoryItem(
      id: map['id'].toString(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      revenueText: map['revenue_text'] as String? ?? 'Rp 0',
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0,
      modelUsed: map['model_used'] as String?,
      apiServerLabel: map['api_server_label'] as String? ?? 'HuggingFace Space',
      apiOnline: map['api_online'] as bool? ?? false,
      bestSellingName:
          map['best_selling_name'] as String? ?? 'Belum ada produk',
    );
  }
}
