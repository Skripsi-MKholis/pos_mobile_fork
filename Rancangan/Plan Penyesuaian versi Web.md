# Plan Penyelarasan Halaman Mobile (Versi Web Alignment)

Dokumen ini berisi rencana strategis untuk menyelaraskan fitur, struktur halaman, dan alur kerja aplikasi Mobile POS dengan standar yang telah ditetapkan pada versi Web.

## 1. Analisis Kesenjangan (Gap Analysis)
Berdasarkan dokumen `Versi Web/Halaman.md`, berikut adalah elemen yang perlu ditambahkan atau disesuaikan pada aplikasi Mobile:

| Bagian | Status di Mobile | Tindakan |
| :--- | :--- | :--- |
| **Auth Flow** | Langsung ke Dashboard | Tambahkan halaman **Pilih Toko** setelah Login. |
| **Katalog** | Hanya Produk | Tambahkan manajemen **Kategori Produk**. |
| **Laporan** | Hanya Struk Terakhir | Tambahkan halaman **Riwayat Transaksi** lengkap. |
| **Pengaturan** | Tersebar/Hardcoded | Gabungkan ke dalam satu menu **Pengaturan & Profil**. |
| **UI/UX** | Custom/Basic | Optimasi menggunakan **Shadcn UI (Stone/Lime)** secara menyeluruh. |

---

## 2. Struktur Navigasi Baru (Mobile)
Aplikasi akan menggunakan **Bottom Navigation Bar** dengan 4 tab utama:

1.  **Dashboard**: Ringkasan Analytics (Penjualan, Produk Terlaris).
2.  **Kasir (POS)**: Terminal transaksi utama.
3.  **Transaksi**: Riwayat transaksi, cetak ulang struk, dan filter tanggal.
4.  **Menu**: Akses ke Katalog (Produk/Kategori), Pengaturan Toko, dan Profil.

---

## 3. Rencana Implementasi Bertahap

### Tahap 1: Restrukturisasi Navigasi & Routing
- [x] Implementasi `BottomNavigationBar` baru di `dashboard_screen.dart`.
- [x] Penambahan rute di `router.dart` untuk Kategori, Riwayat Transaksi, dan Settings.

### Tahap 2: Manajemen Katalog (Alignment Bagian C)
- [ ] Pembuatan `CategoryListScreen` (CRUD Kategori).
- [ ] Integrasi Produk dengan Kategori yang dipilih.

### Tahap 3: Riwayat Transaksi & Laporan (Alignment Bagian E)
- [ ] Pembuatan `TransactionHistoryScreen` dengan filter pencarian dan tanggal.
- [ ] Fitur cetak ulang struk dari riwayat transaksi.

### Tahap 4: Menu Pengaturan & Profil (Alignment Bagian F)
- [ ] Pembuatan `SettingsScreen` sebagai hub menu.
- [ ] Implementasi `ProfileScreen` (Informasi Akun User).
- [ ] Implementasi `StoreInfoScreen` (Informasi Detail Toko/Merchant).

### Tahap 5: Alur Multi-Outlet (Alignment Bagian 2)
- [ ] Pembuatan `StoreSelectionScreen`.
- [ ] Logika penyimpanan `active_store_id` di state management (Riverpod).

---

## 4. Standar Desain (Look & Feel)
- Seluruh halaman wajib menggunakan skema warna **Stone & Lime**.
- Latar belakang halaman menggunakan `theme.colorScheme.background`.
- Penggunaan komponen Shadcn (Button, Card, Input, Toast) secara konsisten.

---
*Dibuat oleh: Antigravity AI*
*Tanggal: 5 Mei 2026*
