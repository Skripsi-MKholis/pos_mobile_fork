# Skema Database Supabase — Parzello POS

Dokumen ini merinci skema database PostgreSQL aktual pada proyek Supabase **"Point of Sale Skripsi"** (`https://nolawradcdkemdyumoqs.supabase.co`), diambil langsung dari database melalui Supabase MCP. Semua tabel berada di schema `public`, memiliki **Row Level Security (RLS) aktif**, dan menggunakan PostgreSQL 17 (`17.6.1.104`).

> Catatan: kolom `rows` menunjukkan jumlah baris pada saat dokumen ini ditulis — bersifat snapshot, bukan batas tetap.

---

## 1. Daftar Tabel

| Tabel | Baris | RLS | Ringkasan |
| :--- | ---: | :---: | :--- |
| `stores` | 102 | ✅ | Data toko/outlet |
| `users` | 119 | ✅ | Profil pengguna aplikasi (terhubung ke `auth.users`) |
| `products` | 322 | ✅ | Katalog produk |
| `transactions` | 56.493 | ✅ | Transaksi penjualan |
| `transaction_items` | 130 | ✅ | Item detail per transaksi |
| `store_members` | 107 | ✅ | Keanggotaan staf per toko + role |
| `product_categories` | 0 | ✅ | (Legacy/tidak terpakai — lihat catatan §3) |
| `customers` | 1 | ✅ | Data pelanggan terdaftar |
| `profiles` | 120 | ✅ | Profil dasar (avatar, nama) terhubung `auth.users` |
| `categories` | 26 | ✅ | Kategori produk aktif |
| `notifications` | 16 | ✅ | Notifikasi in-app/push |
| `discounts` | 0 | ✅ | Diskon per produk (belum dipakai) |
| `vouchers` | 2 | ✅ | Voucher diskon transaksi |
| `tables` | 18 | ✅ | Meja dine-in |
| `reservations` | 5 | ✅ | Reservasi meja |
| `subscription_plans` | 3 | ✅ | Paket langganan aplikasi |
| `subscriptions` | 102 | ✅ | Status langganan per toko |
| `subscription_history` | 0 | ✅ | Riwayat pembayaran langganan |
| `app_configs` | 1 | ✅ | Konfigurasi global aplikasi (key-value) |
| `classifications` | 0 | ✅ | Hasil klasifikasi gambar (fitur AI lain, belum terpakai di POS) |
| `user_fcm_tokens` | 7 | ✅ | Token FCM per perangkat/pengguna |
| `download_waitlist` | 2 | ✅ | Waitlist email dari landing page |
| `stock_history` | 51 | ✅ | Log mutasi stok |
| `smart_analytics_snapshots` | 9 | ✅ | Histori hasil Smart Analytics (LSTM) |

---

## 2. Detail Skema per Tabel

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
| `is_public` | boolean | ✅ | `false` | Toko terlihat di direktori publik pelanggan |
| `invite_code` | text | ✅ | | Kode undangan staf |
| `owner_id` | uuid | ✅ | `auth.uid()` | FK → `users.id` dan `auth.users.id` |
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
> Catatan penting: flag `features.kds` masih ada di skema `settings` toko meskipun fitur **KDS (Kitchen Display System) telah dihapus dari kode aplikasi Flutter** (lihat PRD.md §7.2). Flag ini tampaknya sudah tidak digunakan oleh client.

**Relasi keluar (tabel lain yang mereferensikan `stores.id`)**: `discounts`, `categories`, `subscription_history`, `stock_history`, `smart_analytics_snapshots`, `subscriptions`, `notifications`, `tables`, `customers`, `product_categories`, `store_members`, `transactions`, `products`, `users`, `vouchers`, `reservations`.

---

### 2.2 `users`
Profil pengguna aplikasi POS, terhubung ke `auth.users` Supabase Auth.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id`; toko aktif pengguna |
| `full_name` | text | ❌ | | |
| `email` | text (unique) | ❌ | | |
| `role` | text | ✅ | | **Check**: `role IN ('Owner', 'Karyawan', 'Pelanggan')` |
| `is_admin` | boolean | ✅ | `false` | Admin sistem (bypass RBAC, setara `app_metadata.role == 'admin'` di client) |
| `created_at` | timestamptz | ✅ | `now()` | |

> Catatan: nilai role di database ("Owner"/"Karyawan"/"Pelanggan") **berbahasa Indonesia**, sedangkan kode Flutter (`router.dart`) membandingkan dengan string `'owner'` (lowercase, dari kolom `user_role` pada hasil query toko aktif — kemungkinan di-lowercase di level query/provider). Perlu verifikasi konsistensi casing bila menambah role baru.

---

### 2.3 `products`
Katalog produk milik toko.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `name` | text | ❌ | | |
| `price` | numeric | ❌ | | Harga jual |
| `modal_price` | numeric | ✅ | | Harga modal (legacy) |
| `cost_price` | numeric | ✅ | `0` | Harga pokok (pengganti `modal_price`) |
| `image_url` | text | ✅ | | |
| `category` | text | ✅ | `'Umum'` | Nama kategori (legacy, string bebas) |
| `category_id` | uuid | ✅ | | FK → `categories.id` (kategori terstruktur) |
| `stock_quantity` | integer | ✅ | `0` | |
| `is_infinite_stock` | boolean | ✅ | `false` | Mendukung penjualan stok kosong/tak terbatas |
| `min_stock_level` | integer | ✅ | `0` | Ambang batas notifikasi stok menipis |
| `barcode` | text | ✅ | | |
| `sku` | text | ✅ | | |
| `variants` | jsonb | ✅ | `[]` | Varian produk (ukuran/rasa, dsb.) |
| `discount_id` | uuid | ✅ | | FK → `discounts.id` |
| `discount_applied` | jsonb | ✅ | | Snapshot diskon aktif |
| `preparation_area` | text | ✅ | `'Kitchen'` | **Check**: `IN ('Kitchen', 'Bar')` — sisa dari fitur KDS |
| `description` | text | ✅ | | |
| `created_at` | timestamptz | ✅ | `now()` | |
| `updated_at` | timestamptz | ✅ | `now()` | |

> Catatan: kolom `category` (string) dan `category_id` (FK) hidup berdampingan — kemungkinan migrasi dari kategori bebas-teks ke kategori terstruktur belum sepenuhnya dituntaskan. Kolom `preparation_area` juga merupakan sisa skema KDS yang fitur UI-nya sudah dihapus.

---

### 2.4 `categories`
Kategori produk terstruktur (aktif dipakai, 26 baris).

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `name` | text | ❌ | |
| `store_id` | uuid | ❌ | FK → `stores.id` |
| `created_at` | timestamptz | ❌ | `timezone('utc', now())` |

### 2.4.1 `product_categories` (kemungkinan legacy/duplikat)
Struktur identik dengan `categories` (id, store_id, name, created_at) namun **0 baris** dan tidak direferensikan oleh `products` (yang menggunakan FK ke `categories`, bukan `product_categories`). Kemungkinan tabel awal yang digantikan oleh `categories` tetapi belum dihapus.

---

### 2.5 `transactions`
Transaksi penjualan (tabel dengan volume data terbesar — 56.493 baris).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `local_id` | text | ✅ | | ID lokal Isar sebelum sinkronisasi (untuk idempotensi) |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `cashier_id` | uuid | ✅ | | FK → `users.id` |
| `table_id` | uuid | ✅ | | FK → `tables.id` (dine-in) |
| `customer_id` | uuid | ✅ | | FK → `customers.id` |
| `total_amount` | numeric | ❌ | | |
| `payment_method` | text | ✅ | | **Check**: `IN ('Tunai', 'QRIS', 'Transfer', 'Pending')` |
| `cash_paid` | numeric | ✅ | | |
| `change_amount` | numeric | ✅ | | |
| `status` | text | ✅ | `'Berhasil'` | **Check**: `IN ('Berhasil', 'Pending', 'Dibatalkan')` |
| `discount_total` | numeric | ✅ | `0` | |
| `voucher_info` | jsonb | ✅ | `{}` | Snapshot voucher yang dipakai |
| `notes` | text | ✅ | | |
| `created_at` | timestamptz | ✅ | `now()` | |

> Catatan: metode pembayaran **tidak termasuk "Debit"** meskipun PRD.md menyebutkan Debit sebagai salah satu opsi pembayaran — hanya `Tunai`, `QRIS`, `Transfer`, `Pending` yang diizinkan oleh constraint database.

---

### 2.6 `transaction_items`
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
| `cost_price` | numeric | ✅ | `0` | Snapshot harga modal (untuk laporan laba) |
| `selected_variants` | jsonb | ✅ | | |
| `discount_applied` | jsonb | ✅ | | |
| `notes` | text | ✅ | | |
| `status` | text | ✅ | `'Pending'` | **Check**: `IN ('Pending', 'Cooking', 'Ready', 'Served')` — sisa alur status KDS per-item |

---

### 2.7 `store_members`
Keanggotaan staf per toko beserta peran (mendukung multi-store per user).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `user_id` | uuid | ❌ | | FK → `users.id` |
| `store_id` | uuid | ❌ | | FK → `stores.id` |
| `role` | text | ❌ | | **Check**: `IN ('Owner', 'Karyawan', 'Pelanggan')` |
| `status` | text | ✅ | `'active'` | **Check**: `IN ('active', 'pending')` — status undangan staf |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.8 `customers`
Data pelanggan terdaftar toko (untuk fitur loyalitas/histori pembelian).

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `store_id` | uuid | ✅ | FK → `stores.id` |
| `name` | text | ❌ | |
| `phone` | text | ✅ | |
| `email` | text | ✅ | |
| `notes` | text | ✅ | |
| `created_at` | timestamptz | ✅ | `now()` |
| `updated_at` | timestamptz | ✅ | `now()` |

### 2.9 `profiles`
Profil ringkas terhubung langsung ke `auth.users` (terpisah dari `users`), tampaknya dipakai untuk avatar/identitas dasar akun.

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK, FK → `auth.users.id`) | ❌ | |
| `email` | text | ✅ | |
| `full_name` | text | ✅ | |
| `avatar_url` | text | ✅ | |
| `created_at` | timestamptz | ❌ | `timezone('utc', now())` |

> Catatan: adanya dua tabel profil pengguna (`users` dan `profiles`) dengan kolom yang tumpang tindih (`full_name`, `email`) berpotensi menjadi sumber duplikasi data — perlu klarifikasi pembagian tanggung jawab keduanya di level aplikasi.

---

### 2.10 `notifications`
Notifikasi in-app dan push (FCM).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `user_id` | uuid | ✅ | | FK → `auth.users.id` |
| `type` | text | ❌ | | Nilai bebas (mis. `stock`, `transaction_void`, `info`, `broadcast`) — **tanpa CHECK constraint** di level DB |
| `title` | text | ❌ | | |
| `message` | text | ❌ | | |
| `is_read` | boolean | ✅ | `false` | |
| `image_url` | text | ✅ | | |
| `metadata` | jsonb | ✅ | `{}` | |
| `created_at` | timestamptz | ✅ | `now()` | |

---

### 2.11 `discounts`
Diskon berbasis produk (terpisah dari `vouchers` yang berbasis kode/transaksi). Saat ini **0 baris** — fitur mungkin belum diaktifkan penuh di UI.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ✅ | | FK → `stores.id` |
| `name` | text | ❌ | | |
| `description` | text | ✅ | | |
| `type` | text | ❌ | | **Check**: `IN ('percentage', 'fixed')` |
| `value` | numeric | ❌ | | |
| `start_date` / `end_date` | timestamptz | ✅ | | |
| `is_active` | boolean | ✅ | `true` | |
| `created_at` | timestamptz | ✅ | `now()` | |

### 2.12 `vouchers`
Voucher diskon berbasis kode untuk transaksi POS (dipakai — sesuai `Voucher` model di PRD.md §3.7).

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

### 2.13 `tables`
Meja dine-in.

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `extensions.uuid_generate_v4()` | |
| `store_id` | uuid | ❌ | | FK → `stores.id` |
| `name` | text | ❌ | | |
| `capacity` | integer | ✅ | `2` | |
| `status` | text | ✅ | `'available'` | **Check**: `IN ('available', 'occupied', 'cleaning', 'reserved')` |
| `merged_to` | uuid | ✅ | | Self-FK — mendukung penggabungan meja |
| `created_at` / `updated_at` | timestamptz | ✅ | `now()` | |

> Data server (18 baris, status lifecycle lengkap, dukungan gabung meja) jauh lebih kaya dari yang tersurat di kode Flutter saat ini — lihat PRD.md §5.2, dimana UI table monitoring hanya tersisa sebagai provider tanpa layar/rute khusus. Skema backend untuk manajemen meja penuh (termasuk reservasi) tampak lebih matang daripada implementasi client saat ini.

### 2.14 `reservations`
Reservasi meja (fitur belum terdokumentasi di PRD.md — perlu ditambahkan bila UI-nya sudah/akan diimplementasikan).

| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid | ❌ | | FK → `stores.id` |
| `table_id` | uuid | ✅ | | FK → `tables.id` |
| `customer_name` | text | ❌ | | |
| `customer_phone` | text | ✅ | | |
| `reservation_date` | date | ❌ | | |
| `reservation_time` | time | ❌ | | |
| `number_of_guests` | integer | ❌ | `1` | |
| `status` | text | ❌ | `'Pending'` | **Check**: `IN ('Pending', 'Confirmed', 'Cancelled', 'Completed')` |
| `notes` | text | ✅ | | |
| `created_at` / `updated_at` | timestamptz | ✅ | `now()` | |

---

### 2.15 `subscription_plans`, `subscriptions`, `subscription_history`
Sistem langganan berbayar (monetisasi aplikasi) — **belum terdokumentasi sama sekali di PRD.md**, namun aktif digunakan (102 baris di `subscriptions`, hampir menyamai jumlah toko).

**`subscription_plans`** (3 paket terdaftar):
| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `slug` | text (unique) | ❌ | |
| `name` | text | ❌ | |
| `description` | text | ✅ | |
| `price` | numeric | ❌ | `0` |
| `max_outlets` | integer | ❌ | `1` |
| `max_transactions` | integer | ❌ | `500` |
| `features` | jsonb | ❌ | `{}` |
| `created_at` | timestamptz | ✅ | `now()` |

**`subscriptions`** (langganan aktif per toko, 1:1 via `store_id` unique):
| Kolom | Tipe | Nullable | Default | Keterangan |
| :--- | :--- | :---: | :--- | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` | |
| `store_id` | uuid (unique) | ✅ | | FK → `stores.id` |
| `plan_id` | uuid | ✅ | | FK → `subscription_plans.id` |
| `status` | text | ❌ | `'active'` | **Check**: `IN ('active', 'expired', 'trial')` |
| `start_date` / `end_date` | timestamptz | ✅ | `now()` / — | |
| `created_at` / `updated_at` | timestamptz | ✅ | `now()` | |

**`subscription_history`** (log transaksi pembayaran langganan, 0 baris):
| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `store_id` | uuid | ✅ | FK → `stores.id` |
| `plan_id` | uuid | ✅ | FK → `subscription_plans.id` |
| `amount` | numeric | ❌ | `0` |
| `status` | text | ❌ | |
| `payload` | jsonb | ✅ | `{}` |
| `created_at` | timestamptz | ✅ | `now()` |

> **Penting**: skema langganan (`max_outlets`, `max_transactions`, batasan per paket) menunjukkan model bisnis *freemium/tiered* yang aktif berjalan di backend, namun tidak tercermin sama sekali dalam PRD.md. Perlu ditambahkan sebagai fitur produk (F-08?) jika memang diimplementasikan di sisi client (mis. paywall, batas transaksi).

---

### 2.16 `stock_history`
Log mutasi stok (audit inventaris) — sesuai `StockHistoryLocal` di PRD.md §3.6.

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

### 2.17 `smart_analytics_snapshots`
Histori hasil Smart Analytics (LSTM) — sesuai fitur F-05 & `SmartAnalyticsHistoryScreen` di PRD.md §5.5. **Comment resmi dari database**: *"Riwayat hasil Smart Analitik per toko; setiap baris = satu kali refresh (panggilan ke server prediksi). tab_data menyimpan data siap-tampil untuk tab daily/weekly/monthly/custom agar histori bisa dilihat tanpa refetch ke model."*

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
| `revenue_text` | text | ❌ | `'Rp 0'` | Format tampilan siap pakai |
| `projected_best_sellers` | jsonb | ❌ | `[]` | **Check**: harus berupa array JSON |
| `pricing_recommendations` | jsonb | ❌ | `[]` | **Check**: harus berupa array JSON |
| `tab_data` | jsonb | ❌ | `{}` | **Check**: harus berupa objek JSON — cache tab daily/weekly/monthly/custom |
| `created_at` | timestamptz | ❌ | `now()` | |

---

### 2.18 `app_configs`
Konfigurasi global aplikasi (key-value store), 1 baris terdaftar.

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `key` | text (PK) | ❌ | |
| `value` | text | ❌ | |
| `description` | text | ✅ | |
| `updated_at` | timestamptz | ✅ | `now()` |

### 2.19 `user_fcm_tokens`
Token Firebase Cloud Messaging per perangkat/pengguna (untuk push notification, PRD.md §5.6).

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `user_id` | uuid | ✅ | FK → `users.id` |
| `fcm_token` | text (unique) | ❌ | |
| `device_info` | text | ✅ | |
| `created_at` / `updated_at` | timestamptz | ❌ | `timezone('utc', now())` |

### 2.20 `classifications`
Hasil klasifikasi gambar berbasis AI (confidence score) — **tidak berkaitan dengan fitur POS** di PRD.md. Kemungkinan sisa dari eksperimen/proyek AI lain atau fitur di luar cakupan dokumen ini yang berbagi project Supabase yang sama. **0 baris**, belum aktif dipakai.

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `user_id` | uuid | ✅ | FK → `auth.users.id` |
| `result` | text | ❌ | |
| `confidence` | float8 | ❌ | |
| `image_url` | text | ✅ | |
| `status` | text | ✅ | `'COMPLETED'` |
| `created_at` | timestamptz | ✅ | `now()` |

### 2.21 `download_waitlist`
Waitlist email dari landing page (marketing), tidak terkait langsung dengan aplikasi mobile.

| Kolom | Tipe | Nullable | Default |
| :--- | :--- | :---: | :--- |
| `id` | uuid (PK) | ❌ | `gen_random_uuid()` |
| `email` | text (unique) | ❌ | |
| `source` | text | ❌ | `'download_page'` |
| `created_at` | timestamptz | ❌ | `now()` |

---

## 3. Observasi & Catatan Penting

1. **RBAC di database vs client tidak sepenuhnya selaras.** Kolom `role` di `users`/`store_members` memakai nilai berbahasa Indonesia (`Owner`, `Karyawan`, `Pelanggan`), sementara guard router Flutter (`router.dart`) membandingkan string `'owner'` lowercase yang berasal dari alias `user_role` pada hasil query gabungan (kemungkinan sudah dinormalisasi di provider). Perubahan skema role sebaiknya diverifikasi ulang terhadap logika RBAC di `router.dart`.
2. **Sisa skema fitur KDS yang sudah dihapus dari client**: kolom `stores.settings.features.kds`, `products.preparation_area` (`Kitchen`/`Bar`), dan `transaction_items.status` (`Pending/Cooking/Ready/Served`) semuanya adalah artefak dari fitur Kitchen Display System yang telah dihapus dari kode Flutter (lihat PRD.md §7.2). Tidak menimbulkan masalah fungsional, tetapi dapat dipertimbangkan untuk dibersihkan pada migrasi berikutnya bila KDS tidak akan dihidupkan kembali.
3. **`categories` vs `product_categories`**: dua tabel dengan struktur nyaris identik. `categories` yang aktif dipakai (26 baris, direferensikan oleh `products.category_id`); `product_categories` kosong (0 baris) dan tidak direferensikan — kemungkinan tabel warisan (*legacy*) yang aman untuk diarsipkan/dihapus setelah verifikasi.
4. **Sistem langganan (subscription) belum terdokumentasi di PRD.md.** Tabel `subscription_plans`, `subscriptions`, dan `subscription_history` menunjukkan adanya model bisnis *tiered/freemium* (pembatasan `max_outlets`, `max_transactions` per paket) yang berjalan di backend dengan 102 baris `subscriptions` aktif (mendekati jumlah total toko). Ini kemungkinan modul monetisasi yang perlu ditambahkan sebagai fitur resmi di PRD.md.
5. **Metode pembayaran di database hanya mendukung**: `Tunai`, `QRIS`, `Transfer`, `Pending` (constraint `transactions.payment_method`). PRD.md §5.2 menyebutkan "Debit" sebagai salah satu opsi — ini **tidak konsisten** dengan constraint database saat ini dan perlu diklarifikasi (baik PRD yang perlu dikoreksi, atau constraint database yang perlu diperbarui bila Debit memang didukung).
6. **`reservations` (reservasi meja) adalah fitur backend yang belum terdokumentasi di PRD.md** — skema lengkap dengan status lifecycle (`Pending/Confirmed/Cancelled/Completed`) dan sudah memiliki 5 baris data, mengindikasikan fitur ini sudah/akan digunakan.
7. **Dua tabel profil pengguna** (`users` dan `profiles`) memiliki kolom yang tumpang tindih (`full_name`, `email`), berpotensi menjadi sumber duplikasi/inkonsistensi data — perlu klarifikasi pembagian peran keduanya.
8. **Tabel `classifications`** tampak tidak berkaitan dengan domain POS sama sekali (klasifikasi gambar dengan confidence score) — kemungkinan proyek Supabase ini dipakai bersama oleh aplikasi lain di luar cakupan Parzello POS.
9. Seluruh 24 tabel memiliki **RLS aktif**, konsisten dengan kebijakan keamanan data yang disyaratkan PRD.md §6.3 (`store_id`-scoped access).

---
*Dokumen ini dihasilkan secara otomatis berdasarkan introspeksi langsung skema database Supabase melalui Supabase MCP pada tanggal 2026-07-13. Untuk detail kebijakan RLS per tabel, gunakan `get_advisors` atau query `pg_policies` secara terpisah — dokumen ini hanya mencakup struktur kolom, constraint, dan relasi foreign key.*
