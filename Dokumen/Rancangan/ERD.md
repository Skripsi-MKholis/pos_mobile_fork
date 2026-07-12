# Entity Relationship Diagram (ERD) & Kamus Data
**Aplikasi: Parzello POS Mobile (ZelloPOS)**
**Platform: Supabase PostgreSQL (Cloud) & Isar Database (Local Cache)**
**Tanggal Penyusunan: 1 Juni 2026 — Direvisi 13 Juli 2026 mengikuti introspeksi skema aktual**

---

## Pendahuluan

Dokumen ini merinci rancangan basis data relasional (**Entity Relationship Diagram - ERD**) untuk aplikasi **Parzello POS Mobile**. Arsitektur database aplikasi ini didesain secara hibrida, di mana skema relasional di **Supabase PostgreSQL (Cloud)** direplikasi secara cerdas di dalam **Isar DB (Database Lokal Client)** untuk mendukung ketahanan operasional *offline-first*.

Beberapa tabel lokal memiliki atribut tambahan pelacakan sinkronisasi (`isSynced` dan `isDeleted`) untuk menjaga integritas data saat terjadi pertukaran data di latar belakang. **Tidak semua tabel cloud memiliki padanan lokal di Isar** — hanya `categories`, `products`, `transactions`, `transaction_items`, `stock_history`, `stores`, dan `notifications` yang memiliki koleksi Isar (lihat [Dokumen/PRD.md](../PRD.md) §3). Tabel lain seperti `users`, `profiles`, `customers`, `tables`, `vouchers`, dan `user_fcm_tokens` bersifat **cloud-only** dan memerlukan koneksi internet untuk dibaca/ditulis.

> Isi dokumen ini diselaraskan dengan hasil introspeksi langsung ke database Supabase project *"Point of Sale Skripsi"* (`nolawradcdkemdyumoqs`) via Supabase MCP, difilter hanya untuk tabel yang benar-benar dipakai kode aplikasi ini — lihat [Dokumen/Supabase/This App Supabase Database Scheme.md](../Supabase/This%20App%20Supabase%20Database%20Scheme.md) untuk detail lengkap per kolom dan referensi lokasi pemakaian di kode.

---

## Diagram ERD (Mermaid Diagram)

Diagram berikut digambar menggunakan format **Mermaid erDiagram** untuk menggambarkan entitas, atribut (beserta tipe data), kunci utama (PK), kunci tamu (FK), serta hubungan kardinalitas antartabel — mencakup seluruh 14 tabel yang benar-benar dipakai aplikasi.

```mermaid
erDiagram
    STORES ||--o{ STORE_MEMBERS : "has"
    STORES ||--o{ USERS : "employs"
    STORES ||--o{ CATEGORIES : "defines"
    STORES ||--o{ PRODUCTS : "stocks"
    STORES ||--o{ TABLES : "manages"
    STORES ||--o{ VOUCHERS : "creates"
    STORES ||--o{ CUSTOMERS : "registers"
    STORES ||--o{ TRANSACTIONS : "records"
    STORES ||--o{ STOCK_HISTORY : "tracks"
    STORES ||--o{ NOTIFICATIONS : "broadcasts"
    STORES ||--o{ SMART_ANALYTICS_SNAPSHOTS : "generates"

    AUTH_USERS ||--o| PROFILES : "extends"
    AUTH_USERS ||--o{ USER_FCM_TOKENS : "registers_device"
    USERS ||--o{ STORE_MEMBERS : "is_member_via"
    USERS ||--o{ USER_FCM_TOKENS : "owns"

    CATEGORIES ||--o{ PRODUCTS : "classifies"
    TABLES ||--o{ TRANSACTIONS : "assigns"
    CUSTOMERS ||--o{ TRANSACTIONS : "makes"
    USERS ||--o{ TRANSACTIONS : "cashiers"
    USERS ||--o{ STOCK_HISTORY : "adjusts"

    PRODUCTS ||--o{ TRANSACTION_ITEMS : "included_in"
    PRODUCTS ||--o{ STOCK_HISTORY : "logs_change"

    TRANSACTIONS ||--o{ TRANSACTION_ITEMS : "contains"

    STORES {
        uuid id PK
        text name
        text address
        text phone
        text email
        text business_type
        text country
        text province
        text city
        boolean is_public
        text invite_code
        uuid owner_id FK
        text logo_url
        jsonb settings
        timestamptz created_at
    }

    USERS {
        uuid id PK
        uuid store_id FK "nullable"
        text full_name
        text email UK
        text role "Owner, Karyawan, Pelanggan"
        boolean is_admin
        timestamptz created_at
    }

    PROFILES {
        uuid id PK_FK "-> auth.users.id"
        text email
        text full_name
        text avatar_url
        timestamptz created_at
    }

    STORE_MEMBERS {
        uuid id PK
        uuid user_id FK
        uuid store_id FK
        text role "Owner, Karyawan, Pelanggan"
        text status "active, pending"
        timestamptz created_at
    }

    CATEGORIES {
        uuid id PK
        uuid store_id FK
        text name
        boolean is_synced "Local Only (Isar)"
        boolean is_deleted "Local Only (Isar)"
        timestamptz created_at
    }

    PRODUCTS {
        uuid id PK
        uuid store_id FK
        uuid category_id FK "nullable"
        uuid discount_id FK "nullable, unused feature"
        text name
        text description
        numeric price
        numeric modal_price "legacy"
        numeric cost_price
        integer stock_quantity
        boolean is_infinite_stock
        integer min_stock_level
        text sku
        text barcode
        text category "legacy free-text"
        text image_url
        jsonb variants
        jsonb discount_applied
        text preparation_area "legacy KDS remnant"
        boolean is_synced "Local Only (Isar)"
        boolean is_deleted "Local Only (Isar)"
        timestamptz created_at
        timestamptz updated_at
    }

    TABLES {
        uuid id PK
        uuid store_id FK
        text name
        integer capacity
        text status "available, occupied, cleaning, reserved"
        uuid merged_to FK "self, nullable"
        timestamptz created_at
        timestamptz updated_at
    }

    VOUCHERS {
        uuid id PK
        uuid store_id FK
        text code
        text description
        text type "percentage, fixed"
        numeric value
        numeric min_purchase
        numeric max_discount
        integer usage_limit
        integer used_count
        timestamptz starts_at
        timestamptz expires_at
        boolean is_active
        timestamptz created_at
    }

    CUSTOMERS {
        uuid id PK
        uuid store_id FK
        text name
        text phone
        text email
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    TRANSACTIONS {
        uuid id PK
        text local_id "Isar local id (idempotency)"
        uuid store_id FK
        uuid cashier_id FK
        uuid table_id FK "nullable"
        uuid customer_id FK "nullable"
        numeric total_amount
        numeric discount_total
        text payment_method "Tunai, QRIS, Transfer, Pending"
        numeric cash_paid
        numeric change_amount
        text status "Berhasil, Pending, Dibatalkan"
        jsonb voucher_info
        text notes
        boolean is_synced "Local Only (Isar)"
        timestamptz created_at
    }

    TRANSACTION_ITEMS {
        uuid id PK
        uuid transaction_id FK
        uuid product_id FK
        text product_name
        text product_sku
        numeric unit_price
        numeric cost_price
        integer quantity
        numeric subtotal
        jsonb selected_variants
        jsonb discount_applied
        text notes
        text status "legacy KDS remnant"
    }

    STOCK_HISTORY {
        uuid id PK
        uuid store_id FK
        uuid product_id FK "nullable"
        uuid cashier_id FK "nullable"
        text product_name
        integer quantity_change
        integer old_stock
        integer new_stock
        text change_type "sale, manual_addition, manual_reduction, manual_adjustment"
        uuid reference_id "nullable"
        boolean is_synced "Local Only (Isar)"
        timestamptz created_at
    }

    NOTIFICATIONS {
        uuid id PK
        uuid store_id FK "nullable"
        uuid user_id FK "nullable"
        text title
        text message
        text type "free text: stock, transaction_void, info, broadcast, dll."
        boolean is_read
        text image_url
        jsonb metadata
        timestamptz created_at
    }

    USER_FCM_TOKENS {
        uuid id PK
        uuid user_id FK
        text fcm_token UK
        text device_info
        timestamptz created_at
        timestamptz updated_at
    }

    SMART_ANALYTICS_SNAPSHOTS {
        uuid id PK
        uuid store_id FK
        uuid created_by FK "nullable"
        text business_type
        text store_name
        text model_used
        boolean api_online
        boolean is_local_server
        text api_server_label
        text cold_start_warning
        text best_selling_name
        numeric total_revenue
        text revenue_text
        jsonb projected_best_sellers
        jsonb pricing_recommendations
        jsonb tab_data
        timestamptz created_at
    }
```

---

## Kamus Data Terperinci (Data Dictionary)

Berikut adalah detail kolom, tipe data, kendala (*constraints*), serta deskripsi fungsional untuk setiap entitas dalam sistem Parzello POS yang **benar-benar dipakai oleh kode aplikasi** (`lib/`). Sembilan tabel lain pada project Supabase yang sama (`product_categories`, `discounts`, `reservations`, `subscription_plans`, `subscriptions`, `subscription_history`, `app_configs`, `classifications`, `download_waitlist`) tidak direferensikan di kode dan sengaja diabaikan dari dokumen ini.

### 1. Tabel: `stores`
Menyimpan informasi identitas dasar outlet/toko merchant.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID Unik global toko. |
| `name` | TEXT | NOT NULL | Nama toko/outlet. |
| `address` | TEXT | NULLABLE | Alamat fisik toko. |
| `phone` | TEXT | NULLABLE | Nomor telepon toko. |
| `email` | TEXT | NULLABLE | Alamat email toko. |
| `business_type` | TEXT | NULLABLE | Kategori bisnis (mis. Retail/F&B). |
| `country` | TEXT | NULLABLE, default `'Indonesia'` | Negara lokasi toko. |
| `province` | TEXT | NULLABLE | Provinsi lokasi toko. |
| `city` | TEXT | NULLABLE | Kota lokasi toko. |
| `is_public` | BOOLEAN | NULLABLE, default `false` | Menentukan apakah toko terlihat di direktori publik pelanggan (`customer` app). |
| `invite_code` | TEXT | NULLABLE | Kode unik undangan staf gabung toko. |
| `owner_id` | UUID | FK -> `users.id` & `auth.users.id`, default `auth.uid()` | Pemilik toko. |
| `logo_url` | TEXT | NULLABLE | URL gambar logo toko di Supabase Storage. |
| `settings` | JSONB | NULLABLE | Pengaturan operasional (fitur aktif, pajak/service charge, ambang stok minim). Lihat struktur di bawah. |
| `created_at` | TIMESTAMPTZ | default `now()` | Waktu pendaftaran toko. |

**Struktur default `settings` (JSONB):**
```json
{
  "features": { "kds": true, "tables": true, "customers": true, "promotions": true, "reservations": true },
  "financial": { "tax_rate": 10, "tax_enabled": false, "service_charge_rate": 5, "service_charge_enabled": false },
  "operational": { "auto_print": false, "business_model": "custom", "low_stock_threshold": 5 }
}
```
> Catatan: `features.kds` dan `features.reservations` adalah sisa skema untuk fitur KDS dan reservasi meja yang **sudah tidak diimplementasikan di sisi client Flutter** — lihat PRD.md §7.2.

### 2. Tabel: `users`
Profil pengguna aplikasi, terhubung ke `auth.users` Supabase Auth, dipakai untuk resolusi role & data staf.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik pengguna. |
| `store_id` | UUID | NULLABLE, FK -> `stores.id` | Toko aktif pengguna saat ini. |
| `full_name` | TEXT | NOT NULL | Nama lengkap pengguna. |
| `email` | TEXT | NOT NULL, UNIQUE | Email login pengguna. |
| `role` | TEXT | NULLABLE, CHECK `IN ('Owner', 'Karyawan', 'Pelanggan')` | Peran pengguna. |
| `is_admin` | BOOLEAN | NULLABLE, default `false` | Admin sistem — setara `app_metadata.role == 'admin'` di client, dipakai `router.dart` sebagai jalur bypass RBAC. |
| `created_at` | TIMESTAMPTZ | default `now()` | Waktu pendaftaran pengguna. |

> Catatan penting: nilai `role` berbahasa Indonesia dengan huruf kapital awal (`Owner`, `Karyawan`, `Pelanggan`), sedangkan guard router Flutter membandingkan string `'owner'` lowercase pada alias `user_role` hasil query gabungan — perlu verifikasi konsistensi casing di level provider.

### 3. Tabel: `profiles`
Profil ringkas terhubung langsung ke `auth.users`, dipakai terpisah dari `users` (mis. untuk avatar/nama tampilan cepat pada layar profil).

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, FK -> `auth.users.id` | ID pengguna (sama dengan Supabase Auth). |
| `email` | TEXT | NULLABLE | Email pengguna. |
| `full_name` | TEXT | NULLABLE | Nama lengkap. |
| `avatar_url` | TEXT | NULLABLE | URL foto profil. |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `timezone('utc', now())` | Waktu pembuatan profil. |

> Catatan: `users` dan `profiles` memiliki kolom yang tumpang tindih (`full_name`, `email`) — berpotensi menjadi sumber duplikasi data; belum ada dokumentasi resmi pembagian tanggung jawab keduanya di level aplikasi.

### 4. Tabel: `store_members`
Menyimpan hubungan hak akses anggota staf terhadap suatu toko (untuk penegakan RBAC), mendukung satu pengguna menjadi anggota di lebih dari satu toko.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik keanggotaan. |
| `user_id` | UUID | NOT NULL, FK -> `users.id` | Pengguna anggota. |
| `store_id` | UUID | NOT NULL, FK -> `stores.id` | Toko terkait. |
| `role` | TEXT | NOT NULL, CHECK `IN ('Owner', 'Karyawan', 'Pelanggan')` | Peran staf di toko tersebut. |
| `status` | TEXT | NULLABLE, default `'active'`, CHECK `IN ('active', 'pending')` | Status keanggotaan/undangan. |
| `created_at` | TIMESTAMPTZ | default `now()` | Waktu penambahan staf ke toko. |

### 5. Tabel: `categories`
Kategori pengelompokan produk makanan/barang dagangan.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik kategori. |
| `store_id` | UUID | NOT NULL, FK -> `stores.id` | Kepemilikan kategori per toko. |
| `name` | TEXT | NOT NULL | Nama kategori (contoh: *Makanan*, *Minuman*). |
| `is_synced` | BOOLEAN | *Isar Local Only, tidak ada di skema cloud* | Penanda sinkronisasi database lokal ke cloud. |
| `is_deleted` | BOOLEAN | *Isar Local Only, tidak ada di skema cloud* | Flag *soft delete* lokal sebelum dihapus permanen di cloud. |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `timezone('utc', now())` | Waktu pembuatan kategori. |

### 6. Tabel: `products`
Katalog produk barang atau makanan/minuman yang dijual.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik produk. |
| `store_id` | UUID | NULLABLE, FK -> `stores.id` | Kepemilikan produk per toko. |
| `category_id` | UUID | NULLABLE, FK -> `categories.id` | Kategori produk (`NULL` = "Tanpa Kategori"). |
| `discount_id` | UUID | NULLABLE, FK -> `discounts.id` | **Kolom ada di skema, namun tabel `discounts` tidak dipakai aplikasi** — diskon transaksi memakai `vouchers`, bukan jalur ini. |
| `name` | TEXT | NOT NULL | Nama menu/produk. |
| `description` | TEXT | NULLABLE | Deskripsi produk. |
| `price` | NUMERIC | NOT NULL | Harga jual produk. |
| `modal_price` | NUMERIC | NULLABLE | Harga modal — kolom legacy, digantikan `cost_price`. |
| `cost_price` | NUMERIC | NULLABLE, default `0` | Harga pokok/modal produk saat ini. |
| `stock_quantity` | INTEGER | NULLABLE, default `0` | Jumlah stok barang saat ini. |
| `is_infinite_stock` | BOOLEAN | NULLABLE, default `false` | Mengizinkan penjualan meski stok `0`/minus. |
| `min_stock_level` | INTEGER | NULLABLE, default `0` | Ambang batas pemicu notifikasi stok menipis. |
| `sku` | TEXT | NULLABLE | Kode SKU produk. |
| `barcode` | TEXT | NULLABLE | Kode barcode untuk pemindaian kamera native. |
| `category` | TEXT | NULLABLE, default `'Umum'` | Nama kategori bebas-teks — kolom legacy, digantikan `category_id`. |
| `image_url` | TEXT | NULLABLE | Foto produk yang tersimpan di Supabase Storage. |
| `variants` | JSONB | NULLABLE, default `[]` | Varian produk (ukuran/rasa, dsb.). |
| `discount_applied` | JSONB | NULLABLE | Snapshot diskon yang sedang aktif pada produk. |
| `preparation_area` | TEXT | NULLABLE, default `'Kitchen'`, CHECK `IN ('Kitchen', 'Bar')` | Sisa skema fitur KDS yang sudah dihapus dari client — tidak lagi bermakna fungsional di UI. |
| `is_synced` | BOOLEAN | *Isar Local Only, tidak ada di skema cloud* | Penanda status sinkronisasi cloud. |
| `is_deleted` | BOOLEAN | *Isar Local Only, tidak ada di skema cloud* | Flag *soft delete* produk. |
| `created_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu pembuatan produk. |
| `updated_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu pembaruan terakhir. |

### 7. Tabel: `tables`
Tata letak meja operasional restoran (untuk F&B dine-in).

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `extensions.uuid_generate_v4()` | ID unik meja. |
| `store_id` | UUID | NOT NULL, FK -> `stores.id` | Kepemilikan meja per toko. |
| `name` | TEXT | NOT NULL | Nama meja (contoh: *Meja 01*, *VIP 2*). |
| `capacity` | INTEGER | NULLABLE, default `2` | Kapasitas daya tampung orang di meja. |
| `status` | TEXT | NULLABLE, default `'available'`, CHECK `IN ('available', 'occupied', 'cleaning', 'reserved')` | Status meja terkini. |
| `merged_to` | UUID | NULLABLE, FK -> `tables.id` (self) | Menandakan meja ini digabung ke meja lain — belum ditemukan referensi eksplisit di provider yang diperiksa, kemungkinan field cadangan untuk fitur gabung meja yang belum diimplementasikan penuh di UI. |
| `created_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu pembuatan meja. |
| `updated_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu pembaruan terakhir. |

> Catatan: tabel ini dipakai `table_provider.dart` dan `table_monitoring_provider.dart`, meski PRD.md mencatat belum ada layar/rute UI khusus (`/manage-tables`) yang terdaftar di router — kemungkinan fungsinya kini terintegrasi dalam alur POS/keranjang, bukan layar terpisah.

### 8. Tabel: `vouchers`
Kupon promosi diskon transaksi belanja berbasis kode.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik voucher. |
| `store_id` | UUID | NULLABLE, FK -> `stores.id` | Kepemilikan voucher per toko. |
| `code` | TEXT | NOT NULL | Kode kupon transaksi (contoh: *MERDEKA10*). |
| `description` | TEXT | NULLABLE | Deskripsi voucher. |
| `type` | TEXT | NOT NULL, CHECK `IN ('percentage', 'fixed')` | Tipe diskon: persen atau nominal rupiah. |
| `value` | NUMERIC | NOT NULL | Besaran nilai pemotongan diskon. |
| `min_purchase` | NUMERIC | NULLABLE, default `0` | Batas minimal transaksi agar kupon dapat digunakan. |
| `max_discount` | NUMERIC | NULLABLE | Batas maksimal nominal potongan (untuk tipe persen). |
| `usage_limit` | INTEGER | NULLABLE | Batas maksimal jumlah pemakaian voucher. |
| `used_count` | INTEGER | NULLABLE, default `0` | Jumlah pemakaian voucher sejauh ini. |
| `starts_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu mulai berlaku voucher. |
| `expires_at` | TIMESTAMPTZ | NULLABLE | Waktu kedaluwarsa voucher. |
| `is_active` | BOOLEAN | NULLABLE, default `true` | Status keaktifan kupon diskon. |
| `created_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu kupon dibuat. |

### 9. Tabel: `customers`
Data pelanggan terdaftar toko, dipakai fitur self-order/customer-facing app.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik pelanggan. |
| `store_id` | UUID | NULLABLE, FK -> `stores.id` | Toko tempat pelanggan terdaftar. |
| `name` | TEXT | NOT NULL | Nama pelanggan. |
| `phone` | TEXT | NULLABLE | Nomor telepon pelanggan. |
| `email` | TEXT | NULLABLE | Email pelanggan. |
| `notes` | TEXT | NULLABLE | Catatan tambahan. |
| `created_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu pendaftaran pelanggan. |
| `updated_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu pembaruan terakhir. |

### 10. Tabel: `transactions`
Nota transaksi penjualan kasir (induk dari struk).

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID nota transaksi. |
| `local_id` | TEXT | NULLABLE | ID lokal Isar sebelum sinkronisasi, dipakai untuk menjaga idempotensi saat sync. |
| `store_id` | UUID | NULLABLE, FK -> `stores.id` | Transaksi dicatat pada store terkait. |
| `cashier_id` | UUID | NULLABLE, FK -> `users.id` | Kasir yang melayani pembayaran. |
| `table_id` | UUID | NULLABLE, FK -> `tables.id` | Meja terkait jika transaksi berupa F&B dine-in. |
| `customer_id` | UUID | NULLABLE, FK -> `customers.id` | Pelanggan terkait transaksi (self-order). |
| `total_amount` | NUMERIC | NOT NULL | Total akhir nominal yang harus dibayar. |
| `discount_total` | NUMERIC | NULLABLE, default `0` | Total potongan diskon dari transaksi. |
| `payment_method` | TEXT | NULLABLE, CHECK `IN ('Tunai', 'QRIS', 'Transfer', 'Pending')` | Metode bayar. **Tidak mencakup "Debit"/"Kredit"** meskipun disebut di dokumen produk sebelumnya — perlu diklarifikasi bila memang akan didukung. |
| `cash_paid` | NUMERIC | NULLABLE | Jumlah uang tunai yang diserahkan pembeli. |
| `change_amount` | NUMERIC | NULLABLE | Uang kembalian transaksi tunai. |
| `status` | TEXT | NULLABLE, default `'Berhasil'`, CHECK `IN ('Berhasil', 'Pending', 'Dibatalkan')` | Status transaksi. **Tidak ada nilai `'Void'`** — pembatalan memakai status `'Dibatalkan'`. |
| `voucher_info` | JSONB | NULLABLE, default `{}` | Salinan informasi voucher yang dipakai saat checkout. |
| `notes` | TEXT | NULLABLE | Catatan tambahan transaksi. |
| `is_synced` | BOOLEAN | *Isar Local Only, tidak ada di skema cloud* | Status sinkronisasi transaksi offline ke server cloud. |
| `created_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu terjadinya transaksi belanja. |

### 11. Tabel: `transaction_items`
Rincian baris menu/produk yang dibeli dalam sebuah transaksi (anak tabel `transactions`).

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik baris transaksi. |
| `transaction_id` | UUID | NULLABLE, FK -> `transactions.id` | Induk nota transaksi belanja. |
| `product_id` | UUID | NULLABLE, FK -> `products.id` | Produk yang dibeli. |
| `product_name` | TEXT | NOT NULL | *Snapshot* nama produk saat dibeli (bertahan meski produk asli dihapus). |
| `product_sku` | TEXT | NULLABLE | *Snapshot* SKU produk saat dibeli. |
| `unit_price` | NUMERIC | NOT NULL | *Snapshot* harga satuan produk saat dibeli. |
| `cost_price` | NUMERIC | NULLABLE, default `0` | *Snapshot* harga modal — dipakai untuk laporan laba kotor. |
| `quantity` | INTEGER | NOT NULL | Jumlah barang yang dibeli. |
| `subtotal` | NUMERIC | NOT NULL | Total harga baris (`unit_price * quantity`). |
| `selected_variants` | JSONB | NULLABLE | Varian produk yang dipilih pembeli. |
| `discount_applied` | JSONB | NULLABLE | Snapshot diskon per-item yang diterapkan. |
| `notes` | TEXT | NULLABLE | Catatan tambahan per item. |
| `status` | TEXT | NULLABLE, default `'Pending'`, CHECK `IN ('Pending', 'Cooking', 'Ready', 'Served')` | Sisa alur status KDS per-item — tidak lagi dipakai UI aktif karena fitur KDS sudah dihapus. |

### 12. Tabel: `stock_history`
Kartu log riwayat audit perubahan inventaris produk.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik log mutasi stok. |
| `store_id` | UUID | NOT NULL, FK -> `stores.id` | Kepemilikan audit per toko. |
| `product_id` | UUID | NULLABLE, FK -> `products.id` | Produk yang mengalami perubahan stok. |
| `product_name` | TEXT | NOT NULL | Nama produk terkait (snapshot). |
| `change_type` | TEXT | NOT NULL, CHECK `IN ('sale', 'manual_addition', 'manual_reduction', 'manual_adjustment')` | Jenis mutasi stok. |
| `quantity_change` | INTEGER | NOT NULL | Besaran kuantitas mutasi (+/-). |
| `old_stock` | INTEGER | NOT NULL | Jumlah stok sebelum penyesuaian. |
| `new_stock` | INTEGER | NOT NULL | Jumlah stok setelah penyesuaian. |
| `reference_id` | UUID | NULLABLE | ID referensi pendukung (mis. ID transaksi untuk penjualan). |
| `cashier_id` | UUID | NULLABLE, FK -> `users.id` | Pengguna yang melakukan perubahan stok. |
| `is_synced` | BOOLEAN | *Isar Local Only, tidak ada di skema cloud* | Status sinkronisasi audit lokal ke server. |
| `created_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu pencatatan mutasi stok. |

### 13. Tabel: `notifications`
Log notifikasi pusat pesan (in-app dan push alert).

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik notifikasi. |
| `store_id` | UUID | NULLABLE, FK -> `stores.id` | Kepemilikan notifikasi per toko. |
| `user_id` | UUID | NULLABLE, FK -> `auth.users.id` | Penerima notifikasi spesifik (bila ada). |
| `title` | TEXT | NOT NULL | Judul notifikasi. |
| `message` | TEXT | NOT NULL | Detail isi pesan notifikasi. |
| `type` | TEXT | NOT NULL, **tanpa CHECK constraint di level DB** | Tipe alert bebas-teks (mis. `'stock'`, `'transaction_void'`, `'info'`, `'broadcast'`). |
| `is_read` | BOOLEAN | NULLABLE, default `false` | Status pesan sudah dibaca oleh staf/owner. |
| `image_url` | TEXT | NULLABLE | Gambar pendukung notifikasi. |
| `metadata` | JSONB | NULLABLE, default `{}` | Informasi detail tambahan. |
| `created_at` | TIMESTAMPTZ | NULLABLE, default `now()` | Waktu terbitnya notifikasi. |

### 14. Tabel: `user_fcm_tokens`
Token Firebase Cloud Messaging per perangkat/pengguna, dipakai untuk pengiriman push notification.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik registrasi token. |
| `user_id` | UUID | NULLABLE, FK -> `users.id` | Pemilik token. |
| `fcm_token` | TEXT | NOT NULL, UNIQUE | Token FCM perangkat. |
| `device_info` | TEXT | NULLABLE | Informasi perangkat (model, OS, dsb.). |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `timezone('utc', now())` | Waktu registrasi token. |
| `updated_at` | TIMESTAMPTZ | NOT NULL, default `timezone('utc', now())` | Waktu pembaruan terakhir. |

### 15. Tabel: `smart_analytics_snapshots`
Riwayat hasil Smart Analytics (LSTM) per toko — setiap baris merepresentasikan satu kali refresh/panggilan ke server prediksi. Dipakai fitur F-05 dan `SmartAnalyticsHistoryScreen`.

| Nama Kolom | Tipe Data | Kendala | Deskripsi |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` | ID unik snapshot. |
| `store_id` | UUID | NOT NULL, FK -> `stores.id` | Toko terkait. |
| `created_by` | UUID | NULLABLE, FK -> `auth.users.id` | Pengguna yang memicu refresh analitik. |
| `business_type` | TEXT | NOT NULL, default `'Retail'` | Jenis bisnis saat snapshot diambil. |
| `store_name` | TEXT | NOT NULL, default `'Toko POS'` | Snapshot nama toko. |
| `model_used` | TEXT | NULLABLE | Nama/versi model LSTM yang dipakai. |
| `api_online` | BOOLEAN | NOT NULL, default `false` | Status server prediksi saat snapshot diambil. |
| `is_local_server` | BOOLEAN | NOT NULL, default `false` | Menandakan pemakaian server lokal (`lstmLocalPhysicalUrl`) vs Hugging Face. |
| `api_server_label` | TEXT | NOT NULL, default `'HuggingFace Space'` | Label server yang dipakai. |
| `cold_start_warning` | TEXT | NOT NULL, default `''` | Peringatan cold-start model Hugging Face. |
| `best_selling_name` | TEXT | NOT NULL, default `'Belum ada produk'` | Nama produk terlaris hasil prediksi. |
| `total_revenue` | NUMERIC | NOT NULL, default `0` | Total omzet hasil analisis. |
| `revenue_text` | TEXT | NOT NULL, default `'Rp 0'` | Format tampilan omzet siap pakai. |
| `projected_best_sellers` | JSONB | NOT NULL, default `[]`, CHECK harus array | Daftar produk terlaris hasil prediksi. |
| `pricing_recommendations` | JSONB | NOT NULL, default `[]`, CHECK harus array | Daftar rekomendasi harga/promosi. |
| `tab_data` | JSONB | NOT NULL, default `{}`, CHECK harus objek | Cache data siap-tampil untuk tab daily/weekly/monthly/custom, agar histori bisa dilihat tanpa refetch ke model. |
| `created_at` | TIMESTAMPTZ | NOT NULL, default `now()` | Waktu snapshot diambil. |

---

## Fungsi RPC (PostgreSQL Functions) yang Dipakai

Selain tabel, beberapa alur data penting dijalankan lewat pemanggilan fungsi RPC PostgreSQL dari client, bukan query `SELECT`/`INSERT` langsung:

| Fungsi RPC | Lokasi Pemanggilan | Kegunaan |
| :--- | :--- | :--- |
| `create_transaction_v4` | `lib/core/providers/sync_provider.dart` | Jalur utama sinkronisasi: mengirim transaksi offline (Isar) ke server, menjaga konsistensi stok dalam satu transaksi database. |
| `create_transaction_v3` | `lib/features/pos/providers/table_monitoring_provider.dart` | Membuat transaksi langsung (jalur non-sync terkait alur dine-in/table monitoring) — versi lebih lama dari v4. |
| `sync_pending_transaction` | `lib/features/pos/providers/table_monitoring_provider.dart` | Sinkronisasi transaksi berstatus pending terkait meja. |
| `get_sales_performance` | `lib/features/reports/providers/sales_performance_provider.dart` | Data agregat untuk layar Performa Penjualan. |
| `get_analytics` | `lib/features/reports/providers/analytics_provider.dart` | Data agregat untuk layar Laporan. |

---

## Aturan Integritas Data (Referential Integrity Constraints)

> Catatan: aturan berikut merupakan **rancangan integritas relasional berdasarkan sifat kolom FK yang teramati** (nullable vs not-null) dan pola pengelolaan data di kode aplikasi (soft-delete via `is_deleted` lokal), bukan hasil introspeksi langsung terhadap definisi `ON DELETE` aktual di setiap constraint Postgres. Untuk kepastian penuh, perlu verifikasi terpisah terhadap definisi constraint di database.

1. **Kolom FK bersifat `NULLABLE` pada mayoritas relasi turunan** (`products.store_id`, `transactions.store_id`, `transactions.table_id`, `transactions.customer_id`, `stock_history.product_id`, `notifications.store_id`, dsb.) — ini konsisten dengan pola *set-null-on-delete* atau penghapusan yang tidak berantai secara otomatis, sehingga entitas anak dapat tetap ada meski induknya dihapus, dengan referensi menjadi `NULL`.
2. **Soft delete di level lokal (Isar)**: Untuk `categories` dan `products`, aplikasi memakai flag `isDeleted`/`isSynced` di database lokal untuk menandai penghapusan sebelum benar-benar disinkronkan/dihapus di cloud — bukan `ON DELETE CASCADE` fisik di Postgres.
3. **Snapshot data historis pada `transaction_items`**: Kolom `product_name`, `product_sku`, `unit_price`, dan `cost_price` disalin (snapshot) saat transaksi terjadi, sehingga laporan transaksi historis tetap valid meskipun data produk asli di tabel `products` kemudian diubah atau dihapus — pola ini menggantikan kebutuhan constraint `RESTRICT` yang ketat pada `products -> transaction_items`.
4. **Kolom sisa fitur yang sudah dihapus dari client tetap ada di skema**: `products.preparation_area`, `transaction_items.status` (alur `Pending/Cooking/Ready/Served`), `products.discount_id` (mengarah ke tabel `discounts` yang tidak dipakai app), dan `stores.settings.features.kds` adalah artefak dari fitur yang sudah tidak aktif di UI Flutter, namun tetap eksis di skema database tanpa memengaruhi integritas data.
