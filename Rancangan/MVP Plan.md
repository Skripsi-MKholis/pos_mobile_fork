# Milestone Pengembangan MVP System POS Mobile (Flutter)

Dokumen ini merinci rencana pengembangan bertahap untuk mencapai versi **Minimum Viable Product (MVP)** dari aplikasi Parzello POS versi mobile/tablet. Kami memanfaatkan infrastruktur backend Supabase yang sudah ada namun membangun ulang antarmuka menggunakan Flutter.

## Fase 1: Fondasi & Autentikasi (Status: Completed) ✅
Menyiapkan infrastruktur dasar aplikasi Flutter.

- [x] **Inisialisasi Project**: Setup Flutter project dan struktur folder.
- [x] **Dependency Setup**: Konfigurasi `pubspec.yaml` (Riverpod, Supabase, GoRouter).
- [x] **Supabase Integration**: Inisialisasi Supabase client di Flutter.
- [x] **Sistem Autentikasi**: Implementasi layar Login & Register dengan Supabase Auth.
- [x] **State Management**: Setup Riverpod providers untuk User & Auth state.

## Fase 2: Manajemen Produk & Stok (Mobile View) (Status: Completed) ✅
Membangun UI untuk pengelolaan inventaris yang ramah sentuhan.

- [x] **Katalog Produk**: Daftar produk dengan pencarian cepat dan filter.
- [x] **Barcode Scanner**: Integrasi kamera untuk scan SKU produk.
- [x] **Product Form**: CRUD produk (Nama, Harga, SKU, Gambar dari Galeri/Kamera).
- [x] **Real-time Inventory**: Sinkronisasi stok otomatis via Supabase Realtime.

## Fase 3: Core POS / Antarmuka Kasir (Status: Completed) ✅
Fitur kritikal untuk operasional bisnis di mobile/tablet.

- [x] **Checkout Interface**: Grid/List produk dengan sistem keranjang (Add/Remove items).
- [x] **Calculation Engine**: Kalkulasi total, pajak, dan diskon di tingkat lokal.
- [x] **Payment Flow**: Pemilihan metode bayar (Tunai, QRIS) dan input nominal.
- [x] **Receipt Management**: Generate struk digital (PDF/Image).

## Fase 4: Integrasi Hardware & Cetak (Status: Completed) ✅
Fungsionalitas spesifik perangkat mobile.

- [x] **Bluetooth/USB Printing**: Integrasi library printer thermal.
- [x] **Format Struk**: Penyesuaian layout struk untuk ukuran 58mm/80mm.
- [x] **Test Print**: Simulasi cetak struk setelah transaksi berhasil.

## Fase 5: UI Polish & Shadcn UI (Status: Completed) ✅
Memastikan pengalaman premium dengan framework desain modern.

- [x] **Shadcn UI Migration**: Implementasi komponen premium (ShadCard, ShadButton, ShadInput).
- [x] **Custom Theme**: Penyesuaian skema warna Stone & Lime yang energetik.
- [x] **Error Fixes**: Perbaikan bug inisialisasi dan masalah build Gradle.
- [x] **Responsive Layout**: Layout yang adaptif untuk berbagai ukuran layar.

---

## Rencana Milestone Lanjut (Pasca-MVP)
- [ ] **Kitchen Display System (KDS)**: Tampilan khusus tablet untuk dapur.
- [ ] **Advanced Analytics**: Grafik performa penjualan menggunakan `fl_chart`.
- [ ] **Push Notifications**: Notifikasi stok rendah dan broadcast owner.
- [ ] **Multi-language Support**: Dukungan Bahasa Indonesia & Inggris.

## Kriteria Keberhasilan MVP
- **Operasional Dasar**: Berhasil melakukan login, scan produk, dan checkout hingga cetak struk.
- **Sinkronisasi**: Data tersinkronisasi dengan database Supabase secara real-time.
- **Performa**: Aplikasi tetap responsif dengan >500 item produk di katalog.
- **Kualitas UI**: Mengikuti pedoman desain di `Design.md`.
saat modul dinonaktifkan di pengaturan.
