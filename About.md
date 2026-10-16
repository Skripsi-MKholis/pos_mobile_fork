# About Zello POS (Parzello POS)

**Zello POS** (sebelumnya dikenal sebagai *Parzello POS*) adalah aplikasi Point of Sale (Kasir Digital) berbasis mobile yang dirancang modern, cepat, dan handal untuk pelaku UMKM, bisnis retail, serta food & beverage (F&B). Aplikasi ini dibangun menggunakan Flutter dengan arsitektur *offline-first*, terintegrasi dengan kecerdasan buatan (AI/LSTM) untuk peramalan penjualan dan rekomendasi stok, serta didukung ekosistem backend Supabase & Firebase.

---

## 🎯 Gambaran Umum (Overview)

Zello POS hadir sebagai solusi kasir komprehensif yang tidak hanya mencatat transaksi penjualan harian, tetapi juga memberikan wawasan prediktif (*predictive analytics*) guna membantu pemilik toko mengoptimalkan perputaran stok, mengurangi kerugian barang basi/kadaluwarsa, dan meningkatkan margin keuntungan bisnis secara cerdas.

Dengan dukungan sinkronisasi otomatis (*offline-first*), kasir tetap dapat melayani pelanggan dengan lancar meski koneksi internet terputus di lapangan.

---

## 🌟 Fitur-Fitur Utama

### 1. Point of Sale (Kasir Digital Cepat & Intuitif)
- **Pencarian Cepat & Barcode Scanner**: Dukungan pemindaian barcode/SKU menggunakan kamera perangkat untuk input produk instan.
- **Dukungan Meja & F&B**: Manajemen nomor meja (*table ordering*) serta pemantauan status pesanan aktif.
- **Custom Product**: Kemampuan menambahkan item kustom secara langsung saat transaksi berlangsung.
- **Multi-Metode Pembayaran**: Mendukung pembayaran Tunai (Cash), QRIS, Transfer Bank, dan Debit dengan perhitungan kembalian otomatis.
- **Konektivitas Printer Termal**: Cetak struk via printer thermal Bluetooth (dukungan ESC/POS 58mm & 80mm) serta kustomisasi logo dan catatan struk.

### 2. Smart Analytics & AI Forecast (Prediksi Penjualan LSTM)
- **Deep Learning Sales Forecasting**: Model peramalan berbasis LSTM (Long Short-Term Memory) untuk memprediksi tren penjualan harian, mingguan, dan bulanan.
- **Evaluasi Akurasi Prediksi**: Pelacakan akurasi peramalan (*forecast accuracy*) secara transparan dengan metrik MAPE, MAE, dan RMSE.
- **Rekomendasi Restok Cerdas**: Saran otomatis pengadaan stok barang berdasarkan proyeksi permintaan masa depan untuk mencegah *out-of-stock* maupun *overstocking*.
- **Snapshot & Riwayat Analitik**: Simpan dan tinjau riwayat performa analitik bisnis secara historis.

### 3. Manajemen Produk, Kategori, & Inventaris
- **Katalog Produk Terstruktur**: Pengelompokan produk per kategori, foto produk, harga jual, harga pokok (HPP), serta barcode.
- **Peringatan Stok Rendah (Low Stock Alert)**: Notifikasi instan saat persediaan menipis di bawah ambang batas minimal.
- **Riwayat Mutasi Stok**: Pencatatan lengkap setiap penambahan, pengurangan, dan penyesuaian stok (*stock adjustment*).

### 4. Laporan Penjualan & Analisis Laba/Rugi (HPP)
- Laporan omzet penjualan, laba kotor, dan laba bersih secara real-time.
- Perhitungan Harga Pokok Penjualan (HPP / COGS).
- Ringkasan transaksi terlaris (*best-selling items*) dan jam-jam sibuk (*peak hours*).

### 5. Multi-Store & Manajemen Karyawan (RBAC)
- **Role-Based Access Control (RBAC)**: Pembagian hak akses antara Pemilik Toko (*Owner / Admin*) dan Staf Kasir (*Karyawan*).
- **Multi-Outlet Support**: Dukungan pemilihan toko dan pergantian outlet secara seamless dalam satu akun.

### 6. Layanan Pelanggan & Self-Order (Customer Shell)
- Jalur khusus pelanggan (`/customer`) untuk melihat katalog toko, melakukan scan QR toko/meja, serta membuat pesanan mandiri (*self-ordering*).

### 7. Kehandalan Offline-First
- Menggunakan database lokal **Isar** yang sangat cepat untuk menyimpan data transaksi, produk, dan riwayat stok saat offline.
- Background sync otomatis via `SyncNotifier` saat perangkat terhubung kembali ke internet, menyelaraskan data lokal ke cloud database tanpa konflik.

### 8. Notifikasi & Deep Linking
- Integrasi Firebase Cloud Messaging (FCM) untuk pengiriman notifikasi broadcast promosi, pengingat stok, dan informasi transaksi.
- Deep linking langsung mengarahkan pengguna ke halaman terkait dari notifikasi sistem.

---

## 🛠️ Arsitektur & Teknologi

| Komponen | Teknologi | Deskripsi |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK ^3.11.5) | Antarmuka pengguna lintas platform dengan performa tinggi |
| **State Management** | Flutter Riverpod + Code Generation | Manajemen state reaktif, modular, dan terstruktur (`@riverpod`) |
| **Backend & Cloud DB** | Supabase | Database PostgreSQL, autentikasi pengguna, RLS, storage, dan Supabase Realtime |
| **Local Offline DB** | Isar Community (v3.2.1) | Database lokal NoSQL berkecepatan tinggi dengan 16 KB-page alignment |
| **Routing** | GoRouter | Navigasi deklaratif dengan route guards (Auth, Onboarding, Store, RBAC) |
| **UI Design System** | Shadcn UI (Luma - Stone/Lime Theme) | Komponen UI elegan, modern, konsisten, dan responsif |
| **Push Notification & Analytics** | Firebase Core, Auth, Messaging, Analytics | Notifikasi instan dan pelacakan event penggunaan aplikasi |
| **AI / Machine Learning** | Python / PyTorch (LSTM Service via HuggingFace) | Model inferensi peramalan deret waktu (*time-series forecasting*) |
| **Hardware Integration** | Bluetooth Thermal Printer (ESC/POS) | Cetak struk belanja via Bluetooth thermal printer |
| **Internationalization** | Flutter Localizations (ARB) | Dukungan multi-bahasa (Bahasa Indonesia & Bahasa Inggris) |

---

## 👥 Pengembang & Lisensi

- **Project**: Zello POS Mobile
- **Fokus Riset**: Integrasi Kasir Digital Offline-First & Peramalan Permintaan Produk Menggunakan Deep Learning (LSTM)
- **Status**: Aplikasi Produksi & Skripsi Penelitian
