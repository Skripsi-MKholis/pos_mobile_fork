# Screen Umum

Dokumen ini berisi screen yang paling penting dan paling relevan untuk dicantumkan di laporan. Daftar ini dipilih dari alur utama aplikasi, bukan seluruh route teknis yang ada.

> **Direvisi 2026-07-13**: kolom "Akses" disesuaikan dengan router aktual — sejak penyesuaian RBAC, hanya `StaffManagementScreen` (dan `StoreInfoScreen`, tidak masuk daftar utama) yang benar-benar dibatasi router untuk Owner/admin. Layar lain yang sebelumnya ditandai "Owner/admin" kini dapat diakses semua staff toko.

## Daftar Screen Utama

| No | Screen | Fungsi Singkat | Akses |
|---|---|---|---|
| 1 | `OnboardingScreen` | Halaman awal untuk pengguna baru sebelum masuk ke aplikasi. | Semua pengguna saat first run. |
| 2 | `LoginScreen` | Halaman masuk akun untuk staff atau pemilik toko. | Pengunjung yang belum login. |
| 3 | `StoreSelectionScreen` | Memilih toko aktif setelah login. | User yang sudah login. |
| 4 | `DashboardScreen` | Ringkasan performa toko, statistik, dan pintasan fitur penting. | Semua staff toko. |
| 5 | `POSScreen` | Layar utama kasir untuk mencari produk, membuat pesanan, dan memproses transaksi. | Semua staff toko. |
| 6 | `TransactionHistoryScreen` | Menampilkan riwayat transaksi yang sudah dilakukan. | Semua staff toko. |
| 7 | `ProductListScreen` | Mengelola daftar produk yang dijual. | Semua staff toko — tidak lagi dibatasi router. |
| 8 | `CategoryListScreen` | Mengelola kategori produk. | Semua staff toko — tidak lagi dibatasi router. |
| 9 | `ReportsScreen` | Menampilkan laporan penjualan, tren, dan ringkasan performa. | Semua staff toko — tidak lagi dibatasi router. |
| 10 | `SettingsScreen` | Pusat pengaturan aplikasi dan toko. | Semua staff toko, dengan menu Manajemen Staf & Info Toko khusus owner/admin. |
| 11 | `StaffManagementScreen` | Mengelola staf dan hak akses toko. | Owner/admin — satu-satunya layar yang tetap diblokir router untuk non-owner. |
| 12 | `ReceiptCustomizationScreen` | Mengatur tampilan struk dan informasi yang dicetak. | Semua staff toko — tidak lagi dibatasi router. |
| 13 | `CustomerHomeScreen` | Beranda mode pelanggan untuk melihat katalog toko. | Pelanggan / pengunjung customer mode. |
| 14 | `CustomerStoreDetailScreen` | Detail toko, produk, dan aksi belanja untuk pelanggan. | Pelanggan / pengunjung customer mode. |
| 15 | `CustomerCheckoutPage` | Halaman checkout pelanggan untuk menyelesaikan pesanan. | Pelanggan / pengunjung customer mode. |

## Screen Paling Penting Untuk Laporan

Jika hanya ingin mencantumkan screen inti, daftar berikut sudah cukup mewakili alur utama aplikasi:

1. `OnboardingScreen`
2. `LoginScreen`
3. `StoreSelectionScreen`
4. `DashboardScreen`
5. `POSScreen`
6. `TransactionHistoryScreen`
7. `ProductListScreen`
8. `ReportsScreen`
9. `SettingsScreen`
10. `CustomerHomeScreen`

## Catatan

- `DashboardScreen` dan `POSScreen` adalah pusat operasional aplikasi.
- Hanya `StaffManagementScreen` (beserta `StoreInfoScreen`) yang benar-benar dibatasi router untuk owner/admin. `ReportsScreen`, `ProductListScreen`, dan `ReceiptCustomizationScreen` secara teknis dapat diakses kasir, meski secara konvensi UI lebih sering dipakai owner.
- `CustomerHomeScreen`, `CustomerStoreDetailScreen`, dan `CustomerCheckoutPage` mewakili mode pelanggan yang berjalan terpisah dari mode staff.
- Fitur Kitchen Display System (KDS), Manajemen Meja (`ManageTablesScreen`), dan Split Bill (`SplitBillScreen`) yang sempat direncanakan sebagai screen mandiri **tidak lagi eksis sebagai route terpisah** — lihat [Screen.md](Screen.md) §5 untuk detail.
