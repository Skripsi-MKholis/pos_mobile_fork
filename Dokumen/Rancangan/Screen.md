# Screen Aplikasi

Dokumen ini merangkum layar yang ada di aplikasi berdasarkan `lib/core/router/router.dart`, layar shell utama, dan beberapa layar helper yang dipakai langsung dari kode.

## Ringkasan

- Total entry yang didokumentasikan: 51
- Route tujuan utama: 48
- Shell wrapper: 2
- Redirect entry: 1

## 1. Layar Publik / Auth

| No | Route | Screen | Akses |
|---|---|---|---|
| 1 | `/onboarding` | `OnboardingScreen` | Semua pengunjung saat first run. Setelah first run, route ini dialihkan ke `/login`. |
| 2 | `/login` | `LoginScreen` | Pengunjung yang belum login. |
| 3 | `/register` | `RegisterScreen` | Pengunjung yang belum login. |
| 4 | `/forgot-password` | `ForgotPasswordScreen` | Pengunjung yang belum login. |
| 5 | `/setup-password` | `SetupPasswordScreen` | Pengunjung yang sedang menyelesaikan setup/reset password. |
| 6 | `/select-store` | `StoreSelectionScreen` | User yang sudah login tetapi belum memilih toko aktif. |
| 7 | `/create-store` | `CreateStoreScreen` | User yang sudah login tetapi belum punya toko aktif. |

## 2. Layar Pelanggan

Semua route `"/customer/*"` dibuka tanpa login staff. Ini adalah mode katalog/pembelian mandiri untuk pelanggan.

| No | Route | Screen | Akses |
|---|---|---|---|
| 8 | `/customer` | Redirect ke `/customer/home` | Entry point customer mode. |
| 9 | `/customer/home` | `CustomerHomeScreen` | Pelanggan / pengunjung customer mode. |
| 10 | `/customer/history` | `CustomerHistoryScreen` | Pelanggan / pengunjung customer mode. |
| 11 | `/customer/profile` | `CustomerProfileScreen` | Pelanggan / pengunjung customer mode. |
| 12 | `/customer/checkout` | `CustomerCheckoutPage` | Pelanggan / pengunjung customer mode. |
| 13 | `/customer/cart` | `CustomerCartScreen` | Pelanggan / pengunjung customer mode. |
| 14 | `/customer/scan` | `CustomerScanScreen` | Pelanggan / pengunjung customer mode. |
| 15 | `/customer/search` | `CustomerSearchScreen` | Pelanggan / pengunjung customer mode. |
| 16 | `/customer/select-location` | `CustomerSelectLocationScreen` | Pelanggan / pengunjung customer mode. |
| 17 | `/customer/all-stores` | `CustomerAllStoresScreen` | Pelanggan / pengunjung customer mode. |
| 18 | `/customer/store-detail` | `CustomerStoreDetailScreen` | Pelanggan / pengunjung customer mode. |
| 19 | `/customer/order/:orderId` | `CustomerOrderTrackingScreen` | Pelanggan / pengunjung customer mode. |
| 20 | `/customer/receipt/:transactionId` | `CustomerReceiptScreen` | Pelanggan / pengunjung customer mode. |
| 21 | `/customer/loyalty` | `CustomerLoyaltyScreen` | Pelanggan / pengunjung customer mode. |
| 22 | `/customer/notifications` | `CustomerNotificationsScreen` | Pelanggan / pengunjung customer mode. |

## 3. Layar Operasional Staff

Layar di bagian ini memerlukan user login dan toko aktif. Secara default bisa diakses oleh staff toko, kasir, owner, dan admin, kecuali yang diberi pembatasan khusus di bawah.

| No | Route | Screen | Akses |
|---|---|---|---|
| 23 | `/dashboard` | `DashboardScreen` | Semua staff toko yang login. Owner/admin mendapat fitur tambahan di UI. |
| 24 | `/pos` | `POSScreen` | Semua staff toko yang login. |
| 25 | `/transactions` | `TransactionHistoryScreen` | Semua staff toko yang login. Owner/admin mendapat filter tanggal lebih luas. |
| 26 | `/settings` | `SettingsScreen` | Semua staff toko yang login. Beberapa menu di dalamnya hanya tampil untuk owner/admin. |
| 27 | `/settings/sync-monitoring` | `SyncMonitoringScreen` | Semua staff toko yang login. |
| 28 | `/payment` | `PaymentScreen` | Semua staff toko yang login. Biasanya dipanggil dari alur POS. |
| 29 | `/receipt` | `ReceiptScreen` | Semua staff toko yang login. Biasanya dipakai setelah transaksi selesai. |
| 30 | `/printer-settings` | `PrinterSettingsScreen` | Semua staff toko yang login. |
| 31 | `/receipt-customization` | `ReceiptCustomizationScreen` | Owner/admin via UI. Route ini belum diblokir eksplisit di router, jadi direct access masih mungkin jika user tahu URL. |
| 32 | `/table-monitoring` | `TableMonitoringScreen` | Semua staff toko yang login. Menu aksesnya disembunyikan saat fitur meja dimatikan. |
| 33 | `/split-bill` | `SplitBillScreen` | Semua staff toko yang login. Biasanya dipakai dari alur meja/POS. |
| 34 | `/stock` | `StockManagementScreen` | Semua staff toko yang login. |
| 35 | `/stock/history` | `StockHistoryScreen` | Semua staff toko yang login. Di UI ditempatkan di menu owner/admin, tetapi router tidak memblokir langsung. |
| 36 | `/kds` | `KDSScreen` | Semua staff toko yang login. |
| 37 | `/smart-analytics` | `SmartAnalyticsScreen` | Owner/admin. Route ini diblokir untuk non-owner di router. |
| 38 | `/profile` | `ProfileScreen` | Semua staff toko yang login. |
| 39 | `/notifications` | `NotificationCenterScreen` | Semua staff toko yang login. Owner/admin mendapat tombol aksi tambahan di UI. |
| 40 | `/broadcast-notification` | `BroadcastNotificationScreen` | Owner/admin. Route ini diblokir untuk non-owner di router. |

## 4. Layar Katalog / Master Data

Layar di bawah ini adalah area master data. Sebagian dibatasi langsung oleh router ke owner/admin.

| No | Route | Screen | Akses |
|---|---|---|---|
| 41 | `/reports` | `ReportsScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 42 | `/categories` | `CategoryListScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 43 | `/categories/products` | `CategoryProductsScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 44 | `/products` | `ProductListScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 45 | `/products/add` | `ProductFormScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 46 | `/products/edit` | `ProductFormScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 47 | `/store-info` | `StoreInfoScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 48 | `/staff-management` | `StaffManagementScreen` | Owner/admin. Diblokir di router untuk non-owner. |
| 49 | `/manage-tables` | `ManageTablesScreen` | Owner/admin. Diblokir di router untuk non-owner. |

## 5. Shell Wrapper

| No | Route / Context | Screen | Akses |
|---|---|---|---|
| 50 | Customer shell | `CustomerShellScreen` | Semua pengguna di customer mode. |
| 51 | Staff shell | `ScaffoldWithNavBar` | Semua staff toko yang login. |

## 6. Layar Helper / Non-route

Layar berikut ada di codebase, tetapi bukan tujuan route utama di `router.dart`.

| Screen | Dipakai untuk |
|---|---|
| `BarcodeScannerScreen` | Helper scanner di alur POS. |
| `KosongPage` | Placeholder/legacy page dari `Configuration/components.dart`. |
| `CustomerMenuScreen` | Komponen internal di `customer_screens.dart`. |
| `CustomerCheckoutScreen` | Komponen internal di `customer_screens.dart`. |
| `_DetailPage` | Komponen internal untuk tampilan detail di customer flow. |

## Catatan Akses

- `Owner/admin` di dokumen ini mengikuti logika router: `user_role == 'owner'` atau `auth.currentUser.appMetadata.role == 'admin'`.
- Beberapa layar hanya dibatasi di UI, bukan di router. Contoh paling jelas: `ReceiptCustomizationScreen` dan `StockHistoryScreen`.
- Jika user membuka route yang diblokir, router akan mengarahkan ke `/dashboard` atau `/login` sesuai kondisi login dan toko aktif.
