# Zello POS (Point of Sale Mobile)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-blue)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)](https://supabase.com)
[![Offline DB](https://img.shields.io/badge/Local%20DB-Isar-blueviolet)](https://isar.dev)

**Zello POS** (sebelumnya *Parzello POS*) adalah aplikasi kasir digital (*Point of Sale*) modern berbasis mobile yang dirancang untuk mendukung operasional UMKM, ritel, dan bisnis F&B. Dilengkapi dengan arsitektur **offline-first**, integrasi **AI/LSTM Sales Forecasting**, sinkronisasi cloud real-time, serta pencetakan struk via thermal printer.

> 📖 Untuk dokumentasi gambaran umum dan ringkasan fitur lengkap, silakan baca [About.md](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/About.md).

---

## 🚀 Fitur Unggulan

- 🛒 **Point of Sale Cepat**: Scan barcode/SKU, multi-metode pembayaran (Cash, QRIS, Transfer), nomor meja, dan cetak struk via Bluetooth thermal printer.
- 🧠 **Smart Analytics (AI/LSTM)**: Prediksi tren penjualan otomatis berbasis model Deep Learning LSTM, evaluasi akurasi metrik (MAPE, MAE, RMSE), dan rekomendasi restok barang.
- 📦 **Manajemen Katalog & Inventaris**: Pengelolaan produk, kategori, HPP/harga jual, riwayat pergerakan stok, dan peringatan stok menipis (*low stock alert*).
- 📊 **Laporan Finansial & HPP**: Laporan laba/rugi, omzet, margin kotor/bersih, serta ringkasan jam sibuk operasional.
- 👥 **Multi-Store & RBAC**: Pengelolaan outlet toko terpusat dengan pembatasan hak akses berbasis peran (Owner / Admin vs Karyawan/Kasir).
- 📶 **Offline-First & Auto-Sync**: Transaksi kasir tetap berjalan lancar saat koneksi internet terputus, dan otomatis disinkronisasi ke Supabase saat kembali online.
- 🛍️ **Customer Self-Order Mode**: Antarmuka khusus pelanggan untuk eksplorasi katalog dan pemesanan mandiri melalui QR code meja/toko.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK ^3.11.5)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`, `riverpod_annotation`, code generation)
- **Backend & Auth**: [Supabase](https://supabase.com) (Auth, PostgreSQL DB, Realtime, Storage)
- **Local Database**: [Isar Community](https://github.com/isar-community/isar) v3.2.1 (16 KB page-aligned binaries)
- **Design System**: [Shadcn UI for Flutter](https://shadcn-ui.com) (Luma Stone/Lime Scheme)
- **Push Notification & Telemetry**: Firebase Core, Firebase Messaging (FCM), & Firebase Analytics
- **Machine Learning**: Model LSTM (HuggingFace Inference Endpoint & local fallback)

---

## 💻 Memulai Pengembangan (Getting Started)

### Prasyarat

- Flutter SDK (versi kompatibel dengan SDK Dart `^3.11.5`)
- Java JDK 17+ (untuk build Android)
- Android Studio / VS Code dengan ekstensi Flutter & Dart

### Instalasi

1. **Clone repositori**:
   ```bash
   git clone <repository-url>
   cd pos_mobile_fork
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Environment**:
   Salin file `env.example.json` menjadi `env.json` atau pastikan kredensial Supabase & Firebase telah sesuai di:
   - `lib/core/env/env.dart`
   - `android/app/google-services.json`
   - `lib/firebase_options.dart`

4. **Generate Kode (Riverpod)**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

---

## 📱 Build Production

Untuk menghasilkan file instalasi APK rilis:

```bash
flutter build apk --release
```

---

## 📚 Dokumentasi Terkait

- [About.md](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/About.md) — Penjelasan detail fitur & gambaran umum aplikasi.
- [CLAUDE.md](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/CLAUDE.md) — Panduan arsitektur teknis, aturan code-generation, dan pedoman pengembangan.
- [Release.md](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/Release.md) — Catatan rilis dan riwayat pembaruan versi aplikasi.
- [FEATURE_KEYS_GUIDE.md](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/FEATURE_KEYS_GUIDE.md) — Panduan kunci fitur dan kontrol hak akses / kuota.

