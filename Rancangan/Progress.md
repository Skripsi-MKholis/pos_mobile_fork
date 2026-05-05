# 📈 Jurnal Proyek: Parzello POS Mobile

Dokumen ini mencatat riwayat kemajuan pengembangan aplikasi Parzello POS.

---

### 📅 5 Mei 2026 (Sesi 6) - Fase: UI Modularization & Performance Optimization (Status: 100% Selesai ✅)

#### ✅ Pencapaian Sesi Ini:
1.  **Modular Table Architecture**: Menciptakan widget kustom `ParzelloTable` dan `ParzelloTableRow` untuk standardisasi tampilan data di seluruh aplikasi (Produk & Kategori).
2.  **Schema Alignment (Category)**: Menghapus field `description` pada model dan UI Kategori agar sesuai dengan skema database Supabase terkini.
3.  **High-Performance Lookups**: Mengoptimalkan render katalog produk dengan mengimplementasikan `categoryMap` (O(1) lookup) untuk menggantikan pencarian linear O(N).
4.  **Memory Leak Prevention**: Implementasi manajemen siklus hidup `RealtimeChannel` Supabase menggunakan `ref.onDispose` pada seluruh provider.
5.  **UX & System Stability**: 
    - Memperbaiki *layout overflow* pada kolom aksi dengan tombol berbasis `InkWell` yang lebih ringkas.
    - Mengaktifkan `OnBackInvokedCallback` di `AndroidManifest.xml` untuk mendukung fitur *predictive back gesture* pada Android 13+.

#### 🛠️ Status Teknis:
- **UI Architecture**: Standardisasi tabel modular selesai.
- **Resource Management**: Realtime subscription sudah terkelola dengan aman.
- **Android Support**: Kompatibel penuh dengan Android 13+ (API 33).


### 📅 5 Mei 2026 (Sesi 5) - Fase: Data Sync Stability & Multi-Store Visibility (Status: 100% Selesai ✅)

#### ✅ Pencapaian Sesi Ini:
1.  **Robust Data Synchronization**: Memperbaiki masalah katalog produk kosong dengan mengimplementasikan auto-sync pada `build()` provider dan memperkuat pemetaan data numerik dari Supabase.
2.  **Multi-Store Query Fix**: Menghilangkan bug pada query `in` di `store_provider.dart` yang menyebabkan toko tempat user terdaftar sebagai staff tidak muncul. Kini seluruh toko (Owner & Staff) tampil dengan benar.
3.  **Real-time UI Refresh**: Menambahkan `RefreshIndicator` pada Katalog Produk untuk memudahkan pengguna melakukan sinkronisasi manual.
4.  **Premium Store Branding**: Memastikan logo toko dari Supabase Storage tampil konsisten di halaman pemilihan toko dan sidebar.
5.  **Modern Code Standards**: Refactor seluruh pemanggilan `withOpacity` ke `withValues(alpha: ...)` sesuai standar Flutter 3.27+.

#### 🛠️ Status Teknis:
- **Sync Logic**: Menggunakan `Future.microtask` untuk background sync tanpa infinite loop.
- **Data Mapping**: Penanganan nilai `numeric` Supabase (String) ke `double` Flutter sudah aman.
- **Store Visibility**: Query `.or()` sudah dioptimasi untuk UUID PostgREST.

---

### 📅 5 Mei 2026 (Sesi 3) - Fase: Store Management & Sidebar UX Optimization (Status: 100% Selesai ✅)

#### ✅ Pencapaian Sesi Ini:
1.  **Interactive Store Switcher**: Implementasi `ShadPopover` pada sidebar yang memungkinkan pengguna berpindah outlet secara instan tanpa log out.
2.  **Supabase Storage Integration**: Menampilkan logo toko secara real-time dari Supabase Storage pada (1) Header Sidebar, (2) Daftar Popover, dan (3) Halaman Seleksi Toko.
3.  **Multi-Store Logic Refinement**: Memperbarui `userStoresProvider` untuk menarik data toko dari dua sumber: toko milik user (`owner_id`) dan toko di mana user terdaftar sebagai anggota (`store_members`).
4.  **UI/UX Overlap Fix**: Optimalisasi layout sidebar menggunakan background solid, shadow, dan penyesuaian padding untuk mencegah tumpang tindih visual antara informasi outlet dan menu navigasi.
5.  **Syntax Stabilization**: Refactor total kode `AppDrawer` untuk menghilangkan duplikasi dan memastikan struktur widget nesting yang stabil.

#### 🛠️ Status Teknis:
- **Store Switching**: Berjalan lancar dengan refresh data otomatis.
- **Null-Safety**: Implementasi pengecekan logo_url yang lebih aman pada seluruh komponen UI.
- **Build Status**: Stabil, tidak ada syntax error yang tersisa.

---

### 📅 5 Mei 2026 (Sesi 2) - Fase: Web Alignment & Dashboard Redesign (Status: 100% Selesai ✅)

#### ✅ Pencapaian Sesi Ini:
1.  **Sidebar/Drawer Integration**: Implementasi `AppDrawer` lengkap berdasarkan struktur web (Analytics, Operasional, Katalog, Laporan).
2.  **Premium Navigation (GNav)**: Migrasi ke `google_nav_bar` dengan desain interaktif dan modern.
3.  **Role-Based UI**: Bottom Navbar dan Sidebar dinamis yang menyesuaikan menu antara role **Admin** dan **Owner/Staff**.
4.  **Dashboard Overhaul**: Desain ulang halaman utama Dashboard agar memiliki fitur dan visual yang identik dengan versi Web (Quick Access, Stat Cards, & Sales Chart).
5.  **Architecture Cleanup**: Refactor seluruh halaman utama untuk menghilangkan redundansi `Scaffold` dan sentralisasi `AppBar`.

#### 🛠️ Status Teknis:
- **Navigation**: Dual-system (GNav + Drawer) aktif.
- **UI Components**: Implementasi `CustomPainter` untuk visualisasi grafik estetik.
- **Router**: Mendukung 5-branch navigation stack.

### Sesi 4: Katalog Produk & Manajemen Kategori (Premium UI)
*   **Redesain Katalog Produk**: Mengubah tampilan daftar produk menjadi model "Table-View" yang bersih dan profesional, sesuai dengan dashboard web Parzello. (Status: 100% Selesai ✅)
*   **Implementasi CategoryNotifier**: Membuat sistem sinkronisasi kategori secara realtime antara Supabase dan Isar (Local Storage).
*   **Fitur Filter Kategori**: Menambahkan dropdown filter kategori pada katalog produk untuk mempermudah pencarian barang.
*   **Optimasi UI/UX**:
    *   Implementasi tombol "Tambah Produk" dengan warna aksen Lime Green (Premium Feel).
    *   Sinkronisasi data kategori secara otomatis pada setiap baris produk.
    *   Pembersihan kode dari *deprecated methods* (migrasi `withOpacity` ke `withValues`).

### Next Steps (Prioritas Berikutnya)
1.  **CRUD Produk Lengkap**: Menyelesaikan halaman Tambah/Edit produk dengan pemilihan kategori yang dinamis.
2.  **Manajemen Stok**: Menambahkan visualisasi stok rendah dan integrasi update stok cepat.
3.  **Realtime Sync Update**: Memastikan setiap perubahan di dashboard web langsung tercermin di aplikasi mobile tanpa refresh manual.

---

### 📅 5 Mei 2026 (Sesi 1) - Fase 5: UI Polish & Build Stability (Status: 100% Selesai ✅)

#### ✅ Pencapaian:
1.  **Shadcn UI Migration**: Refactor total Login, Dashboard, POS, Product Management, dan Receipt menggunakan Shadcn UI.
2.  **Custom Theme Styling**: Implementasi preset **Stone & Lime** yang memberikan kesan modern dan premium.
3.  **Gradle Namespace Patching**: Menambahkan script di `build.gradle.kts` untuk mendukung pustaka `blue_thermal_printer` pada Gradle 8.0+.
4.  **Error Handling**: Memperbaiki masalah "Undefined theme" dan inisialisasi model produk.

---

### 🛠️ Status Teknis Sebelumnya:
- **UI Framework**: Shadcn UI aktif global.
- **Build**: Stabil pada Android 12+ (SDK 31+).
