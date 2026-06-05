# Analisis & Rencana Penyesuaian UI — Role Pelanggan

> Dokumen ini berisi hasil analisis mendalam terhadap fitur, UI, dan kesesuaian dengan struktur database Supabase untuk role **Pelanggan** pada aplikasi Parzello POS. Fokus utama adalah penyesuaian UI untuk target **MVP**.

---

## 1. Gambaran Umum Sistem

### 1.1 Struktur Database Supabase (Relevan untuk Pelanggan)

| Tabel | Kolom Kunci | Catatan |
|---|---|---|
| `users` | `id`, `role` (Owner/Karyawan/**Pelanggan**), `full_name`, `email`, `store_id` | Role Pelanggan sudah terdefinisi |
| `store_members` | `user_id`, `store_id`, `role`, `status` (active/pending) | Pelanggan bisa jadi member toko |
| `customers` | `id`, `store_id`, `name`, `phone`, `email`, `notes` | Tabel data pelanggan (beda dari `users`) |
| `transactions` | `id`, `store_id`, `customer_id`, `status`, `payment_method`, `voucher_info` | `customer_id` FK ke `customers.id` |
| `transaction_items` | `transaction_id`, `product_id`, `quantity`, `status` (Pending/Cooking/Ready/Served) | Status item KDS |
| `products` | `id`, `store_id`, `name`, `price`, `category`, `stock_quantity`, `variants` | Produk nyata |
| `vouchers` | `id`, `store_id`, `code`, `type`, `value`, `min_purchase`, `expires_at` | Voucher sudah ada di DB |
| `reservations` | `id`, `store_id`, `table_id`, `customer_name`, `reservation_date/time`, `status` | Reservasi meja |
| `notifications` | `id`, `store_id`, `user_id`, `title`, `message`, `is_read` | Push notif |

> **Kesimpulan**: Database sudah sangat lengkap dan siap. Banyak fitur UI pelanggan yang saat ini hanya menggunakan **data mock/hardcode** padahal tabelnya sudah ada di Supabase.

---

### 1.2 Screen yang Ada di Role Pelanggan

| Screen | File | Status |
|---|---|---|
| Shell (Nav Bar) | `customer_shell_screen.dart` | ✅ Selesai |
| Beranda | `CustomerHomeScreen` | ✅ Dinamis (Terintegrasi DB & Provider) |
| Katalog Toko | `CustomerStoreDetailScreen` | ✅ Terintegrasi DB (Dinamis) |
| Keranjang | `CustomerCartScreen` | ✅ Terintegrasi Settings Toko DB |
| Checkout | `CustomerCheckoutPage` | ✅ Terintegrasi DB (transactions & transaction_items) |
| Pesanan Saya | `CustomerHistoryScreen` | ✅ Streaming Real-time DB |
| Profil | `CustomerProfileScreen` | ✅ Dinamis (userProfileProvider) |
| Scan QR | `CustomerScanScreen` | ✅ Terintegrasi (store_id & table_id) |
| Cari | `CustomerSearchScreen` | ⚠️ Data mock |
| Pilih Lokasi | `CustomerSelectLocationScreen` | ⚠️ Data mock |
| Struk Digital | `CustomerReceiptScreen` | ✅ Dinamis (Berdasarkan Data Transaksi DB) |
| Lacak Pesanan | `CustomerOrderTrackingScreen` | ✅ Real-time KDS Status |
| Loyalty | `CustomerLoyaltyScreen` | ❌ Placeholder (`_DetailPage`) |

---

## 2. Analisis Masalah UI per Halaman

### 2.1 🏠 Beranda (`CustomerHomeScreen`)

**Masalah UI:**
- **`_LocationSelector`**: Menampilkan kota (mis. "Yogyakarta") sebagai konteks pencarian toko — tetapi toko di sistem adalah entitas per `store_id`, bukan per kota. *Tidak relevan dengan model data yang ada.*
- **`_PromoCarousel`**: Banner promo **hardcode** (3 item statis). Database `vouchers` sudah ada tapi tidak digunakan.
- **`_ServiceGrid`** (2x2 grid): Isinya masuk akal tapi:
  - "Struk Digital" → mengarah ke `demo-transaction` (placeholder)
  - "Bantuan" → hanya SnackBar
- **`_RecommendedStores`**: Daftar toko **hardcode** (Kopi Kenangan, Mie Gacoan, Warmindo). Seharusnya load dari tabel `stores` yang sudah ada (90 baris).
- **FAB Scan** di tengah bawah: Bagus dan fungsional ✅

**Saran Penyesuaian UI (MVP):**
- Ganti `_LocationSelector` → **banner sambutan** dengan nama user dari `auth.currentUser` + nama toko aktif (jika sudah scan QR)
- `_PromoCarousel` → Load dari tabel `vouchers` yang aktif (`is_active = true`) milik toko yang di-scan, atau tampilkan voucher yang berlaku umum. Jika belum ada voucher, sembunyikan carousel atau tampilkan placeholder "Tidak ada promo saat ini"
- `_RecommendedStores` → Load dari tabel `stores` (`is_public = true`). Tampilkan nama toko, `business_type`, logo jika ada
- `_ServiceGrid` → Ganti "Bantuan" dengan **"Reservasi Meja"** (DB sudah ada tabel `reservations`)

---

### 2.2 🏪 Detail Toko / Katalog (`CustomerStoreDetailScreen`)

**Masalah UI:**
- **Produk hardcode**: `mockStoreProducts` adalah data fiktif. Seharusnya load dari tabel `products` berdasarkan `store_id` yang di-scan.
- **Rating "4.8"** hardcode — tidak ada kolom rating di tabel `stores`.
- **Alamat hardcode**: "Jl. Kaliurang KM 5.2..." — seharusnya dari `stores.address`.
- **Status "Buka" hardcode** — tidak ada kolom jam operasional di `stores`.
- **Kategori tab** dibuat dari data mock, seharusnya dari tabel `categories` (7 baris ada di DB).
- **Fitur Like/Favorit** hanya toggle lokal tanpa simpan ke DB.
- **Fitur Share** hanya dialog, belum ada URL publik nyata.

**Saran Penyesuaian UI (MVP):**
- Load produk dari `products` WHERE `store_id = [scanned store_id]`
- Tampilkan info toko dari `stores`: `name`, `address`, `phone`, `business_type`, `logo_url`
- Load kategori dari `categories` WHERE `store_id = [store_id]`
- Sembunyikan rating & jarak (tidak ada di DB) — atau ganti dengan `business_type`
- Hapus fitur like/favorit (tidak ada tabel pendukung di DB saat ini) — **catat untuk backend**
- Tombol "Hubungi" → gunakan `stores.phone` (sudah ada di DB)

---

### 2.3 🛒 Keranjang (`CustomerCartScreen`)

**Masalah UI:**
- **PPN 11% hardcode** — seharusnya dari `stores.settings.financial.tax_rate` dan `stores.settings.financial.tax_enabled` (sudah ada di DB!)
- **Service Fee Rp 2.000 hardcode** — dari `stores.settings.financial.service_charge_rate`
- **Tipe Pesanan** (Makan di Sini / Bawa Pulang): UI bagus, tapi **nomor meja diinput manual teks** — seharusnya setelah scan QR meja, nomor meja sudah terisi otomatis dari session
- **Catatan Pesanan** → field ada tapi belum dikirim ke DB

**Saran Penyesuaian UI (MVP):**
- Baca `tax_rate` dan `service_charge_rate` dari `stores.settings` (ambil saat toko di-scan)
- Jika sudah scan QR meja, auto-isi nomor meja dan lock (disable edit) dengan label tabel
- Tambahkan **field input voucher** (kode promo) — DB `vouchers` sudah ada
- Teruskan `notes` ke checkout payload

---

### 2.4 💳 Checkout (`CustomerCheckoutPage`)

**Masalah UI & Backend Kritis:**
- **Submit ke `customer_orders`** — tabel ini **TIDAK ADA** di database Supabase! (hanya ada tabel `transactions` dan `transaction_items`).
- UI checkout sangat minimalis dibanding desain `CustomerCartScreen` yang sudah bagus.
- Metode pembayaran: `pay_at_counter` dan `qris` — padahal `transactions.payment_method` punya: `Tunai`, `QRIS`, `Transfer`, `Pending`.
- Setelah submit berhasil, langsung `context.go('/customer/order/$orderId')` — tapi route ini menuju `CustomerOrderTrackingScreen` yang masih placeholder.

**Saran Penyesuaian UI (MVP):**
- Selaraskan desain checkout dengan `CustomerCartScreen` (gunakan `ShadCard`, warna, padding yang konsisten)
- Ubah opsi pembayaran menjadi: **"Bayar di Kasir (Tunai)"**, **"QRIS"** sesuai enum DB
- Tampilkan ringkasan produk dengan ikon seperti di cart screen
- **(Backend — catat)**: Ganti endpoint `customer_orders` → insert ke `transactions` dengan `status: 'Pending'` dan `payment_method: 'Pending'`, lalu insert `transaction_items`. Kasir yang akan mengonfirmasi pembayaran.

---

### 2.5 📋 Pesanan Saya (`CustomerHistoryScreen`)

**Masalah UI:**
- **Semua data mock** — 2 pesanan aktif + 3 riwayat semuanya hardcode
- Status pesanan yang ada: `Diproses`, `Siap Diambil`, `Selesai`, `Dibatalkan` — perlu diselaraskan dengan `transactions.status` DB: `Berhasil`, `Pending`, `Dibatalkan`
- Klik item → navigasi ke `CustomerReceiptScreen` dengan ID hardcode — placeholder
- Tombol "Pesan Menu Baru" → ke `/customer/home` ✅

**Saran Penyesuaian UI (MVP):**
- Mapping status DB → label UI yang friendly:
  - `Pending` → "Dalam Proses" (warna kuning)
  - `Berhasil` → "Selesai" (warna hijau)
  - `Dibatalkan` → "Dibatalkan" (warna merah)
- Ubah tab "Dalam Proses" = `status: Pending`, tab "Riwayat" = `status: Berhasil` atau `Dibatalkan`
- **(Backend — catat)**: Query `transactions` WHERE `customer_id = [current_customer_id]`

---

### 2.6 👤 Profil (`CustomerProfileScreen`)

**Masalah UI:**
- Header menampilkan **"Pelanggan Tamu"** dan **"CS-MEMBER-882 • Belum Terhubung"** — hardcode!
- Seharusnya menampilkan `auth.currentUser.email`, `users.full_name` dari Supabase
- Tombol **"Keluar Sesi Pelanggan"** → navigasi ke `/login` (benar ✅)
- Dialog logout: *"kembali ke halaman login staf?"* — teks tidak tepat, ini seharusnya logout pelanggan umum
- Menu "Lokasi Gerai" → memunculkan `CustomerSelectLocationScreen` (kota-based) — tidak relevan jika pelanggan sudah scan QR toko

**Saran Penyesuaian UI (MVP):**
- Tampilkan nama dan email dari `Supabase.instance.client.auth.currentUser`
- Avatar: gunakan inisial nama jika tidak ada foto (buat widget `AvatarInitials` sederhana)
- Ganti dialog logout: *"Anda akan keluar dari akun Pelanggan"*
- Ganti/hapus menu "Lokasi Gerai" → ganti dengan **"Gerai Aktif"** (tampilkan nama toko dari QR yang sudah di-scan)
- Tambahkan menu **"Reservasi Saya"** (DB sudah ada)

---

### 2.7 🔍 Pencarian (`CustomerSearchScreen`)

**Masalah UI:**
- **Data mock**: 3 toko + 5 produk fiktif
- Riwayat pencarian hanya di-state lokal (hilang saat restart)
- Klik toko → ke `CustomerStoreDetailScreen` dengan parameter hardcode (warna, jarak, dll.)

**Saran Penyesuaian UI (MVP):**
- Saat ini tetap mock dulu, tapi buat query ke `stores` (`is_public = true`) untuk hasil pencarian toko nyata
- Tambah filter: "Toko" vs "Produk"
- **(Backend — catat)**: Full-text search dengan `ilike` ke `products.name` dan `stores.name`

---

### 2.8 🧾 Struk Digital (`CustomerReceiptScreen`) — PLACEHOLDER

**Masalah UI:**
- Hanya `_DetailPage` placeholder dengan teks deskripsi
- Sama sekali tidak menampilkan data transaksi

**Saran Penyesuaian UI (MVP):**
- Buat layout struk yang menampilkan:
  - Header: Nama toko, tanggal transaksi
  - Daftar item (dari `transaction_items`)
  - Subtotal, pajak, total
  - Metode pembayaran
  - Status transaksi (badge)
- Tombol "Bagikan" dan "Download" (opsional, bisa ditunda)
- Desain referensi: lihat `receipt_customization_screen.dart` di settings Owner

---

### 2.9 📍 Lacak Pesanan (`CustomerOrderTrackingScreen`) — PLACEHOLDER

**Masalah UI:**
- Hanya `_DetailPage` placeholder
- Tidak ada tracking real-time

**Saran Penyesuaian UI (MVP):**
- Buat UI timeline sederhana dengan status:
  - ✅ Pesanan Diterima (`Pending`)
  - 🍳 Sedang Dimasak (`Cooking` dari `transaction_items.status`)
  - 🔔 Siap Diambil (`Ready`)
  - 🎉 Selesai (`Served`)
- **(Backend — catat)**: Subscribe Supabase Realtime ke `transaction_items` WHERE `transaction_id = [id]`

---

### 2.10 🎯 Scan QR (`CustomerScanScreen`)

**Status: ✅ Relatif Baik**

- Fungsional: bisa scan QR dan parse `store_name`, `table` dari URL params
- Masalah: menyimpan `store_name` (string) di `customerStoreIdProvider` — seharusnya menyimpan `store_id` (UUID) agar bisa query ke DB
- Mode "Scan Struk" → navigasi ke route yang masih placeholder

**Saran Penyesuaian UI (MVP):**
- Ganti parsing: dari `store_name` → `store_id` sebagai primary key session
- Simpan juga `table_id` di session (agar checkout auto-isi meja)
- Mode "Scan Struk" → arahkan ke `CustomerReceiptScreen` yang sudah diperbaiki

---

## 3. Ringkasan Masalah Kritis

### Tabel Tidak Ada di DB
| Endpoint yang Dipakai | Status |
|---|---|
| `customer_orders` (di `CustomerCheckoutPage`) | **TIDAK ADA** di Supabase |

> Ini adalah **bug kritis** — checkout akan gagal saat dicoba ke production.

### Inkonsistensi Data
| Masalah | Dampak |
|---|---|
| `customerStoreIdProvider` menyimpan `store_name` bukan `store_id` | Query ke DB tidak bisa dilakukan |
| `transactions.status` enum: `Berhasil/Pending/Dibatalkan` vs UI: `Selesai/Diproses/Dibatalkan` | Label tidak selaras |
| PPN 11% & biaya layanan Rp 2.000 hardcode | Tidak mengikuti setting toko dari `stores.settings` |
| `payment_method` di UI: `pay_at_counter/qris` vs DB enum: `Tunai/QRIS/Transfer/Pending` | Insert akan gagal validasi DB |

---

## 4. Rencana Penyesuaian UI (Prioritas MVP)

### Prioritas 1 — Perbaikan Kritis (Harus Sebelum Demo)

| No | Halaman | Aksi UI | Catatan |
|---|---|---|---|
| 1 | **Checkout** | Selaraskan desain dengan CartScreen (konsistensi visual) | Perbaiki `payment_method` label |
| 2 | **Profil** | Tampilkan nama/email dari auth user, bukan hardcode | Perbaiki dialog logout |
| 3 | **Shell / App Bar** | Ganti chip `activeStoreId` yang menampilkan `store_name` → nama toko yang readable | |
| 4 | **Scan QR** | Ubah provider: simpan `store_id` bukan `store_name` | Berdampak ke seluruh session |

### Prioritas 2 — Penyesuaian UI Utama (Target MVP)

| No | Halaman | Aksi UI |
|---|---|---|
| 5 | **Beranda** | Ganti `_LocationSelector` → Banner sambutan + status toko aktif |
| 6 | **Beranda** | Ganti `_RecommendedStores` hardcode → load dari `stores` (is_public=true) |
| 7 | **Beranda** | Ganti banner promo hardcode → cek `vouchers` toko aktif |
| 8 | **Detail Toko** | Tampilkan `stores.address`, `stores.phone` dari DB |
| 9 | **Detail Toko** | Load kategori dari tabel `categories` |
| 10 | **Keranjang** | Baca tax_rate dari `stores.settings` (bukan hardcode 11%) |
| 11 | **Pesanan Saya** | Mapping label status: Pending→"Dalam Proses", Berhasil→"Selesai" |

### Prioritas 3 — Pengembangan Screen Baru (MVP+)

| No | Screen Baru | Deskripsi |
|---|---|---|
| 12 | **Struk Digital** | Ganti placeholder → layout struk dari `transactions` + `transaction_items` |
| 13 | **Lacak Pesanan** | Ganti placeholder → timeline status dari `transaction_items.status` |
| 14 | **Reservasi** | Halaman buat reservasi → insert ke tabel `reservations` |

---

## 5. Catatan Backend (Untuk Fase Berikutnya)

> Hal-hal berikut memerlukan perubahan backend/database — **tidak dikerjakan di fase UI** ini.

1. **Buat tabel `customer_orders`** atau **refactor checkout** untuk insert ke `transactions` + `transaction_items` langsung (lebih direkomendasikan — selaras dengan alur Kasir).
2. **RLS Policy** untuk tabel `transactions`: Pelanggan hanya bisa baca transaksi miliknya (`customer_id = auth.uid()` atau via join ke `customers.email`).
3. **Supabase Realtime** untuk `CustomerOrderTrackingScreen`: subscribe ke perubahan `transaction_items.status`.
4. **Tabel `customers`** vs **`users`**: Saat ini pelanggan yang login via Auth (role `Pelanggan`) belum terhubung ke tabel `customers` (yang dipakai sebagai FK di `transactions`). Perlu fungsi/trigger yang membuat record `customers` saat user baru daftar dengan role Pelanggan.
5. **Fitur Favorit Toko**: Butuh tabel baru `customer_favorites` (user_id, store_id).
6. **Full-text search** produk & toko: gunakan Postgres `ilike` atau `pg_trgm` extension.
7. **Voucher redemption**: Validasi kode, cek `min_purchase`, `usage_limit`, update `used_count`.

---

## 6. Referensi File

| File | Path |
|---|---|
| Shell Screen | `lib/features/customer/presentation/customer_shell_screen.dart` |
| Screens Utama | `lib/features/customer/presentation/customer_screens.dart` |
| Checkout | `lib/features/customer/presentation/customer_checkout_page.dart` |
| Scan QR | `lib/features/customer/presentation/customer_scan_screen.dart` |
| Detail Toko | `lib/features/customer/presentation/customer_store_detail_screen.dart` |
| Session Provider | `lib/features/customer/providers/customer_session_provider.dart` |
| Order Model | `lib/features/customer/models/customer_order_model.dart` |

---

*Terakhir diperbarui: 5 Juni 2026 — Semua penyesuaian utama untuk MVP Role Pelanggan telah selesai diterapkan dan diintegrasikan dengan database Supabase*
