/// Mode/model yang benar-benar menghasilkan angka prediksi.
///
/// Nilai ini berasal dari `metadata.model_used` pada response server model
/// (lihat kontrak API v2 di `Dokumen/28 Juli - Improve Fitur LSTM.md` §5.2).
/// UI **wajib** memetakan mode ini ke label yang ditampilkan: hanya
/// [ForecastMode.lstm] dan [ForecastMode.lstmFinetuned] yang boleh disebut
/// "Prediksi LSTM". Mode lain harus diberi label apa adanya agar tidak
/// mengklaim sesuatu yang tidak dihasilkan oleh model.
enum ForecastMode {
  /// LSTM global yang sudah di-fine-tune dengan data toko ini.
  lstmFinetuned('lstm_finetuned'),

  /// LSTM global (dilatih lintas toko).
  lstm('lstm'),

  /// Baseline statistik: nilai hari yang sama pekan lalu (y[t-7]).
  seasonalNaive('seasonal_naive'),

  /// Baseline paling sederhana: nilai hari sebelumnya (y[t-1]).
  naive('naive'),

  /// Tidak ada server model sama sekali — angka dihitung di perangkat dari
  /// rata-rata & tren riwayat toko. Bukan hasil model apa pun.
  offlineLocal('offline_local');

  const ForecastMode(this.apiValue);

  /// Nilai string yang dipakai di API dan disimpan di database.
  final String apiValue;

  static ForecastMode fromApi(String? value) {
    switch (value) {
      case 'lstm_finetuned':
        return ForecastMode.lstmFinetuned;
      case 'lstm':
        return ForecastMode.lstm;
      case 'seasonal_naive':
        return ForecastMode.seasonalNaive;
      case 'naive':
        return ForecastMode.naive;
      case 'offline_local':
        return ForecastMode.offlineLocal;
      default:
        // Model tidak dikenal → jangan pernah diklaim sebagai LSTM.
        return ForecastMode.seasonalNaive;
    }
  }

  /// True hanya jika angka benar-benar keluar dari jaringan LSTM.
  bool get isLstm =>
      this == ForecastMode.lstm || this == ForecastMode.lstmFinetuned;

  /// True jika angka berasal dari server model (bukan hitungan di perangkat).
  bool get isFromServer => this != ForecastMode.offlineLocal;

  /// Label jujur untuk ditampilkan di UI.
  String get label {
    switch (this) {
      case ForecastMode.lstmFinetuned:
        return 'Prediksi LSTM (terlatih untuk toko Anda)';
      case ForecastMode.lstm:
        return 'Prediksi LSTM';
      case ForecastMode.seasonalNaive:
        return 'Estimasi statistik (pola mingguan)';
      case ForecastMode.naive:
        return 'Estimasi statistik sederhana';
      case ForecastMode.offlineLocal:
        return 'Estimasi lokal (tanpa server model)';
    }
  }

  /// Label pendek untuk badge/legend chart.
  String get shortLabel {
    switch (this) {
      case ForecastMode.lstmFinetuned:
      case ForecastMode.lstm:
        return 'LSTM';
      case ForecastMode.seasonalNaive:
      case ForecastMode.naive:
        return 'Statistik';
      case ForecastMode.offlineLocal:
        return 'Lokal';
    }
  }
}
