# Rencana Pembatasan Fitur Berdasarkan Role

Dokumen ini merinci pembatasan akses dan fitur antara role **Admin (Owner)** dan **Kasir (Staff)** untuk aplikasi POS Mobile.

---

## 1. Definisi Role

| Role | Deskripsi |
| :--- | :--- |
| **Admin (Owner)** | Pemilik toko dengan kontrol penuh terhadap operasional, keuangan, dan pengaturan sistem. |
| **Kasir (Staff)** | Petugas operasional yang fokus pada pelayanan transaksi pelanggan di toko. |

---

## 2. Matriks Akses Fitur

| Fitur / Halaman | Admin | Kasir | Keterangan |
| :--- | :---: | :---: | :--- |
| **Dashboard (Statistik)** | Full | Limited | Kasir hanya melihat ringkasan shift/hari ini. |
| **Point of Sale (POS)** | ✅ | ✅ | Fitur utama transaksi. |
| **Riwayat Transaksi** | ✅ | ✅ | Kasir hanya bisa melihat, tidak bisa menghapus/edit. |
| **Manajemen Produk** | ✅ | ❌ | Tambah/Edit/Hapus produk & harga. |
| **Manajemen Kategori** | ✅ | ❌ | Mengatur pengelompokan produk. |
| **Laporan Keuangan** | ✅ | ❌ | Laporan laba rugi, omzet bulanan, dll. |
| **Manajemen Staf** | ✅ | ❌ | Menambah atau memberhentikan karyawan. |
| **Pengaturan Toko** | ✅ | ❌ | Mengubah nama toko, logo, dan fitur sistem. |
| **Pengaturan Printer** | ✅ | ✅ | Diperlukan kasir untuk mencetak struk. |
| **Manajemen Meja** | ✅ | ✅ | Jika fitur meja aktif, kasir perlu akses ini. |

---

## 3. Rincian Akses Per Halaman

### A. Akses Admin (Full Access)
Halaman yang **HANYA** bisa diakses oleh Admin:
- **Laporan Detail**: Analitik mendalam tentang performa bisnis.
- **Produk & Stok**: Mengelola katalog barang dan memperbarui stok masuk/keluar.
- **Kelola Toko**: Mengatur profil toko, jam operasional, dan metode pembayaran.
- **Manajemen User**: Mengelola akun kasir dan hak akses.
- **Admin Panel**: Akses ke konfigurasi sistem tingkat lanjut.

### B. Akses Kasir (Operational Access)
Halaman yang bisa diakses oleh Kasir:
- **Halaman Kasir**: Input pesanan, pilih produk, dan proses pembayaran.
- **Riwayat Harian**: Melihat daftar transaksi yang dilakukan pada hari tersebut.
- **Daftar Produk (Read-only)**: Melihat katalog tanpa bisa mengubah harga atau detail produk.
- **Pengaturan Printer**: Menghubungkan perangkat ke printer thermal Bluetooth.
- **Profil Mandiri**: Mengubah password atau informasi profil diri sendiri.

---

## 4. Batasan Tindakan (Action Restrictions)

Untuk menjaga keamanan data, beberapa tindakan di dalam halaman yang bisa diakses bersama akan tetap dibatasi:

1. **Hapus Transaksi**: Hanya Admin yang dapat menghapus atau melakukan pembatalan (void) transaksi yang sudah selesai.
2. **Diskon Khusus**: Kasir hanya bisa menerapkan diskon yang sudah ditentukan Admin. Input diskon manual (custom %) memerlukan otorisasi Admin.
3. **Ubah Harga**: Kasir tidak diperbolehkan mengubah harga produk saat transaksi berlangsung (kecuali fitur 'Open Price' diaktifkan oleh Admin).
4. **Edit Stok Manual**: Kasir tidak bisa melakukan *adjustment* stok secara manual tanpa melalui proses transaksi.

---

## 5. Implementasi Teknis (Roadmap)

- [ ] Integrasi pengecekan role pada `AppDrawer` dan `BottomNavigationBar`.
- [ ] Implementasi Guard/Middleware pada level Routing untuk mencegah akses URL manual.
- [ ] Penyesuaian UI (menyembunyikan tombol Edit/Delete untuk role Kasir).
- [ ] Penambahan kolom `role` yang konsisten di database (Supabase) dan State Management (Riverpod).

---
> [!IMPORTANT]
> Admin harus selalu memiliki minimal satu akun aktif untuk menghindari kehilangan akses kontrol terhadap toko.
