# Penyesuaian Fitur Role Kasir/Karyawan

## Context

Saat ini akses kasir (`karyawan`) dibatasi cukup luas: laporan, smart analytics, manajemen produk/kategori, stok, kustomisasi struk, broadcast notifikasi, dan filter tanggal/waktu di dashboard & riwayat transaksi semuanya disembunyikan atau dipaksa ke "hari ini" untuk role selain `owner`. Tujuan perubahan ini: **kasir harus bisa tetap menjalankan toko sepenuhnya saat owner tidak ada** (restock, cek laporan, kelola produk, kirim broadcast promo, lihat riwayat transaksi lampau untuk komplain/refund, dst).

Berdasarkan diskusi dengan user, hanya **dua** hal yang tetap eksklusif untuk Owner:
1. **Manajemen Staff** (`/staff-management`) — menambah/menghapus akun karyawan & mengubah role adalah wewenang pemilik.
2. **Info Toko** (`/store-info`) — data identitas/legal toko adalah wewenang pemilik.

Semua fitur operasional lain (laporan, smart analytics, sales performance, produk & kategori, stok, kustomisasi struk, broadcast notifikasi, filter tanggal riwayat transaksi, filter waktu dashboard, tab bottom-nav "Laporan") **dibuka untuk kasir**, tidak lagi di-hide.

Proteksi tambahan di level router untuk fitur yang tetap owner-only **tidak diperlukan** — cukup disembunyikan di UI (drawer/settings), sesuai keputusan user, karena `/staff-management` dan `/store-info` sudah cukup sensitif tapi risiko rendah bila diakses langsung (tidak ada data yang leak, hanya form CRUD yang butuh UI).

Ada juga inkonsistensi lama yang perlu diluruskan: `dashboard_screen.dart` dan `transaction_history_screen.dart` mendefinisikan `isAdmin` secara sempit (`role == 'owner'` saja, tanpa OR `appMetadata['role'] == 'admin'`) berbeda dari file lain. Karena kedua fitur ini dibuka untuk semua role, gating tersebut akan **dihapus sepenuhnya** (bukan diperbaiki) — jadi inkonsistensi otomatis hilang.

## Perubahan per File

### 1. `lib/core/router/router.dart` (baris ~126-145)
Persempit `restrictedRoutes` menjadi hanya dua route:
```dart
final restrictedRoutes = [
  '/staff-management',
  '/store-info',
];
```
Hapus: `/reports`, `/products`, `/categories`, `/manage-tables`, `/broadcast-notification`, `/smart-analytics`, `/sales-performance` dari daftar. Logika `isOwner` (baris 118-124) tidak berubah.

### 2. `lib/core/widgets/app_drawer.dart`
- `_DrawerMenuContent` (baris ~93-193): hapus semua `if (isAdmin)` yang membungkus:
  - Section **Analytics**: item Laporan (`/reports`) dan Smart Analytics (`/smart-analytics`) — jadi item biasa (selalu tampil).
  - Section **Katalog & Stok** (`/products`, `/stock`, `/stock/history`, `/categories`) — seluruh section (termasuk header-nya) jadi selalu tampil, tidak lagi dibungkus `if (isAdmin) ...[...]`.
  - Item **Receipt Customization** (`/receipt-customization`) di section Settings — selalu tampil.
  - Item **Broadcast Notification** — cek apakah ada di drawer (laporan eksplorasi menyebut hanya ada di `settings_screen.dart`, bukan drawer langsung) — jika ada, buka juga.
- Item drawer **Store Information** yang saat ini route ke `/settings` (baris ~177, label storeInformation) tetap `if (isAdmin)` — TAPI perhatikan: item ini sebenarnya menuju `/settings` (general settings hub), bukan `/store-info` langsung. Karena `/settings` sendiri sudah terbuka untuk semua role (general hub), pertimbangkan apakah item drawer ini masih relevan sebagai gate terpisah — **rekomendasi: hapus gate `isAdmin` pada item ini juga** karena `/settings` memang harus bisa diakses semua role (kasir butuh printer settings, notification settings, dll yang ada di dalamnya). Item khusus `/store-info` yang benar-benar owner-only sudah ada di dalam `settings_screen.dart`.
- Section **Super Admin** (`/admin`, baris 184-193, gated `appMetadata['role']=='admin'`) — **tidak diubah**, di luar scope (unrelated ke role toko, dan fitur ini masih `isSoon`).
- Variabel `isAdmin` (baris 51-52) tetap didefinisikan tapi hanya dipakai untuk logika yang tersisa (tidak ada lagi di drawer setelah perubahan ini kecuali Super Admin section yang pakai check terpisah) — jika akhirnya tidak dipakai sama sekali di file ini, hapus variabelnya untuk menghindari unused-variable warning.

### 3. `lib/core/router/scaffold_with_navbar.dart` (baris ~59-61, 123-168)
Hapus percabangan role untuk bottom nav tabs — semua role (owner & kasir) mendapat 5 tab yang sama termasuk **Laporan**. Samakan dengan tab set yang saat ini hanya diberikan ke owner.

### 4. `lib/features/settings/presentation/settings_screen.dart` (baris 45-124)
- Section **Catalog & Stok** (baris 45-79, `if (isAdmin) ...`) — buka untuk semua role (hapus wrapper `if (isAdmin)`).
- Di dalam section **Store Settings** (baris 80-125):
  - `receiptCustomization` (baris 96-102) — buka untuk semua role.
  - `storeInformation` → `/store-info` (baris 103-109) — **tetap** `if (isAdmin)`.
  - `employeeManagement` → `/staff-management` (baris 110-116) — **tetap** `if (isAdmin)`.
  - `broadcastNotification` (baris 117-123) — buka untuk semua role.
  - Perlu memecah blok `if (isAdmin) [...]` (baris 95-124) yang saat ini membungkus 4 item sekaligus menjadi: 2 item selalu tampil (receiptCustomization, broadcastNotification) + 1 blok `if (isAdmin) [...]` berisi 2 item (storeInformation, employeeManagement).
- Baris 157 (`if (role?.toLowerCase() == 'karyawan')` untuk tombol "Keluar dari Toko") — **tidak diubah**, ini memang fitur khusus untuk karyawan (bukan admin-gate), sudah benar.

### 5. `lib/features/dashboard/presentation/dashboard_screen.dart`
- Hapus penggunaan `isAdmin` untuk membatasi kasir (baris 25, 28-54, 68-71, 79, 81-84, 95, 111, 131, 147+):
  - Time filter (`_buildTimeFilter`) selalu tampil, tidak dipaksa "today".
  - `_buildSalesPerformanceCard` selalu tampil.
  - `_buildQuickAccessGrid` — parameter `isAdmin` dihapus/di-set selalu `true` secara efektif; card Product management, Reports, Settings shortcuts selalu tampil.
  - Auto-switch time range ke `today` untuk kasir (baris 27-33, 53) dihapus — semua role default sama (mengikuti default yang dipakai owner, mis. `week`).
- Efeknya sekaligus meluruskan inkonsistensi definisi `isAdmin` sempit di file ini karena gating dihapus total.

### 6. `lib/features/pos/presentation/transaction_history_screen.dart` (baris 96-134+)
- Hapus auto-force `_dateFilter = 'Hari Ini'` untuk non-admin (baris 98, 101-103).
- Hapus `if (isAdmin)` di sekitar date filter chips (baris 132-134) — semua chip (`Semua`, `Hari Ini`, `Kemarin`, custom) tampil untuk semua role.

### 7. `lib/features/pos/presentation/pos_screen.dart` (baris ~109-111, 333-334, 495, 541-548)
- FAB admin-only (~baris 495) dan tombol "Add Product" di empty-state (~baris 541-548) — buka untuk semua role.
- Perbaiki definisi `isAdmin` yang di-redefine secara sempit di baris 333-334 (shadow) — karena gating dihapus, variabel ini kemungkinan tidak lagi diperlukan di sekitar situ; verifikasi saat implementasi apakah `isAdmin`/`isOwner` masih dipakai untuk hal lain di file ini sebelum menghapus.

### 8. `lib/features/dashboard/presentation/notification_center_screen.dart` (baris ~109-111, 495)
- FAB compose/broadcast (admin-only) — buka untuk semua role, karena broadcast-notification sudah dibuka.

### Yang TIDAK diubah
- `lib/features/settings/presentation/staff_management_screen.dart` — tetap owner-only (gated via router `/staff-management` + settings menu item).
- `lib/features/settings/presentation/store_info_screen.dart` — tetap owner-only (gated via router `/store-info` + settings menu item).
- `lib/features/auth/presentation/store_selection_screen.dart` baris 261 — hanya styling badge, tidak perlu diubah.
- Router: tidak menambahkan proteksi baru untuk route lain (sesuai keputusan user).
- `/manage-tables`, `/table-monitoring` — tetap disembunyikan tapi oleh flag `hasTables = false` (bukan role), jadi tidak relevan untuk perubahan role ini; dikeluarkan dari `restrictedRoutes` karena toh sudah dihalangi flag `hasTables`, tapi tidak perlu perubahan tambahan di file terkait.

## Verifikasi
1. `flutter analyze` — pastikan tidak ada unused-variable warning setelah menghapus penggunaan `isAdmin` di beberapa file.
2. Jalankan app (`flutter run`), login sebagai user dengan role `Karyawan` di suatu store (via staff management existing test store), lalu cek manual:
   - Drawer menampilkan Laporan, Smart Analytics, Katalog & Stok, Receipt Customization, Broadcast Notification.
   - Bottom nav menampilkan tab Laporan.
   - `/settings` menampilkan semua menu kecuali "Employee Management" dan "Store Information".
   - Dashboard menampilkan filter waktu penuh & Sales Performance card.
   - Riwayat Transaksi menampilkan semua filter tanggal (Semua/Hari Ini/Kemarin).
   - POS menampilkan FAB/tombol tambah produk.
   - Mencoba akses langsung `/staff-management` dan `/store-info` (via `context.push` manual atau deep link) sebagai kasir → tetap ter-redirect ke `/dashboard` (router masih memblokir kedua route ini).
3. Login sebagai `Owner` di store yang sama — pastikan tidak ada regresi (semua fitur tetap tampil seperti sebelumnya).
