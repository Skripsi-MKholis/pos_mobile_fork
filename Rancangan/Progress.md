# 📈 Jurnal Proyek: Parzello POS Mobile

Dokumen ini mencatat riwayat kemajuan pengembangan aplikasi Parzello POS.

---

### 📅 5 Mei 2026 (Sesi 2) - Fase: Web Alignment & Multi-Outlet (Status: In Progress 🚧)

#### ✅ Pencapaian Sesi Ini:
1.  **Stateful Navigation**: Implementasi `StatefulShellRoute` untuk navigasi bawah yang persisten.
2.  **Multi-Outlet Support**: Pembuatan `StoreSelectionScreen` dan `activeStoreProvider` untuk menangani banyak cabang.
3.  **Authentication Redirect**: Logika cerdas untuk mengarahkan user ke Login atau Pilih Toko secara otomatis.
4.  **Secure Logout**: Penambahan fitur keluar aplikasi yang sesungguhnya dengan dialog konfirmasi.
5.  **Router Stability**: Perbaikan error `GlobalKey` melalui restrukturisasi instance `GoRouter`.

#### 🛠️ Status Teknis:
- **Navigation**: Persistent Bottom Tab aktif.
- **State Management**: Riverpod + SharedPreferences (Persistence) aktif.

#### ⏭️ Langkah Selanjutnya:
1.  **Tahap 3: Manajemen Katalog**: Implementasi CRUD Kategori dan integrasi dropdown di form produk.

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
