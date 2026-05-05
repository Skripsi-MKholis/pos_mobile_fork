# Daftar Halaman & Sidebar Parzello POS

Dokumen ini merangkum seluruh rute halaman dan struktur navigasi (sidebar) yang tersedia berdasarkan peran pengguna (Role).

## 1. Halaman Publik (Akses Tanpa Login)
Halaman yang dapat diakses oleh siapa saja sebelum melakukan autentikasi.

- **Beranda (Landing Page)**: `/`
- **Login**: `/auth/login` (Tersedia link dari `/login`)
- **Register**: `/auth/register`
- **Lupa Password**: `/auth/forgot-password` (Asumsi standar auth flow)
- **Kebijakan Privasi**: `/privacy`
- **Syarat & Ketentuan**: `/terms`

---

## 2. Halaman Alur Autentikasi (Setelah Login)
Halaman transisi setelah login berhasil sebelum masuk ke dashboard utama.

- **Pilih Toko**: `/select-store` (Memilih toko yang ingin dikelola jika user punya banyak toko)
- **Setup Toko**: `/setup` (Inisialisasi data toko baru jika belum ada)
- **Setup Password**: `/auth/setup-password` (Khusus untuk user baru dari undangan staf)

---

## 3. Dashboard Toko (Role: Owner & Staff)
Navigasi utama dikelola melalui `AppSidebar`. Tampilan sidebar dinamis berdasarkan Role dan Fitur yang aktif.

### A. Bagian: Analytics
- **Dashboard**: `/dashboard`
  - *Isi: Ringkasan penjualan hari ini, grafik pendapatan, produk terlaris.*

### B. Bagian: Operasional Kasir
- **Kasir (POS)**: `/dashboard/cashier`
- **Manajemen Meja**: `/dashboard/tables` (Hanya jika fitur `tables` aktif)
- **Konfigurasi Meja**: `/dashboard/settings/tables` (Hanya jika fitur `tables` aktif)
- **Reservasi**: `/dashboard/reservations` (Hanya jika fitur `reservations` aktif)
- **Dapur (KDS)**: `/dashboard/kds` (Hanya jika fitur `kds` aktif)

### C. Bagian: Katalog & Stok (Akses: Owner Only)
- **Produk**: `/dashboard/products`
- **Kategori**: `/dashboard/categories`
- **Program Diskon**: `/dashboard/promotions` (Hanya jika fitur `promotions` aktif)

### D. Bagian: Pelanggan & Promo
- **Pelanggan**: `/dashboard/customers` (Hanya jika fitur `customers` aktif)
- **Voucher Belanja**: `/dashboard/promotions?tab=vouchers` (Hanya jika fitur `promotions` aktif)
- **Broadcast Area**: `/dashboard/broadcast`
- **Notifikasi**: `/dashboard/notifications`

### E. Bagian: Laporan & Audit
- **Riwayat Transaksi**: `/dashboard/transactions` (Akses: Owner & Staff)
- **Laporan Laba Rugi**: `/dashboard/reports/profit` (Akses: Owner Only)

### F. Pengaturan & Bantuan (Secondary Navigation)
- **Profil Saya**: `/dashboard/settings/profile` (Akses: Owner & Staff)
- **Bantuan**: `/dashboard/settings/help` (Akses: Owner & Staff)
- **Informasi Toko**: `/dashboard/settings/store` (Akses: Owner Only)
- **Modul & Fitur**: `/dashboard/settings/modules` (Akses: Owner Only)
- **Cetak & Struk**: `/dashboard/settings/receipt` (Akses: Owner Only)
- **Akses Staf**: `/dashboard/settings/staff` (Akses: Owner Only)
- **Langganan**: `/dashboard/settings/billing` (Akses: Owner Only)

---

## 4. Panel Admin (Role: Super Admin)
Navigasi khusus untuk pengelola platform melalui `AdminSidebar` di rute `/admin`.

### A. Bagian: Management
- **Overview**: `/admin` (Statistik global platform)
- **Manajemen Toko**: `/admin/stores` (Daftar seluruh merchant)
- **Manajemen User**: `/admin/users` (Daftar seluruh pengguna sistem)
- **Paket Langganan**: `/admin/plans` (Pengaturan pricing & tiering)
- **Analitik Global**: `/admin/analytics` (Laporan pertumbuhan bisnis)

### B. Bagian: System
- **System Settings**: `/admin/settings` (Konfigurasi teknis platform)
- **Audit Logs**: `/admin/audit` (Log aktivitas sistem untuk keamanan)

---
*Catatan: Hak akses (RBAC) dikontrol melalui middleware dan pengecekan server-side pada setiap rute.*
