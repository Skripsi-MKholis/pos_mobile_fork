# 📈 Jurnal Proyek: Parzello POS Mobile

Dokumen ini mencatat riwayat kemajuan pengembangan aplikasi Parzello POS.

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

### ⏭️ Langkah Selanjutnya:
1.  **Tahap 3: Manajemen Katalog**: Implementasi CRUD Kategori dan integrasi dropdown di form produk.
2.  **Tahap 4: Riwayat Transaksi**: Menampilkan data real-time dari Supabase di halaman riwayat.
3.  **Tahap 5: Fitur Admin**: Mulai membangun halaman khusus Admin Dashboard dan Manajemen Toko.

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
