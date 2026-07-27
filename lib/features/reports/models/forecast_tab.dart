/// Periode tampilan pada layar Smart Analitik.
enum ForecastTab {
  daily,
  weekly,
  monthly,
  custom;

  static ForecastTab fromName(String? name) {
    for (final t in ForecastTab.values) {
      if (t.name == name) return t;
    }
    return ForecastTab.daily;
  }

  String get label {
    switch (this) {
      case ForecastTab.daily:
        return 'Harian';
      case ForecastTab.weekly:
        return 'Mingguan';
      case ForecastTab.monthly:
        return 'Bulanan';
      case ForecastTab.custom:
        return 'Kustom';
    }
  }
}
