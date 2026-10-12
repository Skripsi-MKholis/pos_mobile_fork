# Panduan Feature Gate & Subscription Plan Keys

Dokumen ini berisi daftar lengkap **Feature Keys** yang digunakan untuk mengatur sistem **Lock/Unlock (Feature Gate)** otomatis di aplikasi POS Mobile berdasarkan paket langganan aktif toko di Supabase.

Fitur-fitur ini telah diselaraskan dengan **fitur nyata yang benar-benar ada dan aktif di dalam aplikasi POS Mobile**:
1. **Smart AI Analytics** (`smart_analytics`) - Prediksi penjualan LSTM & Akurasi Model.
2. **Laporan Analisis Advance** (`advanced_reports`) - Grafik tren penjualan & ekspor data laporan.
3. **Manajemen Karyawan / Staf** (`staff_management`) - Penambahan akun staf, kasir, dan manajer.
4. **Katalog Mandiri Pelanggan** (`customer_catalog`) - Layar pemesanan & katalog mandiri QR pelanggan.

*(Fitur yang belum tersedia seperti KDS, meja dine-in, dan voucher otomatis telah dibersihkan agar tidak membingungkan pengguna).*

---

## 1. Daftar Feature Keys (`AppFeature`)

Setiap fitur dikendalikan oleh boolean flag yang tersimpan pada kolom `subscription_plans.features` (`JSONB`) di Supabase:

| Feature Key | Enum Dart (`AppFeature`) | Nama Fitur | Keterangan |
| :--- | :--- | :--- | :--- |
| `smart_analytics` | `AppFeature.smartAnalytics` | Smart AI Analytics | Prediksi penjualan masa depan menggunakan LSTM Machine Learning dan evaluasi akurasi |
| `advanced_reports` | `AppFeature.advancedReports` | Laporan Analisis Advance | Grafik tren performa penjualan dan ekspor rekapan data |
| `staff_management` | `AppFeature.staffManagement` | Manajemen Staf & Karyawan | Tambah staf toko, hak akses peran (Kasir/Manajer), dan pantau kinerja tim |
| `customer_catalog` | `AppFeature.customerCatalog` | Katalog Mandiri Pelanggan | Akses layar pemesanan/katalog belanja digital mandiri pelanggan via QR |

---

## 2. Matriks Hak Akses Per Paket di Supabase

Berikut adalah status default tiap paket yang saat ini tersimpan di tabel `subscription_plans`:

| Feature Key | Lite (UMKM Pemula)<br>`Rp 0 / Lifetime` | UMKM Hebat<br>`Rp 49.000 / Bulan` | Bisnis Skalabel<br>`Rp 149.000 / Bulan` |
| :--- | :---: | :---: | :---: |
| `smart_analytics` | ❌ **Locked** | ✅ **Unlocked** | ✅ **Unlocked** |
| `advanced_reports` | ❌ **Locked** | ✅ **Unlocked** | ✅ **Unlocked** |
| `staff_management` | ❌ **Locked** | ✅ **Unlocked** | ✅ **Unlocked** |
| `customer_catalog` | ✅ **Unlocked** | ✅ **Unlocked** | ✅ **Unlocked** |
| **Maksimal Cabang/Outlet** | `1 Outlet` | `2 Outlet` | `5 Outlet` |
| **Maksimal Transaksi** | `500 Transaksi/Bulan` | `Unlimited` | `Unlimited` |

---

## 3. Poin Keuntungan yang Tertera di Layar Pilihan Paket (`plan_features`)

Semua poin teks keuntungan yang tampil di kartu paket langganan tersimpan di tabel `plan_features` Supabase:

### A. Paket **Lite (UMKM Pemula)**
- Hingga 500 transaksi per bulan
- 1 Akun kasir & 1 outlet toko
- Pencatatan kasir & cetak struk Bluetooth
- Laporan ringkasan penjualan harian
- Katalog belanja mandiri pelanggan (QR)

### B. Paket **UMKM Hebat**
- Transaksi Tanpa Batas (Unlimited)
- Dukungan hingga 2 cabang/outlet
- Smart Analytics & AI Prediksi Penjualan (LSTM)
- Laporan analitik advance & grafik tren
- Manajemen staf & karyawan toko
- Kustomisasi logo & struk kasir
- Katalog belanja mandiri pelanggan (QR)

### C. Paket **Bisnis Skalabel**
- Transaksi Tanpa Batas (Unlimited)
- Dukungan hingga 5 cabang/outlet
- Semua fitur UMKM Hebat
- Smart Analytics & AI Prediksi Penjualan (LSTM)
- Manajemen multi-cabang & hak akses staff
- Audit log aktivitas kasir & riwayat stok
- Sinkronisasi real-time multi-perangkat
- Prioritas dukungan teknis WhatsApp 24/7

---

## 4. Cara Penggunaan di Kode Flutter

Semua helper fungsi dan guard terpusat di file:
👉 [lib/core/guards/feature_guard.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/core/guards/feature_guard.dart)

### A. Pengecekan Izin Menggunakan Provider
```dart
final canAccess = ref.watch(canAccessFeatureProvider(AppFeature.smartAnalytics));

if (!canAccess) {
  // Fitur terkunci
}
```

### B. Membuka Dialog Upgrade Otomatis
Jika pengguna menekan tombol atau aksi yang belum dibuka:
```dart
if (!ref.read(canAccessFeatureProvider(AppFeature.staffManagement))) {
  showFeatureLockedDialog(context, AppFeature.staffManagement);
  return;
}
```

### C. Mengunci Item Menu di App Drawer
Cukup tambahkan properti `requiredFeature`:
```dart
_DrawerItem(
  icon: TablerIcons.brain,
  title: l10n.smartAnalytics,
  route: '/smart-analytics',
  requiredFeature: AppFeature.smartAnalytics, // Otomatis tampil badge PRO & modal upgrade jika terkunci
),
```

### D. Mengunci Widget / Section Halaman (`FeatureGate`)
```dart
FeatureGate(
  feature: AppFeature.smartAnalytics,
  child: MySmartAnalyticsContentWidget(),
)
```

---

## 5. Mengubah Hak Akses Fitur Langsung dari Supabase
Anda dapat mengaktifkan atau menonaktifkan fitur secara instan untuk suatu paket tanpa mengubah kode aplikasi:

```sql
-- Contoh: Mengaktifkan Staff Management untuk paket tertentu
UPDATE subscription_plans
SET features = jsonb_set(features, '{staff_management}', 'true', true)
WHERE slug = 'lite';
```
Aplikasi akan langsung merefleksikan perubahan hak akses secara dinamis.
