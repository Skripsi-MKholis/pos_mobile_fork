# Screen Umum

Dokumen ini berisi screen yang paling penting dan paling relevan untuk dicantumkan di laporan. Daftar ini dipilih dari alur utama aplikasi, bukan seluruh route teknis yang ada.

## Daftar Screen Utama

| No | Screen | Fungsi Singkat | Akses |
|---|---|---|---|
| 1 | `OnboardingScreen` | Halaman awal untuk pengguna baru sebelum masuk ke aplikasi. | Semua pengguna saat first run. |
| 2 | `LoginScreen` | Halaman masuk akun untuk staff atau pemilik toko. | Pengunjung yang belum login. |
| 3 | `StoreSelectionScreen` | Memilih toko aktif setelah login. | User yang sudah login. |
| 4 | `DashboardScreen` | Ringkasan performa toko, statistik, dan pintasan fitur penting. | Semua staff toko. |
| 5 | `POSScreen` | Layar utama kasir untuk mencari produk, membuat pesanan, dan memproses transaksi. | Semua staff toko. |
| 6 | `TransactionHistoryScreen` | Menampilkan riwayat transaksi yang sudah dilakukan. | Semua staff toko. |
| 7 | `ProductListScreen` | Mengelola daftar produk yang dijual. | Owner/admin. |
| 8 | `CategoryListScreen` | Mengelola kategori produk. | Owner/admin. |
| 9 | `ReportsScreen` | Menampilkan laporan penjualan, tren, dan ringkasan performa. | Owner/admin. |
| 10 | `SettingsScreen` | Pusat pengaturan aplikasi dan toko. | Semua staff toko, dengan menu tertentu khusus owner/admin. |
| 11 | `StaffManagementScreen` | Mengelola staf dan hak akses toko. | Owner/admin. |
| 12 | `ReceiptCustomizationScreen` | Mengatur tampilan struk dan informasi yang dicetak. | Owner/admin. |
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
- `ReportsScreen`, `ProductListScreen`, `StaffManagementScreen`, dan `ReceiptCustomizationScreen` lebih cocok untuk owner/admin.
- `CustomerHomeScreen`, `CustomerStoreDetailScreen`, dan `CustomerCheckoutPage` mewakili mode pelanggan yang berjalan terpisah dari mode staff.
