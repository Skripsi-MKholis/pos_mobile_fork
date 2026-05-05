# Rencana Detail Penyelarasan Mobile (Fase 2: Alignment & Expansion)

Dokumen ini mendetailkan implementasi teknis untuk menyelaraskan aplikasi mobile dengan fungsionalitas versi Web.

## 1. Arsitektur Navigasi & Routing (State-Persistent) [COMPLETED]
Untuk mendukung multi-tab tanpa kehilangan state, kita akan mengoptimalkan `GoRouter` dengan `StatefulShellRoute`.

- **Bottom Navigation Tab**:
  - `Tab 1: Dashboard` -> `/dashboard` (Statistik & Overview)
  - `Tab 2: Kasir` -> `/pos` (Terminal Penjualan)
  - `Tab 3: Transaksi` -> `/transactions` (Riwayat & Cetak Ulang)
  - `Tab 4: Menu` -> `/settings` (Akses ke Katalog & Konfigurasi)

- **Teknis**: Menggunakan `ShellRoute` agar `BottomNavigationBar` tetap terlihat saat berpindah antar tab utama.

---

## 2. Alur Autentikasi & Multi-Outlet (Pilih Toko) [COMPLETED]
Menangani user yang memiliki lebih dari satu toko (Owner) atau staf yang ditugaskan ke outlet tertentu.

- **Logika**:
  1. Setelah login, aplikasi mengecek jumlah toko di tabel `stores` berdasarkan `owner_id` atau tabel `staff` (untuk staf).
  2. Jika > 1 toko: Arahkan ke `StoreSelectionScreen`.
  3. Jika 1 toko: Langsung set `active_store_id` dan masuk ke Dashboard.
- **State Management**: Simpan `activeStoreProvider` (Riverpod) yang bersifat persisten menggunakan `Isar` atau `SharedPreferences`.

---

## 3. Modul Katalog & Stok (Parity Bagian C)
Menyelesaikan fitur manajemen inventaris yang belum ada.

### A. Manajemen Kategori (`/dashboard/categories`)
- **UI**: `CategoryListScreen` dengan `ShadCard` untuk setiap item.
- **Fitur**: Tambah kategori baru, Edit, dan Hapus (dengan validasi jika kategori masih digunakan produk).
- **Supabase**: Tabel `categories`.

### B. Integrasi Produk
- Memperbarui `ProductAddEditScreen` untuk menyertakan dropdown kategori (fetching data dari tabel `categories`).

---

## 4. Modul Laporan & Riwayat (Parity Bagian E)
Transformasi dari sekedar "Cek Detail" menjadi pusat data transaksi.

- **UI**: `TransactionHistoryScreen` dengan filter:
  - **Pencarian**: Berdasarkan ID Transaksi atau Nama Kasir.
  - **Rentang Tanggal**: Hari ini, 7 hari terakhir, atau kustom.
- **Fitur**: 
  - Klik item riwayat untuk melihat detail (Receipt Preview).
  - Tombol **Cetak Ulang Struk** langsung dari riwayat.

---

## 5. Modul Pengaturan & Bantuan (Parity Bagian F)
Mengkonsolidasikan semua konfigurasi ke dalam satu pusat.

### A. Profil Saya (`/settings/profile`)
- Menampilkan Nama, Email, dan Role (Owner/Staff).
- Fitur Ganti Password (via Supabase Auth).

### B. Informasi Toko (`/settings/store`)
- Edit Nama Toko, Alamat, dan Nomor Telepon Toko.
- Pengaturan Header/Footer struk fisik.

### C. Pusat Bantuan & Logout
- Link dokumentasi/bantuan.
- Logout dengan pembersihan state lokal.

---

## 6. Checklist Teknis & Komponen UI
Setiap halaman baru wajib mengikuti standar:
- **Header**: `AppBar` transparan dengan judul tebal.
- **Latar Belakang**: `theme.colorScheme.background` (Stone White).
- **Input**: `ShadInput` dengan label yang jelas.
- **Button**: `ShadButton` (Primary untuk aksi positif, Outline/Ghost untuk sekunder).
- **Feedback**: `ShadToaster` untuk sukses/gagal operasi Supabase.

---
*Dibuat oleh: Antigravity AI*
*Status: Ready for Execution*
