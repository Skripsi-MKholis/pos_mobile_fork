/// Pembagian aman untuk seluruh perhitungan forecast.
///
/// Mengembalikan `null` alih-alih `NaN`/`Infinity` saat pembagi nol atau
/// operand tidak berhingga (perbaikan T-11: KPI sempat bisa menampilkan
/// `NaN%` ketika toko belum punya omzet).
double? safeDiv(double a, double b) {
  if (b == 0 || !b.isFinite || !a.isFinite) return null;
  final result = a / b;
  return result.isFinite ? result : null;
}
