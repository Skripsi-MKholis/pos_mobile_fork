# Rencana Implementasi Fitur Role "Pelanggan" (Customer-Facing)

Dokumen ini merinci perencanaan, arsitektur halaman, skema data, dan peta jalan (roadmap) untuk menambahkan **Role Pelanggan** pada aplikasi **Parzello POS Mobile**. Role ini memungkinkan pelanggan toko berinteraksi langsung dengan sistem POS melalui antarmuka khusus yang terpisah dari role Kasir dan Admin.

---

## 1. Latar Belakang & Visi

Saat ini aplikasi Parzello POS melayani dua role internal: **Admin (Owner)** dan **Kasir (Staff)**. Namun belum ada antarmuka bagi **pelanggan akhir** sebagai pengguna. Menambahkan role **Pelanggan** akan mengubah POS dari sistem backend-only menjadi ekosistem O2O (Online-to-Offline) yang lengkap.

**Nilai yang diberikan:**
- Pelanggan dapat melihat menu digital, memesan, dan melacak pesanan secara mandiri.
- Toko mendapatkan data perilaku pelanggan (repeat purchase, preferensi produk) yang dapat dimanfaatkan untuk AI Analytics.
- Mengurangi antrian kasir melalui fitur self-order (QR-based ordering).

---

## 2. Definisi Role & Matriks Akses

| Role          | Akses Ke                           | Deskripsi                                             |
| :------------ | :--------------------------------- | :---------------------------------------------------- |
| **Admin**     | Semua fitur + manajemen toko       | Pemilik toko dengan kontrol penuh.                    |
| **Kasir**     | POS, Riwayat, Printer, Profil      | Staf operasional transaksi harian.                    |
| **Pelanggan** | Halaman Pelanggan (mode terbatas)  | Pembeli yang berinteraksi via app atau QR Code toko.  |

### Cara Pelanggan Mengakses Aplikasi

Pelanggan dapat mengakses antarmuka mereka melalui **tiga jalur**:

1. **QR Code Scan di Meja / Kasir** → Membuka halaman WebView atau deep-link ke mode Pelanggan tanpa login.
2. **Login Akun Pelanggan** → Daftar/login dengan email/Google untuk akses penuh (riwayat, poin loyalitas, dll).
3. **Mode Tamu (Guest)** → Akses terbatas: hanya bisa melihat menu dan melakukan pemesanan tanpa menyimpan riwayat.

---

## 3. Daftar Halaman & Fitur Role Pelanggan

### 🏠 Halaman Utama (Customer Home)
**Rute:** `/customer/home`

Halaman utama setelah pelanggan masuk ke mode Pelanggan. Menampilkan identitas toko dan navigasi utama.

**Konten:**
- **Header Toko**: Logo, nama toko, alamat, dan jam operasional.
- **Tombol Navigasi Cepat**: Kartu aksi menuju Menu Digital, Pesanan Aktif, Riwayat Belanja, dan Program Loyalitas.
- **Banner Promosi**: Menampilkan promo/diskon aktif yang dikonfigurasi oleh Admin (terintegrasi dengan Smart Pricing AI).
- **Info Antrean** *(Opsional F&B)*: Estimasi waktu tunggu antrian jika fitur meja/antrian aktif.

---

### 🍽️ Halaman Menu Digital (Digital Catalog)
**Rute:** `/customer/menu`

Inti dari pengalaman pelanggan. Menampilkan katalog produk dalam format yang ramah pelanggan (bukan tampilan kasir).

**Konten:**
- **Filter Kategori**: Chip horizontal untuk filter cepat per kategori produk.
- **Grid/List Produk**: Tampilan kartu produk dengan foto, nama, harga, dan status ketersediaan stok.
- **Pencarian Produk**: Search bar dengan debouncing untuk menemukan produk secara instan.
- **Detail Produk (Bottom Sheet)**: Tap produk untuk melihat deskripsi lengkap, varian (jika ada), dan tombol "Tambah ke Keranjang".
- **Badge Produk**: Label "Habis", "Terlaris", atau "Promo" sesuai status produk.

> [!NOTE]
> Data produk diambil dari tabel `public.products` yang sama dengan data Kasir. Pelanggan hanya bisa **membaca** data ini (read-only via RLS Supabase).

---

### 🛒 Halaman Keranjang Belanja (Customer Cart)
**Rute:** `/customer/cart`

Pelanggan merangkai pesanan mereka sebelum melakukan checkout. Terpisah dari keranjang kasir internal.

**Konten:**
- **Daftar Item**: Produk yang ditambahkan, lengkap dengan tombol tambah/kurang jumlah.
- **Ringkasan Harga**: Subtotal, diskon (jika ada kode promo), pajak, dan total akhir.
- **Input Kode Voucher/Promo**: Field untuk memasukkan kode diskon.
- **Catatan Pesanan**: Field opsional untuk catatan khusus ke dapur/kasir (misal: "Tanpa bawang").
- **Tombol Checkout**: Mengirimkan pesanan ke sistem POS kasir.

---

### ✅ Halaman Konfirmasi & Pembayaran (Checkout)
**Rute:** `/customer/checkout`

Pelanggan memilih metode pembayaran dan mengkonfirmasi pesanan.

**Konten:**
- **Ringkasan Pesanan Final**: Daftar item dan total yang akan dibayar.
- **Pilih Metode Pembayaran**: QRIS, Transfer Bank, atau Bayar di Kasir (Pay at Counter).
- **Nomor Meja / Nama** *(Opsional)*: Input nomor meja atau nama pemesan untuk identifikasi.
- **Tombol Konfirmasi Pesanan**: Membuat order baru di sistem dan mengirim notifikasi ke kasir.

> [!IMPORTANT]
> Pesanan dari pelanggan akan muncul sebagai **pesanan pending** di layar Kasir (`pos_screen.dart`) dan notifikasi push ke perangkat kasir/admin. Kasir mengkonfirmasi dan memproses pembayaran.

---

### 📦 Halaman Status Pesanan (Order Tracking)
**Rute:** `/customer/order/:orderId`

Pelanggan dapat melacak status pesanan mereka secara real-time.

**Konten:**
- **Indikator Status Real-time**: Stepper visual dengan tahapan:
  `Pesanan Diterima` → `Sedang Diproses` → `Siap Diambil / Dikirim` → `Selesai`
- **Detail Pesanan**: Daftar item yang dipesan dan total.
- **Estimasi Waktu**: Perkiraan waktu pesanan siap (opsional, diisi kasir/admin).
- **Tombol Batalkan**: Tersedia selama status masih "Pesanan Diterima" (belum diproses).

> [!NOTE]
> Status pesanan disinkronisasi menggunakan **Supabase Realtime** sehingga pelanggan melihat pembaruan status secara instan tanpa perlu refresh manual.

---

### 🧾 Halaman Struk Digital (Digital Receipt)
**Rute:** `/customer/receipt/:transactionId`

Versi struk yang dioptimalkan untuk pelanggan (dapat diakses via QR Code pada struk fisik).

**Konten:**
- **Detail Transaksi**: Nomor order, tanggal, kasir, dan metode pembayaran.
- **Rincian Item**: Daftar produk, kuantitas, harga satuan, dan subtotal.
- **Total & Kembalian**: Ringkasan pembayaran.
- **QR Code Validasi**: Kode unik untuk verifikasi keaslian struk.
- **Tombol Simpan/Bagikan**: Unduh sebagai gambar atau bagikan via WhatsApp.
- **Tombol Rating & Ulasan**: CTA untuk memberikan penilaian pengalaman belanja.

---

### ⭐ Halaman Program Loyalitas & Poin (Loyalty Program)
**Rute:** `/customer/loyalty`

Fitur gamifikasi untuk mendorong pelanggan kembali berbelanja. Terintegrasi dengan data transaksi.

**Konten:**
- **Saldo Poin Aktif**: Total poin yang dimiliki pelanggan dengan representasi visual (progress bar menuju reward berikutnya).
- **Tier/Level Keanggotaan**: Bronze → Silver → Gold → Platinum berdasarkan total belanja kumulatif.
- **Riwayat Perolehan Poin**: Log poin masuk dan keluar per transaksi.
- **Katalog Reward**: Daftar hadiah/diskon yang bisa ditukarkan dengan poin.
- **Tombol Tukar Poin**: Menghasilkan kode voucher yang bisa digunakan di transaksi berikutnya.

---

### 📜 Halaman Riwayat Transaksi Pelanggan (Purchase History)
**Rute:** `/customer/history`

Pelanggan melihat seluruh riwayat pembelian mereka di toko tersebut (hanya tersedia untuk akun yang login).

**Konten:**
- **Daftar Transaksi**: Kartu riwayat berisi tanggal, total, dan jumlah item per transaksi.
- **Filter Tanggal**: Filter transaksi berdasarkan rentang waktu (7 hari, 1 bulan, dll).
- **Tap untuk Detail**: Membuka struk digital dari transaksi yang dipilih.
- **Tombol Pesan Ulang (Reorder)**: Menambahkan semua item dari transaksi lama ke keranjang baru dengan satu klik.

---

### 👤 Halaman Profil Pelanggan (Customer Profile)
**Rute:** `/customer/profile`

Manajemen akun pribadi pelanggan.

**Konten:**
- **Foto & Nama Profil**: Dapat diubah oleh pelanggan.
- **Informasi Akun**: Email dan nomor telepon.
- **Preferensi Notifikasi**: Mengatur apakah ingin menerima notifikasi promo dari toko.
- **Daftar Alamat** *(Opsional untuk delivery)*: Simpan alamat pengiriman favorit.
- **Tombol Logout / Ganti Akun**: Keluar dari akun pelanggan.

---

### 🔔 Halaman Notifikasi Pelanggan (Customer Notifications)
**Rute:** `/customer/notifications`

Pusat notifikasi khusus pelanggan yang terpisah dari notifikasi internal kasir.

**Konten:**
- **Notifikasi Transaksional**: "Pesanan #1234 sudah siap diambil!", "Pembayaran berhasil dikonfirmasi".
- **Notifikasi Promo**: "Promo Flash Sale 20% untuk Kopi Susu berlaku hari ini!".
- **Notifikasi Loyalitas**: "Selamat! Kamu mendapatkan 50 poin dari transaksi terakhir".
- Tandai Sudah Dibaca & Hapus Semua.

---

## 4. Arsitektur Teknis

### A. Pemisahan Role di Router (GoRouter)

Pelanggan akan diarahkan ke shell navigasi yang berbeda dari kasir/admin:

```
/ (root)
├── /login              → Auth Screen (pilih mode: Staf / Pelanggan)
├── /customer/          → CustomerShell (bottom nav khusus pelanggan)
│   ├── home            → CustomerHomeScreen
│   ├── menu            → CustomerMenuScreen
│   ├── cart            → CustomerCartScreen
│   ├── checkout        → CustomerCheckoutScreen
│   ├── order/:id       → CustomerOrderTrackingScreen
│   ├── receipt/:id     → CustomerReceiptScreen
│   ├── loyalty         → CustomerLoyaltyScreen
│   ├── history         → CustomerHistoryScreen
│   ├── profile         → CustomerProfileScreen
│   └── notifications   → CustomerNotificationsScreen
└── /staff/             → StaffShell (bottom nav kasir/admin) [EXISTING]
```

### B. Bottom Navigation Bar Pelanggan

```
[🏠 Beranda] [🍽️ Menu] [🛒 Keranjang] [📜 Riwayat] [👤 Profil]
```

### C. Skema Database Supabase (Tabel Baru)

```sql
-- 1. Tabel profil pelanggan
CREATE TABLE public.customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    display_name TEXT,
    phone_number TEXT,
    avatar_url TEXT,
    loyalty_points INTEGER DEFAULT 0,
    loyalty_tier VARCHAR(20) DEFAULT 'bronze', -- bronze, silver, gold, platinum
    total_spent NUMERIC(12, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabel pesanan pelanggan (customer orders)
CREATE TABLE public.customer_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'pending',
    -- Status: pending, confirmed, processing, ready, completed, cancelled
    table_number TEXT,
    customer_name TEXT,
    notes TEXT,
    items JSONB NOT NULL,              -- Snapshot item pesanan
    subtotal NUMERIC(12, 2) NOT NULL,
    discount_amount NUMERIC(12, 2) DEFAULT 0,
    tax_amount NUMERIC(12, 2) DEFAULT 0,
    total_amount NUMERIC(12, 2) NOT NULL,
    payment_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Tabel riwayat poin loyalitas
CREATE TABLE public.loyalty_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.customer_orders(id) ON DELETE SET NULL,
    type VARCHAR(10) NOT NULL, -- 'earn', 'redeem'
    points INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Pengaturan program loyalitas per toko
CREATE TABLE public.loyalty_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE UNIQUE,
    is_enabled BOOLEAN DEFAULT FALSE,
    points_per_amount NUMERIC(5, 2) DEFAULT 1.0, -- 1 poin per Rp 1.000
    silver_threshold NUMERIC(12, 2) DEFAULT 500000,
    gold_threshold NUMERIC(12, 2) DEFAULT 2000000,
    platinum_threshold NUMERIC(12, 2) DEFAULT 10000000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### D. Row Level Security (RLS)

```sql
-- Pelanggan hanya bisa melihat/mengubah data dirinya sendiri
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Customers can view own profile"
    ON public.customers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Customers can update own profile"
    ON public.customers FOR UPDATE USING (auth.uid() = user_id);

-- Pelanggan bisa membuat pesanan baru
ALTER TABLE public.customer_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Customers can create orders"
    ON public.customer_orders FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "Customers can view own orders"
    ON public.customer_orders FOR SELECT
    USING (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()));

-- Admin & Kasir bisa melihat semua pesanan di toko mereka
CREATE POLICY "Staff can view store orders"
    ON public.customer_orders FOR ALL
    USING (store_id IN (SELECT store_id FROM public.store_members WHERE user_id = auth.uid()));
```

### E. Realtime Order Status

Status pesanan disinkronisasi menggunakan **Supabase Realtime**:
- **Kasir** mendapat notifikasi pesanan masuk baru (INSERT di `customer_orders`).
- **Pelanggan** mendapat update status real-time (UPDATE di `customer_orders`).

---

## 5. Peta Jalan Implementasi (Milestone)

### 📋 MILESTONE 1: Infrastruktur Database & Auth Pelanggan
**Estimasi: 3-4 hari**

- [x] Buat migrasi SQL untuk tabel `customers`, `customer_orders`, `loyalty_transactions`, dan `loyalty_settings`.
- [x] Aktifkan RLS dan buat seluruh policy keamanan untuk role pelanggan.
- [x] Aktifkan Supabase Realtime untuk tabel `customer_orders` (channel per `store_id`).
- [x] Tambahkan opsi login "Sebagai Pelanggan" di halaman Auth aplikasi, dengan entry point langsung ke mode pelanggan melalui `/customer/home`.
- [x] Buat model Dart: `CustomerModel`, `CustomerOrderModel`, `LoyaltyTransactionModel`.

---

### 📋 MILESTONE 2: Navigasi & Shell Pelanggan
**Estimasi: 2-3 hari**

- [x] Buat `CustomerShellScreen` dengan **Bottom Navigation Bar** 5 tab: Beranda, Menu, Keranjang, Riwayat, Profil.
- [x] Daftarkan seluruh rute `/customer/*` di GoRouter dengan guard: hanya bisa diakses jika login sebagai Pelanggan atau mode Tamu.
- [x] Buat `CustomerHomeScreen` (Halaman Utama) dengan header toko, navigasi cepat, dan banner promo.
- [x] Implementasikan navigasi **mode Tamu via QR Code** (scan QR → buka `/customer/home?store_id=xxx` tanpa login).

---

### 📋 MILESTONE 3: Menu Digital & Keranjang Belanja
**Estimasi: 4-5 hari**

- [ ] Buat `CustomerMenuScreen`:
  - Filter kategori chip horizontal.
  - Grid produk dengan foto, nama, harga, dan badge status.
  - Pencarian produk dengan debouncing.
  - Bottom sheet detail produk + tombol "Tambah ke Keranjang".
- [x] Buat `CustomerCartProvider` (Riverpod) untuk state management keranjang pelanggan yang terpisah dari `cartProvider` kasir.
- [ ] Buat `CustomerCartScreen`:
  - Daftar item + kontrol kuantitas.
  - Input kode voucher.
  - Field catatan pesanan.
  - Ringkasan harga dan tombol Checkout.

---

### 📋 MILESTONE 4: Checkout & Tracking Pesanan
**Estimasi: 3-4 hari**

- [ ] Buat `CustomerCheckoutScreen`:
  - Pilihan metode pembayaran (QRIS, Bayar di Kasir).
  - Input nama/nomor meja.
  - Konfirmasi pesanan → insert ke `customer_orders` dengan status `pending`.
  - Push notifikasi ke kasir via FCM bahwa ada pesanan baru masuk.
- [ ] Buat `CustomerOrderTrackingScreen`:
  - Stepper visual status pesanan.
  - Subscribe ke Supabase Realtime channel untuk update status otomatis.
  - Tombol Batalkan (hanya saat status `pending`).
- [ ] **Integrasi di sisi Kasir**: Tambahkan tab/badge "Pesanan Masuk" di `pos_screen.dart` untuk melihat dan mengkonfirmasi pesanan dari pelanggan.

---

### 📋 MILESTONE 5: Struk Digital & Riwayat Pembelian
**Estimasi: 2-3 hari**

- [ ] Buat `CustomerReceiptScreen` (versi customer dari `receipt_screen.dart`):
  - Tampilan struk yang dioptimalkan untuk pelanggan.
  - QR Code validasi struk.
  - Tombol simpan gambar ke galeri dan bagikan via WhatsApp.
  - Widget rating & ulasan bintang (1-5) untuk feedback toko.
- [ ] Buat `CustomerHistoryScreen`:
  - Daftar transaksi terdahulu dengan filter tanggal.
  - Tap item untuk membuka struk digital.
  - Tombol **"Pesan Ulang"** yang mengisi ulang keranjang dengan item dari transaksi sebelumnya.

---

### 📋 MILESTONE 6: Program Loyalitas
**Estimasi: 3-5 hari**

- [ ] Buat `CustomerLoyaltyScreen`:
  - Tampilan saldo poin dengan animasi counter.
  - Progress bar menuju tier berikutnya.
  - Riwayat perolehan dan penukaran poin.
  - Katalog reward yang bisa ditukar.
- [ ] Buat Supabase Database Function untuk kalkulasi poin otomatis setiap transaksi selesai:
  ```sql
  CREATE FUNCTION award_loyalty_points() RETURNS TRIGGER AS $$ ... $$;
  ```
- [ ] Buat mekanisme penukaran poin → generate kode voucher diskon.
- [ ] Tambahkan pengaturan Program Loyalitas di halaman Pengaturan Toko (Admin).

---

### 📋 MILESTONE 7: Notifikasi & Profil Pelanggan
**Estimasi: 2-3 hari**

- [ ] Buat `CustomerProfileScreen`: Edit nama, foto, nomor telepon, dan preferensi notifikasi.
- [ ] Buat `CustomerNotificationsScreen`: Daftar notifikasi transaksional dan promosi khusus pelanggan.
- [ ] Integrasikan FCM token untuk akun pelanggan agar menerima notifikasi push:
  - Status pesanan berubah.
  - Promo/diskon dari toko.
  - Poin loyalitas masuk.
- [ ] Buat Supabase Edge Function `notify-customer` untuk mengirim notifikasi broadcast ke pelanggan toko tertentu.

---

## 6. Matriks Prioritas Fitur

| Halaman / Fitur              | Prioritas | Kompleksitas | Milestone |
| :--------------------------- | :-------: | :----------: | :-------: |
| Customer Home                | 🔴 Tinggi  | Rendah       | M2        |
| Menu Digital & Katalog       | 🔴 Tinggi  | Menengah     | M3        |
| Keranjang Belanja            | 🔴 Tinggi  | Menengah     | M3        |
| Checkout & Pembayaran        | 🔴 Tinggi  | Tinggi       | M4        |
| Tracking Status Pesanan      | 🔴 Tinggi  | Tinggi       | M4        |
| Struk Digital Pelanggan      | 🟡 Sedang  | Rendah       | M5        |
| Riwayat Pembelian            | 🟡 Sedang  | Menengah     | M5        |
| Profil Pelanggan             | 🟡 Sedang  | Rendah       | M7        |
| Notifikasi Pelanggan         | 🟡 Sedang  | Menengah     | M7        |
| Program Loyalitas & Poin     | 🟢 Rendah  | Tinggi       | M6        |
| Mode Tamu (QR tanpa login)   | 🟢 Rendah  | Menengah     | M2        |

---

## 7. Integrasi dengan Fitur Existing

| Fitur Existing                      | Integrasi dengan Role Pelanggan                                                          |
| :---------------------------------- | :--------------------------------------------------------------------------------------- |
| **Notifikasi (FCM)**                | Pelanggan menerima push notification status pesanan & promo dari toko.                   |
| **AI Smart Analytics**              | Data pesanan pelanggan memperkaya dataset untuk prediksi best-seller dan traffic.        |
| **Riwayat Transaksi (Kasir)**       | Transaksi dari pesanan pelanggan terkonversi menjadi entri di riwayat transaksi kasir.  |
| **Manajemen Produk**                | Katalog produk yang dikelola Admin/Kasir tampil otomatis di menu digital pelanggan.     |
| **Struk Digital (Receipt Screen)**  | Pelanggan mendapat versi struk yang bisa diakses mandiri via link/QR Code.              |
| **Pengaturan Toko**                 | Admin mengkonfigurasi program loyalitas dan tampilan menu pelanggan dari halaman ini.   |
| **Offline Sync**                    | Keranjang pelanggan disimpan lokal (Isar) agar tidak hilang jika koneksi terputus.     |

---

> [!IMPORTANT]
> **Keamanan Data**: Pelanggan **tidak boleh** dapat mengakses data transaksi pelanggan lain, data stok, laporan keuangan, atau pengaturan toko. Semua akses dikontrol ketat via **Row Level Security (RLS)** Supabase berdasarkan `user_id` dan `store_id`.

> [!TIP]
> Untuk MVP (Minimum Viable Product) dalam konteks skripsi, fokuskan pada **Milestone 1-5** (infrastruktur, menu, keranjang, checkout, tracking, struk). Milestone 6 (Loyalitas) dan 7 (Notifikasi Pelanggan) dapat menjadi fitur tambahan atau pengembangan lanjutan.

> [!NOTE]
> **Penamaan Konsisten**: Gunakan prefix `customer_` untuk semua file Dart baru terkait fitur ini (contoh: `customer_home_screen.dart`, `customer_cart_provider.dart`) agar mudah dibedakan dari komponen kasir/admin yang sudah ada.
