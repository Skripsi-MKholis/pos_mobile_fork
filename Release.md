### **Versi Sekarang**

**1.1.0+3**

---

### **Nama Release**

**ZelloPOS MVP Launch - Stable Version**

---

### **Catatan Release (What's New)**

**Versi 1.0.0 (Initial MVP Release)**
Kami dengan bangga memperkenalkan versi stabil pertama dari ZelloPOS! Rilis ini mencakup seluruh fitur inti untuk mendukung operasional bisnis Anda mulai dari pendaftaran hingga cetak struk.

**Fitur Utama:**

* **Sistem Autentikasi Terintegrasi**: Login dan registrasi aman menggunakan infrastruktur Supabase Auth.
* **Manajemen Inventaris & Barcode**: Kelola katalog produk dan stok dengan mudah menggunakan pemindai barcode berbasis kamera ponsel.
* **Antarmuka Kasir (POS) yang Cepat**: Sistem keranjang belanja yang intuitif dengan kalkulasi pajak dan diskon otomatis secara lokal.
* **Integrasi Printer Thermal**: Dukungan cetak struk transaksi via koneksi Bluetooth atau USB untuk ukuran kertas 58mm/80mm.
* **Desain Modern & Responsif**: Antarmuka premium menggunakan *Shadcn UI* yang adaptif untuk berbagai ukuran layar smartphone dan tablet.
* **Sinkronisasi Real-time**: Data transaksi dan produk selalu sinkron antara perangkat mobile dan database pusat.
* **Manajemen Multi-Toko**: Kemampuan untuk berpindah antar outlet dengan cepat langsung dari menu profil.
* **Role-Based Access Control (RBAC)**: Pembatasan akses fitur yang jelas antara pemilik (Owner) dan staf (Kasir) untuk keamanan data.

**Perbaikan & Optimalisasi:**

* Migrasi komponen UI ke framework Shadcn untuk pengalaman pengguna yang lebih mulus.
* Penyesuaian skema warna *Vibrant Lime* yang energetik sesuai identitas branding.
* Peningkatan performa katalog untuk menangani lebih dari 500 item produk.

---

**Versi 1.0.0+2 (Security & Performance Update)**

* **Update Target SDK**: Meningkatkan target API level ke **35 (Android 15)** untuk memastikan aplikasi menggunakan fitur keamanan dan optimasi performa terbaru.
* **Compile SDK 36**: Memperbarui Compile SDK ke versi 36 untuk kompatibilitas penuh dengan library Google Play Services terbaru.

---

**Versi 1.1.0+3 (Feature Updates & Enhancements)**

* **Fitur Manajemen Stok**: Menambahkan sistem kelola stok yang komprehensif, memungkinkan pengguna untuk memperbarui inventaris dengan mudah. Mendukung penjualan stok 0/minus untuk fleksibilitas operasional.
* **Fitur Notifikasi**: Sistem notifikasi baru, baik dari sistem maupun *broadcast*, terintegrasi di dalam aplikasi.
* **Fitur Cetak & Kustomisasi Struk**: Integrasi pencetakan struk *thermal* (Bluetooth/USB) beserta halaman kustomisasi yang memungkinkan pengaturan *header*, pesan penutup, dan ukuran kertas secara dinamis.
* **Perbaikan Alur Pembayaran (Checkout)**: Penyesuaian kalkulasi dan stabilisasi sinkronisasi keranjang belanja ke transaksi sukses.
* **Perbaikan Antarmuka (UI/UX)**: Berbagai perbaikan kecil pada antarmuka *Dashboard* dan *Kasir* (*POS Screen*), serta menyembunyikan fitur Manajemen Meja sementara untuk fokus pada fitur inti kasir ritel/F&B tanpa meja.
* **Halaman Coming Soon KDS**: Menyiapkan pondasi *Kitchen Display System* dengan halaman *placeholder*.