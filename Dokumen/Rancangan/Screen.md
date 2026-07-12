# Screen Aplikasi

Dokumen ini merangkum layar yang ada di aplikasi berdasarkan `lib/core/router/router.dart`, layar shell utama, dan beberapa layar helper yang dipakai langsung dari kode.

> **Direvisi 2026-07-13**: disesuaikan dengan router aktual. Beberapa layar pada versi dokumen sebelumnya (`KDSScreen`, `ManageTablesScreen`, `SplitBillScreen`, `TableMonitoringScreen` sebagai screen mandiri, `BarcodeScannerScreen`, `KosongPage`) **tidak lagi ada di kode** — fitur KDS telah dihapus total (commit *"Delete KDS Feature"*), sementara split bill dan status meja kini menjadi logika terintegrasi di dalam `pos_screen.dart`, `cart_detail_sheet.dart`, dan `payment_screen.dart`, bukan route/screen terpisah. RBAC juga telah dilonggarkan signifikan (commit *"Penyesuaian Fitur Role Kasir"*) — lihat catatan akses di bagian akhir dokumen.

## Ringkasan

- Total entry route yang didokumentasikan: 50
- Shell wrapper: 2
- Rute yang dibatasi router untuk non-owner: **hanya 2** (`/staff-management`, `/store-info`)

## 1. Layar Publik / Auth

| No | Route | Screen | Akses |
|---|---|---|---|
| 1 | `/onboarding` | `OnboardingScreen` | Semua pengunjung saat first run. |
| 2 | `/login` | `LoginScreen` | Pengunjung yang belum login. |
| 3 | `/register` | `RegisterScreen` | Pengunjung yang belum login. |
| 4 | `/forgot-password` | `ForgotPasswordScreen` | Pengunjung yang belum login. |
| 5 | `/confirm-email` | Layar konfirmasi email | Pengunjung yang baru mendaftar, menunggu verifikasi email. |
| 6 | `/setup-password` | `SetupPasswordScreen` | Pengunjung yang sedang menyelesaikan setup/reset password. |
| 7 | `/select-store` | `StoreSelectionScreen` | User yang sudah login tetapi belum memilih toko aktif. |
| 8 | `/create-store` | `CreateStoreScreen` | User yang sudah login tetapi belum punya toko aktif. |

## 2. Layar Pelanggan

Semua route `"/customer/*"` dibuka tanpa login staff. Ini adalah mode katalog/pembelian mandiri untuk pelanggan (self-order).

| No | Route | Screen | Akses |
|---|---|---|---|
| 9 | `/customer` | Shell entry point customer mode | Pelanggan / pengunjung customer mode. |
| 10 | `/customer/home` | `CustomerHomeScreen` | Pelanggan / pengunjung customer mode. |
| 11 | `/customer/history` | `CustomerHistoryScreen` | Pelanggan / pengunjung customer mode. |
| 12 | `/customer/profile` | `CustomerProfileScreen` | Pelanggan / pengunjung customer mode. |
| 13 | `/customer/checkout` | `CustomerCheckoutPage` | Pelanggan / pengunjung customer mode. |
| 14 | `/customer/cart` | `CustomerCartScreen` | Pelanggan / pengunjung customer mode. |
| 15 | `/customer/scan` | `CustomerScanScreen` | Pelanggan / pengunjung customer mode. |
| 16 | `/customer/search` | `CustomerSearchScreen` | Pelanggan / pengunjung customer mode. |
| 17 | `/customer/select-location` | `CustomerSelectLocationScreen` | Pelanggan / pengunjung customer mode. |
| 18 | `/customer/all-stores` | `CustomerAllStoresScreen` | Pelanggan / pengunjung customer mode. |
| 19 | `/customer/store-detail` | `CustomerStoreDetailScreen` | Pelanggan / pengunjung customer mode. |
| 20 | `/customer/order/:orderId` | `CustomerOrderTrackingScreen` | Pelanggan / pengunjung customer mode. |
| 21 | `/customer/receipt/:transactionId` | `CustomerReceiptScreen` | Pelanggan / pengunjung customer mode. |
| 22 | `/customer/loyalty` | `CustomerLoyaltyScreen` | Pelanggan / pengunjung customer mode. |
| 23 | `/customer/notifications` | `CustomerNotificationsScreen` | Pelanggan / pengunjung customer mode. |

## 3. Layar Operasional Staff

Layar di bagian ini memerlukan user login dan toko aktif. Kecuali dua rute yang secara eksplisit diblokir router untuk non-owner (`/staff-management`, `/store-info`), **seluruh layar berikut kini dapat diakses oleh Owner maupun Kasir**.

| No | Route | Screen | Akses |
|---|---|---|---|
| 24 | `/dashboard` | `DashboardScreen` | Semua staff toko yang login. |
| 25 | `/pos` | `POSScreen` | Semua staff toko yang login. |
| 26 | `/transactions` | `TransactionHistoryScreen` | Semua staff toko yang login. |
| 27 | `/reports` | `ReportsScreen` | Semua staff toko yang login — **tidak lagi dibatasi router**. |
| 28 | `/settings` | `SettingsScreen` | Semua staff toko yang login. |
| 29 | `/settings/sync-monitoring` | `SyncMonitoringScreen` | Semua staff toko yang login. |
| 30 | `/payment` | `PaymentScreen` | Semua staff toko yang login. Dipanggil dari alur POS; menangani juga logika split bill. |
| 31 | `/receipt` | `ReceiptScreen` | Semua staff toko yang login. Dipakai setelah transaksi selesai. |
| 32 | `/printer-settings` | `PrinterSettingsScreen` | Semua staff toko yang login. |
| 33 | `/receipt-customization` | `ReceiptCustomizationScreen` | Semua staff toko yang login. |
| 34 | `/categories` | `CategoryListScreen` | Semua staff toko yang login — **tidak lagi dibatasi router**. |
| 35 | `/categories/products` | `CategoryProductsScreen` | Semua staff toko yang login. |
| 36 | `/store-info` | `StoreInfoScreen` | **Owner/admin saja.** Diblokir router untuk non-owner. |
| 37 | `/staff-management` | `StaffManagementScreen` | **Owner/admin saja.** Diblokir router untuk non-owner. |
| 38 | `/products` | `ProductListScreen` | Semua staff toko yang login — **tidak lagi dibatasi router**. |
| 39 | `/products/add` | `ProductFormScreen` | Semua staff toko yang login. |
| 40 | `/products/edit` | `ProductFormScreen` | Semua staff toko yang login. |
| 41 | `/stock` | `StockManagementScreen` | Semua staff toko yang login. |
| 42 | `/stock/history` | `StockHistoryScreen` | Semua staff toko yang login. |
| 43 | `/smart-analytics` | `SmartAnalyticsScreen` | Semua staff toko yang login — **tidak lagi dibatasi router**. |
| 44 | `/sales-performance` | `SalesPerformanceScreen` | Semua staff toko yang login. Fitur baru, belum ada di dokumen sebelumnya. |
| 45 | `/smart-analytics/history` | `SmartAnalyticsHistoryScreen` | Semua staff toko yang login. |
| 46 | `/smart-analytics/history/:id` | Detail riwayat Smart Analytics | Semua staff toko yang login. |
| 47 | `/profile` | `ProfileScreen` | Semua staff toko yang login. |
| 48 | `/notifications` | `NotificationCenterScreen` | Semua staff toko yang login. |
| 49 | `/notification-settings` | `NotificationSettingsScreen` | Semua staff toko yang login. |
| 50 | `/broadcast-notification` | `BroadcastNotificationScreen` | Semua staff toko yang login — **tidak lagi dibatasi router**. |

## 4. Shell Wrapper

| No | Route / Context | Screen | Akses |
|---|---|---|---|
| 51 | Customer shell | `CustomerShellScreen` | Semua pengguna di customer mode. |
| 52 | Staff shell | `ScaffoldWithNavBar` | Semua staff toko yang login. |

## 5. Fitur yang Tidak Lagi Memiliki Screen/Route Terpisah

| Fitur | Status Saat Ini |
|---|---|
| Kitchen Display System (KDS) | **Dihapus sepenuhnya** dari kode (screen, provider, route `/kds`). Sisa artefak hanya berupa kolom skema database yang tidak lagi dipakai (lihat ERD.md). |
| Manajemen Meja (`ManageTablesScreen`, route `/manage-tables`) | Tidak ada screen/route mandiri. Logika status meja berjalan lewat `TableMonitoringProvider` yang dipakai di dalam `pos_screen.dart`. |
| Split Bill (`SplitBillScreen`, route `/split-bill`) | Tidak ada screen/route mandiri. Logika split bill terintegrasi di `cart_detail_sheet.dart` dan `payment_screen.dart`. |
| Pemindai Barcode Mandiri (`BarcodeScannerScreen`) | Fungsi pemindaian barcode kini dipanggil sebagai komponen/dialog dari layar POS dan form produk, bukan screen route terpisah. |
| `KosongPage` (placeholder legacy) | Berasal dari `lib/Configuration/components.dart` yang sudah dihapus saat restrukturisasi direktori (lihat Style.md). |

## 6. Layar Helper / Non-route

| Screen | Dipakai untuk |
|---|---|
| `CustomerMenuScreen` | Komponen internal di `customer_screens.dart`. |
| `CustomerCheckoutScreen` | Komponen internal di `customer_screens.dart`. |
| `_DetailPage` | Komponen internal untuk tampilan detail di customer flow. |

## Catatan Akses

- `Owner/admin` di dokumen ini mengikuti logika router: `user_role == 'owner'` atau `auth.currentUser.appMetadata.role == 'admin'`.
- Sejak penyesuaian RBAC (commit *"Penyesuaian Fitur Role Kasir"*), daftar rute yang diblokir router untuk non-owner hanya `restrictedRoutes = ['/staff-management', '/store-info']` (`lib/core/router/router.dart`). Seluruh rute lain yang sebelumnya dibatasi (`/reports`, `/products`, `/categories`, `/smart-analytics`, `/broadcast-notification`, dll.) **kini terbuka untuk kasir**.
- Jika user membuka route yang diblokir, router akan mengarahkan ke `/dashboard` atau `/login` sesuai kondisi login dan toko aktif.
