# 🎨 Panduan Desain Parzello POS (Mobile & Tablet)

Dokumen ini mendefinisikan identitas visual, filosofi desain, dan standar antarmuka pengguna (UI/UX) yang digunakan dalam pengembangan Parzello POS versi mobile menggunakan Flutter.

---

## 🏛️ Filosofi Desain: "Modern Premium & Ergonomic"

Parzello POS dirancang untuk menggabungkan estetika aplikasi SaaS modern dengan efisiensi alat operasional kasir di perangkat layar sentuh. 

1. **Touch-First & Modular**: Antarmuka berbasis kartu (card-based) dengan target sentuh minimal 44x44 dp untuk memudahkan navigasi.
2. **High Information Density**: Menyajikan data penting secara ringkas tanpa mengorbankan keterbacaan pada layar perangkat mobile/tablet.
3. **Adaptive Layout**: Layout yang menyesuaikan secara cerdas antara orientasi Portrait (Mobile) dan Landscape (Tablet).
4. **Interactive Feedback**: Respon visual instan menggunakan animasi Flutter (shimmer effects, hero transitions, micro-animations).

---

## 🌈 Sistem Warna (Material 3 Scheme)

Kami menggunakan skema warna yang dioptimalkan untuk kontras tinggi dan kenyamanan mata pada layar OLED/LCD.

### 1. Warna Utama (Brand)
- **Primary (Vibrant Lime)**: `Color(0xFFCCFF00)`
  - *Penggunaan*: Tombol aksi utama, indikator aktif, status sukses.
- **Success (Emerald)**: `Color(0xFF10B981)`
  - *Penggunaan*: Indikator stok tersedia, pembayaran berhasil.
- **Destructive (Ruby)**: `Color(0xFFE11D48)`
  - *Penggunaan*: Peringatan stok habis, aksi hapus, indikator kerugian.

### 2. Warna Dasar (Neutral)
- **Background**: `Color(0xFFFFFFFF)` (Light) | `Color(0xFF121212)` (Dark)
- **Surface/Card**: `Color(0xFFF8FAFC)` dengan elevation minimal atau border halus.

---

## ✍️ Tipografi (Typography)

Menggunakan package `google_fonts` untuk konsistensi di berbagai platform:

1. **Heading (Space Grotesk)**:
   - Karakter: Geometris, Futuristis.
   - Digunakan untuk: Judul halaman, Angka Stats besar.
2. **Body & Interface (Outfit)**:
   - Karakter: Hangat, Modern, Sangat terbaca.
   - Digunakan untuk: Navigasi, List item, Form input.
3. **Data & Technical (Geist Mono)**:
   - Karakter: Presisi, Monospace.
   - Digunakan untuk: SKU Produk, ID Transaksi, Nomor Invoice.

---

## 🧩 Komponen & Pola UI (Flutter Widgets)

### 1. Navigasi
- **Adaptive Sidebar**: Menggunakan `NavigationRail` pada Tablet (Landscape) dan `NavigationBar` atau `Drawer` pada Mobile (Portrait).
- **Store Switcher**: Dropdown atau Modal Bottom Sheet di AppBar untuk perpindahan antar outlet.
- **AppBar**: Berisi judul halaman, status sinkronisasi, dan menu profil.

### 2. Kartu Aksi (Action Cards)
- Menggunakan widget `Card` atau `Container` dengan dekorasi custom.
- Implementasi **Glassmorphism** menggunakan `BackdropFilter` (jika diperlukan untuk kesan premium).
- Menggunakan ikon dari `tabler_icons` atau `lucide_icons`.

### 3. Visualisasi Data
- **Interactive Charts**: Menggunakan library `fl_chart` yang responsif.
- **Status Badges**: Widget `Chip` atau `Container` custom dengan warna semi-transparan.
- **Skeleton Loaders**: Menggunakan package `shimmer` untuk loading state yang halus.

---

## 📱 UX & Interaktivitas

1. **Haptic Feedback**: Memberikan getaran halus (vibration) pada aksi kritikal (misal: sukses checkout).
2. **Gestures**: Mendukung swipe-to-delete pada daftar produk/keranjang.
3. **Offline Mode**: Cache data menggunakan `Isar` atau `SQLite` untuk menjamin operasional saat koneksi internet tidak stabil.
4. **Thermal Print Integration**: Mendukung cetak struk via Bluetooth/USB menggunakan library `flutter_pos_printer_platform`.

---

## 🛠️ Stack Teknologi (Flutter)

- **Framework**: Flutter (SDK ^3.x)
- **State Management**: Riverpod (Functional & Reactive)
- **Backend Service**: Supabase Flutter
- **Local Database**: Isar (High performance NoSQL)
- **Navigation**: GoRouter (Declarative routing)
- **Animations**: `flutter_animate` & Hero Animations
