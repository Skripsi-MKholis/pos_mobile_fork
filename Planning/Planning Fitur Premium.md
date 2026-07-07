# Planning Fitur Premium — Parzello POS

> Dokumen perencanaan monetisasi freemium. Tujuan: aplikasi tetap sepenuhnya bisa dipakai untuk operasional dasar (POS, produk, transaksi) secara gratis, sementara fitur bernilai tambah tinggi dibatasi/di-unlock lewat langganan Premium.

---

## 1. Analisis Fitur Eksisting & Kandidat Pembatasan

Hasil pemetaan dari router (`lib/core/router/router.dart`), struktur `lib/features/`, dan `lib/core/`:

| Fitur | Lokasi | Nilai bagi user | Rekomendasi |
|---|---|---|---|
| Smart Analytics (prediksi LSTM) | `features/reports/.../smart_analytics_*.dart` | Sangat tinggi, ada biaya server (HF endpoint) | **Premium penuh** (atau kuota 1x/bulan gratis sebagai teaser) |
| Riwayat Smart Analytics (snapshot) | `/smart-analytics/history` | Tinggi | **Premium** (ikut induknya) |
| Laporan / Reports | `features/reports/reports_screen.dart` | Tinggi | **Freemium**: gratis rentang 7 hari terakhir; rentang custom/bulanan + export = Premium |
| Broadcast Notification | `dashboard/.../broadcast_notification_screen.dart` | Tinggi, ada biaya FCM | **Premium** (atau kuota 3 broadcast/bulan) |
| KDS (Kitchen Display) | `features/kds/` | Tinggi, segmen resto serius | **Premium** |
| Table Monitoring + Split Bill | `pos/.../table_monitoring_screen.dart`, `split_bill_screen.dart` | Tinggi | **Premium**; kelola meja dasar tetap gratis dengan limit (mis. 5 meja) |
| Kustomisasi Struk | `settings/.../receipt_customization_screen.dart` | Sedang (branding) | **Premium** (struk default gratis) |
| Manajemen Staff | `settings/.../staff_management_screen.dart` | Tinggi | **Freemium**: gratis maks. 2 staff, unlimited = Premium |
| Produk & Kategori | `features/product/` | Inti — jangan dikunci total | **Freemium**: gratis maks. 50 produk & 10 kategori |
| Multi-toko | `store_selection`, `create_store` | Tinggi | **Freemium**: gratis 1 toko, tambahan = Premium |
| Riwayat Stok | `product/.../stock_history_screen.dart` | Sedang | Gratis 30 hari terakhir; riwayat penuh = Premium |
| Bebas Iklan | `lib/core/ads/` (banner di dashboard, receipt, transaksi, reports, settings + interstitial) | — | **Benefit Premium utama**: semua iklan hilang |
| POS, Pembayaran, Struk, Riwayat Transaksi, Printer | `features/pos/` | Inti operasional | **Tetap gratis** (jangan dibatasi — ini alasan user memakai aplikasi) |
| Portal Customer (`/customer/*`) | `features/customer/` | Akuisisi | **Tetap gratis** (branding di halaman customer bisa jadi benefit Premium nanti) |
| Sync offline-first | `core/providers/sync_provider.dart` | Inti | **Tetap gratis** (membatasi sync merusak data user) |

Prinsip: **fitur transaksional inti gratis, fitur analitik/skala/branding berbayar, plus penghapusan iklan.**

## 2. Paket yang Diusulkan

| | Free | Premium |
|---|---|---|
| POS, transaksi, struk, printer | ✅ | ✅ |
| Iklan (AdMob) | Ada | ❌ Tanpa iklan |
| Produk / Kategori | 50 / 10 | Unlimited |
| Staff per toko | 2 | Unlimited |
| Toko | 1 | s/d 5 |
| Laporan | 7 hari terakhir | Semua rentang + export |
| Smart Analytics | 1 prediksi/bulan | Unlimited + riwayat snapshot |
| Broadcast notifikasi | ❌ | ✅ |
| KDS, Table Monitoring, Split Bill | ❌ | ✅ |
| Kustomisasi struk | ❌ | ✅ |

Harga (usulan awal, pasar UMKM Indonesia): Rp 49.000/bulan atau Rp 490.000/tahun. Lisensi melekat pada **toko** (bukan user), agar staff ikut menikmati dan owner multi-toko membayar per toko.

## 3. Arsitektur Teknis

### 3.1 Sumber kebenaran: Supabase

Tabel baru `store_subscriptions`:

```sql
create table store_subscriptions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references stores(id),
  plan text not null default 'free',            -- 'free' | 'premium'
  status text not null default 'inactive',       -- 'active' | 'expired' | 'grace' | 'inactive'
  started_at timestamptz,
  expires_at timestamptz,
  payment_provider text,                         -- 'midtrans' | 'play_billing' | 'manual'
  payment_ref text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- RLS: member toko boleh SELECT; INSERT/UPDATE hanya via service role (Edge Function)
```

Tabel pendukung kuota (untuk Smart Analytics gratis 1x/bulan & broadcast): `feature_usage(store_id, feature, period, count)` — atau hitung langsung dari tabel snapshot analitik yang sudah ada.

### 3.2 Sisi Flutter

Struktur baru `lib/features/premium/`:

- `models/subscription.dart` — model status langganan (+ cache Isar/SharedPreferences untuk offline).
- `providers/premium_provider.dart` — `@riverpod` `PremiumStatus`, ambil dari Supabase saat login/ganti toko, cache lokal, dengarkan realtime update.
- `providers/feature_gate.dart` — API terpusat, satu-satunya tempat aturan gating:
  ```dart
  enum PremiumFeature { smartAnalytics, broadcast, kds, tableMonitoring,
    splitBill, receiptCustomization, fullReports, adFree }

  bool canUse(PremiumFeature f);
  int limitFor(LimitedResource r); // products, categories, staff, stores, tables
  ```
- `presentation/paywall_screen.dart` — halaman upgrade (benefit, harga, tombol beli).
- `presentation/widgets/premium_badge.dart`, `premium_gate.dart` — wrapper widget: kalau bukan premium tampilkan lock + CTA ke paywall (bukan menyembunyikan menu — menu tetap terlihat dengan badge "Premium" agar jadi sarana promosi).

### 3.3 Titik penerapan gating

1. **Router** (`router.dart`): tambah guard setelah RBAC — route premium (`/smart-analytics`, `/kds`, `/table-monitoring`, `/split-bill`, `/broadcast-notification`, `/receipt-customization`) redirect ke `/paywall` bila non-premium. Guard membaca provider yang sama dengan `feature_gate`.
2. **Limit resource**: cek di aksi create — `product_form_screen`/provider produk (hitung produk sebelum simpan), `staff_management_screen` (hitung staff), `create_store_screen` (hitung toko), `manage_tables_screen` (hitung meja). Tampilkan dialog "Batas tercapai — upgrade ke Premium".
3. **Reports**: batasi date-picker di `reports_screen.dart` ke 7 hari untuk free; tombol export dibungkus `PremiumGate`.
4. **Iklan**: di `banner_ad_widget.dart` dan `interstitial_ad_manager.dart`, cek `premiumProvider` — return `SizedBox.shrink()` / skip load bila premium. (Ini satu titik perubahan, otomatis berlaku di 5 layar yang memakai ads.)
5. **Validasi server**: fitur berbiaya server (Smart Analytics, broadcast) juga divalidasi di sisi server (Edge Function / RLS policy cek `store_subscriptions`), karena gating client-side bisa di-bypass.

### 3.4 Pembayaran

Pilihan (keputusan terpisah, tidak memblokir fase 1–2):

- **Google Play Billing** (`in_app_purchase`): wajib bila distribusi via Play Store untuk unlock fitur digital; potongan 15%.
- **Midtrans/Xendit via Supabase Edge Function + webhook**: cocok bila distribusi APK langsung (saat ini build APK release manual); QRIS/VA familiar untuk UMKM.
- **Aktivasi manual** (admin set row di `store_subscriptions`): cukup untuk tahap skripsi/demo — **direkomendasikan sebagai fase awal**.

## 4. Tahapan Implementasi

### Fase 1 — Fondasi (backend + state)
1. Migrasi Supabase: tabel `store_subscriptions` + RLS.
2. `lib/features/premium/`: model, `premium_provider`, `feature_gate` + build_runner.
3. Cache status lokal agar gating tetap benar saat offline (dengan `expires_at` + toleransi grace 3 hari offline).
4. Unit test `feature_gate` (free vs premium vs expired).

### Fase 2 — Penerapan gating
1. Guard router untuk route premium + `paywall_screen` (statis dulu, tombol "hubungi admin"/dummy).
2. `PremiumGate` widget + badge di menu (dashboard/settings) untuk fitur terkunci.
3. Limit produk/kategori/staff/toko/meja di titik create.
4. Pembatasan rentang laporan + export.
5. Matikan iklan untuk premium (banner + interstitial).
6. Kuota Smart Analytics free 1x/bulan (cek jumlah snapshot bulan berjalan).

### Fase 3 — Pembayaran & server-side enforcement
1. Integrasi payment (mulai dari aktivasi manual → Midtrans/Play Billing).
2. Edge Function webhook: update `store_subscriptions` saat pembayaran sukses/expired.
3. Validasi premium di endpoint Smart Analytics & broadcast.
4. Notifikasi FCM pengingat menjelang expired + status `grace`.

### Fase 4 — Polish
1. Analytics event (paywall_viewed, upgrade_clicked, purchase_success) via `analytics_service.dart`.
2. Localization string paywall di `lib/l10n/` (ARB) + `flutter gen-l10n`.
3. Layar status langganan di Settings (masa aktif, perpanjang).
4. A/B harga & teks paywall (opsional).

## 5. Risiko & Catatan

- **Jangan mengunci data**: saat premium expired, data (produk > 50, staff > 2) tetap terbaca & terpakai; yang diblokir hanya **penambahan baru** dan fitur premium. Ini penting agar downgrade tidak merusak operasional.
- **Grandfathering**: user eksisting sebaiknya diberi masa premium gratis (mis. 30 hari) saat fitur ini rilis.
- **Bypass client**: semua limit di client hanyalah UX; enforcement nyata untuk fitur berbiaya harus di server (RLS/Edge Function).
- **Offline**: status premium di-cache; jika `expires_at` lewat saat offline > grace period, fallback ke free.
- **RBAC vs Premium**: dua lapis berbeda — RBAC = siapa boleh (role), Premium = toko boleh apa (plan). Guard router harus mengecek keduanya.

## 6. Definition of Done

- [ ] Semua fitur di tabel §2 ter-gate sesuai paket, diverifikasi manual di device.
- [ ] Toko free tidak melihat error, hanya paywall/dialog upgrade yang jelas.
- [ ] Toggle premium via row Supabase langsung mengubah perilaku app (realtime/refresh).
- [ ] Iklan hilang total pada toko premium.
- [ ] `flutter analyze` & `flutter test` hijau.
