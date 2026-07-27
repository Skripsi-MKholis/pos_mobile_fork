# Skema Database Supabase — Yang Dipakai Parzello POS

Dokumen ini adalah versi **terfilter** dari skema penuh database Supabase project *"Point of Sale Skripsi"* (`nolawradcdkemdyumoqs`), hanya mencakup tabel yang **benar-benar direferensikan oleh kode Dart** di `lib/` aplikasi ini (dicek via pencarian pemanggilan `.from('...')` dan `.rpc('...')` pada `Supabase.instance.client`).

Untuk skema lengkap seluruh 24 tabel di project (termasuk yang tidak dipakai aplikasi ini), lihat [Supabase Database Scheme.md](../Supabase%20Database%20Scheme.md).

---

## 1. Ringkasan: Tabel Terpakai vs Tidak Terpakai

### ✅ Dipakai aplikasi (15 tabel)
| Tabel | Contoh lokasi pemakaian di kode |
| :--- | :--- |
| `stores` | `lib/features/auth/providers/store_provider.dart`, `customer_session_provider.dart` |
| `users` | `lib/features/auth/providers/store_provider.dart`, `auth_provider.dart` |
| `profiles` | `lib/features/auth/providers/auth_provider.dart`, `profile_screen.dart` |
| `store_members` | `lib/features/auth/providers/store_provider.dart`, `staff_management_screen.dart` |
| `products` | `lib/features/product/providers/product_provider.dart`, `customer_catalog_provider.dart`, `sync_provider.dart` |
| `categories` | `lib/features/product/providers/category_provider.dart`, `sync_provider.dart` |
| `stock_history` | `lib/features/product/providers/stock_history_provider.dart`, `sync_provider.dart` |
| `transactions` | `lib/features/pos/providers/table_monitoring_provider.dart`, `transaction_history_provider.dart`, `sync_provider.dart` |
| `transaction_items` | `lib/features/pos/providers/table_monitoring_provider.dart`, `customer_checkout_page.dart` |
| `tables` | `lib/features/pos/providers/table_provider.dart`, `table_monitoring_provider.dart` |
| `vouchers` | `lib/features/pos/providers/voucher_provider.dart` |
| `customers` | `lib/features/customer/providers/customer_session_provider.dart`, `customer_checkout_page.dart` |
| `notifications` | `lib/features/dashboard/providers/notification_repository.dart` |
| `user_fcm_tokens` | `lib/core/services/fcm_service.dart` |
| `smart_analytics_snapshots` | `lib/features/reports/data/smart_analytics_repository.dart` (`snapshotsTable`) |
| `ai_forecast_points` | `lib/features/reports/data/smart_analytics_repository.dart` (`forecastPointsTable`) — evaluasi akurasi prediksi |

### ❌ Tidak dipakai aplikasi ini (9 tabel — diabaikan dari dokumen ini)
`product_categories`, `discounts`, `reservations`, `subscription_plans`, `subscriptions`, `subscription_history`, `app_configs`, `classifications`, `download_waitlist`.

> Catatan: `tables` (meja dine-in) dan `smart_analytics_snapshots` sempat terlihat tidak terpakai pada pemeriksaan awal, namun setelah verifikasi ulang keduanya **aktif direferensikan** di kode (masing-masing untuk fitur meja/dine-in POS dan riwayat Smart Analytics). `reservations` (reservasi meja) dan tabel-tabel `subscription_*` (sistem langganan) terbukti **tidak** direferensikan sama sekali di `lib/` — kemungkinan fitur backend yang belum/tidak diimplementasikan di sisi client Flutter ini, atau dipakai oleh aplikasi lain (mis. landing page/dashboard admin terpisah) yang berbagi project Supabase yang sama.

### Fungsi RPC (PostgreSQL functions) yang dipanggil
| Fungsi RPC | Lokasi pemanggilan | Kegunaan |
| :--- | :--- | :--- |
| `create_transaction_v4` | `lib/core/providers/sync_provider.dart` | Jalur utama: mengirim transaksi offline (Isar) ke server saat sinkronisasi, menjaga konsistensi stok |
| `create_transaction_v3` | `lib/features/pos/providers/table_monitoring_provider.dart` | Membuat transaksi langsung (jalur non-sync, terkait alur dine-in/table monitoring) — versi lebih lama dari v4 |
| `sync_pending_transaction` | `lib/features/pos/providers/table_monitoring_provider.dart` | Sinkronisasi transaksi pending terkait meja |
| `get_sales_performance` | `lib/features/reports/providers/sales_performance_provider.dart` | Data agregat untuk layar Performa Penjualan (`/sales-performance`) |
| `get_analytics` | `lib/features/reports/providers/analytics_provider.dart`, `today_revenue_provider.dart` | Data agregat untuk laporan (`/reports`) dan realisasi omzet hari ini |
| `get_forecast_input` | `lib/features/reports/data/smart_analytics_repository.dart` | Agregat harian/per jam/per produk sebagai input model prediksi (menggantikan penarikan transaksi mentah) |
| `evaluate_forecast_points` | `lib/features/reports/data/smart_analytics_repository.dart` | Mengisi realisasi pada `ai_forecast_points` untuk tanggal yang sudah lewat |

> `get_forecast_input` dan `evaluate_forecast_points` didefinisikan di `supabase/migrations/20260728_lstm_forecast.sql`. Klien memperlakukan keduanya sebagai **opsional**: bila migrasi belum dijalankan, input model diambil lewat query langsung dan evaluasi akurasi dilewati.

---

## 2. Detail Skema Tabel Terpakai

### 2.1 `stores`
Data toko/outlet, mendukung multi-store per owner.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `name` | text | ❌ | | Nama toko |
| `address` | text | ✅ | | |
| `phone` | text | ✅ | | |
| `email` | text | ✅ | | |
| `business_type` | text | ✅ | | Kategori bisnis (Retail/F&B) |
| `country` | text | ✅ | `'Indonesia'` | |
| `province` | text | ✅ | | |
| `city` | text | ✅ | | |
| `is_public` | boolean | ✅ | `false` | Toko terlihat di direktori publik pelanggan (`customer` app) |
| `invite_code` | text | ✅ | | Kode undangan staf |
| `owner_id` | uuid | ✅ | `auth.uid()` | FK → `users.id` / `auth.users.id` |
| `logo_url` | text | ✅ | | |
| `settings` | jsonb | ✅ | lihat di bawah | Konfigurasi fitur & finansial toko |
| `created_at` | timestamptz | ✅ | `now()` | |

**Struktur default `settings` (JSONB):**
```json
{
  "features": {
    "kds": true,
    "tables": true,
    "customers": true,
    "promotions": true,
    "reservations": true
  },
  "financial": {
    "tax_rate": 10,
    "tax_enabled": false,
    "service_charge_rate": 5,
    "service_charge_enabled": false
  },
  "operational": {
    "auto_print": false,
    "business_model": "custom",
    "low_stock_threshold": 5
  }
}
```
> `features.kds` masih ada di struktur JSON meski fitur KDS sudah dihapus dari kode Flutter (PRD.md §7.2) — flag ini tidak lagi bermakna fungsional di app ini. `features.reservations` juga tidak punya padanan di client karena tabel `reservations` tidak dipakai.

---

### 2.2 `users`
Profil pengguna aplikasi, dipakai untuk resolusi role & data staf.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id`; toko aktif pengguna |
| `full_name` | text | ❌ | | |
| `email` | text (unique) | ❌ | | |
| `role` | text | ✅ | | **Check**: `IN ('Owner', 'Karyawan', 'Pelanggan')` |
| `is_admin` | boolean | ✅ | `false` | Setara `app_metadata.role == 'admin'` di client — dipakai router.dart sebagai jalur bypass RBAC |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.3 `profiles`
Profil ringkas terhubung langsung ke `auth.users`, dipakai terpisah dari `users` (mis. untuk avatar/nama tampilan cepat).

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK, FK → `auth.users.id`) | ❌ | |
| `email` | text | ✅ | |
| `full_name` | text | ✅ | |
| `avatar_url` | text | ✅ | |
| `created_at` | timestamptz | ❌ | `timezone('utc', now())` |

---

### 2.4 `store_members`
Keanggotaan staf per toko beserta peran — dipakai `staff_management_screen.dart` untuk kelola kasir.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `user_id` | uuid | ❌ | | FK → `users.id` |
| `store_id` | uuid | ❌ | | FK → `stores.id` |
| `role` | text | ❌ | | **Check**: `IN ('Owner', 'Karyawan', 'Pelanggan')` |
| `status` | text | ✅ | `'active'` | **Check**: `IN ('active', 'pending')` — status undangan |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.5 `products`
Katalog produk — inti dari fitur POS, Manajemen Produk, dan katalog pelanggan (`customer_catalog_provider.dart`). Juga sasaran sinkronisasi offline-first Isar (`sync_provider.dart`).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `name` | text | ❌ | | |
| `price` | numeric | ❌ | | Harga jual |
| `modal_price` | numeric | ✅ | | Harga modal (legacy) |
| `cost_price` | numeric | ✅ | `0` | Harga pokok saat ini |
| `image_url` | text | ✅ | | |
| `category` | text | ✅ | `'Umum'` | Nama kategori (legacy, string bebas) |
| `category_id` | uuid | ✅ | | FK → `categories.id` |
| `stock_quantity` | integer | ✅ | `0` | |
| `is_infinite_stock` | boolean | ✅ | `false` | Mendukung penjualan meski stok 0 |
| `min_stock_level` | integer | ✅ | `0` | Ambang batas notifikasi stok menipis |
| `barcode` | text | ✅ | | Dipindai via `mobile_scanner` |
| `sku` | text | ✅ | | |
| `variants` | jsonb | ✅ | `[]` | |
| `discount_id` | uuid | ✅ | | FK → `discounts.id` — kolom ada, tapi tabel `discounts` tidak dipakai app |
| `discount_applied` | jsonb | ✅ | | |
| `preparation_area` | text | ✅ | `'Kitchen'` | **Check**: `IN ('Kitchen', 'Bar')` — sisa skema KDS, tidak dipakai lagi oleh UI |
| `description` | text | ✅ | | |
| `created_at` / `updated_at` | timestamptz | ✅ | `now()` | |

---

### 2.6 `categories`
Kategori produk terstruktur, dipakai `category_provider.dart` dan disinkronkan via `sync_provider.dart`.

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `name` | text | ❌ | |
| `store_id` | uuid | ❌ | FK → `stores.id` |
| `created_at` | timestamptz | ❌ | `timezone('utc', now())` |

---

### 2.7 `stock_history`
Log mutasi stok — sesuai `StockHistoryLocal` (Isar) yang disinkronkan ke tabel ini.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ❌ | | FK → `stores.id` |
| `product_id` | uuid | ✅ | | FK → `products.id` |
| `product_name` | text | ❌ | | |
| `change_type` | text | ❌ | | **Check**: `IN ('sale', 'manual_addition', 'manual_reduction', 'manual_adjustment')` |
| `quantity_change` | integer | ❌ | | |
| `old_stock` / `new_stock` | integer | ❌ | | |
| `reference_id` | uuid | ✅ | | Mis. ID transaksi terkait |
| `cashier_id` | uuid | ✅ | | FK → `users.id` |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.8 `transactions`
Transaksi penjualan — tabel dengan volume terbesar di database (56.493 baris), pusat dari alur POS/checkout, riwayat transaksi, dan sinkronisasi offline.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `local_id` | text | ✅ | | ID lokal Isar sebelum sync (idempotensi) |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `cashier_id` | uuid | ✅ | | FK → `users.id` |
| `table_id` | uuid | ✅ | | FK → `tables.id` (dine-in) |
| `customer_id` | uuid | ✅ | | FK → `customers.id` |
| `total_amount` | numeric | ❌ | | |
| `payment_method` | text | ✅ | | **Check**: `IN ('Tunai', 'QRIS', 'Transfer', 'Pending')` — **tidak ada "Debit"**, berbeda dengan yang disebut PRD.md §5.2 |
| `cash_paid` | numeric | ✅ | | |
| `change_amount` | numeric | ✅ | | |
| `status` | text | ✅ | `'Berhasil'` | **Check**: `IN ('Berhasil', 'Pending', 'Dibatalkan')` |
| `discount_total` | numeric | ✅ | `0` | |
| `voucher_info` | jsonb | ✅ | `{}` | Snapshot voucher yang dipakai |
| `notes` | text | ✅ | | |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.9 `transaction_items`
Item detail per transaksi.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `transaction_id` | uuid | ✅ | | FK → `transactions.id` |
| `product_id` | uuid | ✅ | | FK → `products.id` |
| `product_name` | text | ❌ | | Snapshot nama saat transaksi |
| `product_sku` | text | ✅ | | |
| `unit_price` | numeric | ❌ | | |
| `quantity` | integer | ❌ | | |
| `subtotal` | numeric | ❌ | | |
| `cost_price` | numeric | ✅ | `0` | Snapshot harga modal (laporan laba) |
| `selected_variants` | jsonb | ✅ | | |
| `discount_applied` | jsonb | ✅ | | |
| `notes` | text | ✅ | | |
| `status` | text | ✅ | `'Pending'` | **Check**: `IN ('Pending', 'Cooking', 'Ready', 'Served')` — sisa alur KDS per-item, tidak dipakai UI aktif |

---

### 2.10 `tables`
Meja dine-in — dipakai `table_provider.dart` dan `table_monitoring_provider.dart` untuk alur POS dine-in, meski PRD.md mencatat belum ada layar/rute UI khusus (`/manage-tables`) yang terdaftar di router.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `extensions.uuid_generate_v4()` | |
| `store_id` | uuid | ❌ | | FK → `stores.id` |
| `name` | text | ❌ | | |
| `capacity` | integer | ✅ | `2` | |
| `status` | text | ✅ | `'available'` | **Check**: `IN ('available', 'occupied', 'cleaning', 'reserved')` |
| `merged_to` | uuid | ✅ | | Self-FK, gabung meja — tidak terlihat dipakai eksplisit di provider yang ditemukan |
| `created_at` / `updated_at` | timestamptz | ✅ | `now()` | |

---

### 2.11 `vouchers`
Voucher diskon kode untuk transaksi POS, dipakai `voucher_provider.dart` dan model `Voucher` (`lib/core/models/voucher.dart`).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `code` | text | ❌ | | |
| `description` | text | ✅ | | |
| `type` | text | ❌ | | **Check**: `IN ('percentage', 'fixed')` |
| `value` | numeric | ❌ | | |
| `min_purchase` | numeric | ✅ | `0` | |
| `max_discount` | numeric | ✅ | | |
| `usage_limit` | integer | ✅ | | |
| `used_count` | integer | ✅ | `0` | |
| `starts_at` / `expires_at` | timestamptz | ✅ | `now()` / — | |
| `is_active` | boolean | ✅ | `true` | |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.12 `customers`
Data pelanggan terdaftar, dipakai fitur self-order (`customer_session_provider.dart`, `customer_checkout_page.dart`).

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `store_id` | uuid | ✅ | FK → `stores.id` |
| `name` | text | ❌ | |
| `phone` | text | ✅ | |
| `email` | text | ✅ | |
| `notes` | text | ✅ | |
| `created_at` / `updated_at` | timestamptz | ✅ | `now()` |

---

### 2.13 `notifications`
Notifikasi in-app dan push, dipakai `notification_repository.dart` untuk Notification Hub (PRD.md §5.6).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `user_id` | uuid | ✅ | | FK → `auth.users.id` |
| `type` | text | ❌ | | Nilai bebas (`stock`, `transaction_void`, `info`, `broadcast`, dll.) — tanpa CHECK constraint |
| `title` | text | ❌ | | |
| `message` | text | ❌ | | |
| `is_read` | boolean | ✅ | `false` | |
| `image_url` | text | ✅ | | |
| `metadata` | jsonb | ✅ | `{}` | |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.14 `user_fcm_tokens`
Token Firebase Cloud Messaging per perangkat, dipakai `fcm_service.dart` untuk push notification.

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `user_id` | uuid | ✅ | FK → `users.id` |
| `fcm_token` | text (unique) | ❌ | |
| `device_info` | text | ✅ | |
| `created_at` / `updated_at` | timestamptz | ❌ | `timezone('utc', now())` |

---

### 2.15 `smart_analytics_snapshots`
Histori hasil Smart Analytics (LSTM), dipakai `smart_analytics_provider.dart` (konstanta `_snapshotsTable`) untuk fitur F-05 dan `SmartAnalyticsHistoryScreen`.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ❌ | | FK → `stores.id` |
| `created_by` | uuid | ✅ | | FK → `auth.users.id` |
| `business_type` | text | ❌ | `'Retail'` | |
| `store_name` | text | ❌ | `'Toko POS'` | Snapshot nama toko |
| `model_used` | text | ✅ | | Model LSTM yang dipakai |
| `api_online` | boolean | ❌ | `false` | Status server prediksi saat snapshot diambil |
| `is_local_server` | boolean | ❌ | `false` | Menandakan pemakaian `lstmLocalPhysicalUrl` vs Hugging Face |
| `api_server_label` | text | ❌ | `'HuggingFace Space'` | |
| `cold_start_warning` | text | ❌ | `''` | Peringatan cold-start model HF |
| `best_selling_name` | text | ❌ | `'Belum ada produk'` | |
| `total_revenue` | numeric | ❌ | `0` | |
| `revenue_text` | text | ❌ | `'Rp 0'` | |
| `projected_best_sellers` | jsonb | ❌ | `[]` | **Check**: harus array JSON |
| `pricing_recommendations` | jsonb | ❌ | `[]` | **Check**: harus array JSON |
| `tab_data` | jsonb | ❌ | `{}` | **Check**: harus objek JSON — cache tab daily/weekly/monthly/custom |
| `created_at` | timestamptz | ❌ | `now()` | |
| `model_version` | text | ✅ | | Versi artefak model, mis. `lstm-v2.1.0` |
| `fallback_reason` | text | ✅ | | Alasan memakai baseline: `insufficient_history`, `model_unavailable`, `timeout`, `legacy_v1_endpoint` |
| `input_days` | integer | ❌ | `0` | Jumlah hari data yang dipakai model |
| `metrics` | jsonb | ❌ | `{}` | MAPE/RMSE backtest yang dilaporkan server |
| `hourly_traffic` | jsonb | ❌ | `[]` | Prediksi transaksi per jam |
| `product_demand` | jsonb | ❌ | `[]` | Prediksi permintaan per produk |
| `forecast_payload` | jsonb | ❌ | `{}` | `{forecast, input_daily, profile}` — cukup untuk menggambar ulang snapshot sepenuhnya |

> Delapan kolom terakhir ditambahkan migrasi `20260728_lstm_forecast.sql`. Klien melepasnya otomatis saat insert bila migrasi belum dijalankan, sehingga fitur tetap berjalan.

---

### 2.16 `ai_forecast_points`
Satu baris per titik prediksi harian. Kolom `actual_*` diisi belakangan oleh RPC `evaluate_forecast_points`, dan menjadi dasar perhitungan MAE/RMSE/MAPE pada layar Akurasi Model (`/smart-analytics/accuracy`).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ❌ | | FK → `stores.id` **ON DELETE CASCADE** (data turunan, bukan catatan keuangan) |
| `snapshot_id` | uuid | ✅ | | FK → `smart_analytics_snapshots.id` ON DELETE CASCADE |
| `target_date` | date | ❌ | | Tanggal yang diprediksi |
| `horizon_days` | smallint | ❌ | | Jarak hari saat prediksi dibuat (H+1, H+7, …) |
| `model_used` | text | ❌ | | `lstm`, `lstm_finetuned`, `seasonal_naive`, `naive`, `offline_local` |
| `predicted_revenue` | numeric | ❌ | | |
| `predicted_tx` | integer | ✅ | | |
| `actual_revenue` / `actual_tx` | numeric / integer | ✅ | | Realisasi, diisi setelah tanggalnya lewat |
| `evaluated_at` | timestamptz | ✅ | | |
| `created_at` | timestamptz | ❌ | `now()` | |

**Unique**: `(store_id, snapshot_id, target_date)`. **RLS**: SELECT & INSERT untuk anggota toko.

---

## 3. Catatan Khusus untuk Skema Terpakai

1. **Kolom sisa fitur yang sudah dihapus dari client tetap ada di tabel yang dipakai**: `products.preparation_area`, `transaction_items.status` (alur Cooking/Ready/Served), dan `stores.settings.features.kds` adalah artefak KDS. Karena tabel induknya (`products`, `transaction_items`, `stores`) tetap aktif dipakai, kolom-kolom ini ikut terbawa meski tidak lagi punya makna fungsional di UI.
2. **`payment_method` di `transactions` tidak mendukung "Debit"** — hanya `Tunai`, `QRIS`, `Transfer`, `Pending`. PRD.md perlu disesuaikan agar tidak menyebut Debit sebagai metode yang tersedia, kecuali constraint database memang akan diperbarui.
3. **`products.discount_id` mengarah ke tabel `discounts` yang tidak dipakai app** — kolom FK tetap ada di skema meski fitur diskon-per-produk (`discounts`) belum diimplementasikan di sisi client; diskon transaksi yang benar-benar dipakai adalah lewat `vouchers`.
4. **`tables.merged_to`** (gabung meja) ada di skema tapi tidak ditemukan referensi eksplisit di provider yang diperiksa — kemungkinan field cadangan untuk fitur gabung meja yang belum diimplementasikan penuh di UI.
5. Semua tabel yang dipakai memiliki **RLS aktif**, konsisten dengan kebijakan `store_id`-scoped access di PRD.md §6.3.

---
*Dokumen ini adalah versi terfilter dari [Supabase Database Scheme.md](../Supabase%20Database%20Scheme.md), disaring berdasarkan pencarian pemanggilan `.from('...')` dan `.rpc('...')` pada `Supabase.instance.client` di seluruh `lib/`. Ditulis pada 2026-07-13.*
