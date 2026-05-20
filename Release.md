### **Versi Sekarang**

**1.3.0+5**

---

### **Nama Release**

**ZelloPOS Auth Refactor & Search Optimization**

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

---

**Versi 1.2.0+4 (Offline & Analytics Update)**

Ringkasan perubahan sejak commit `679b5d0c1e99e1f12ca2aeb6d65899dab6707e61`:

* **Mode Offline & Sinkronisasi Data**: Menambahkan model transaksi lokal berbasis Isar, provider sinkronisasi, pemantauan koneksi, dan halaman monitoring sinkronisasi agar transaksi tetap dapat dicatat saat koneksi tidak stabil.
* **Barcode SKU & Scan di POS**: Menambahkan dukungan pemindaian barcode/SKU di layar kasir dan form produk untuk mempercepat pencarian serta input produk.
* **Smart Analytics**: Mengembangkan halaman analitik pintar dengan visualisasi dan ringkasan performa penjualan yang lebih lengkap.
* **Produk ke Kategori**: Memperkuat pengelolaan kategori produk, termasuk alur penambahan produk ke kategori dan pembaruan tampilan daftar produk/kategori.
* **Perbaikan UI Toast**: Migrasi penggunaan *ShadToast* ke *DelightfulToast* untuk notifikasi antarmuka yang lebih konsisten.
* **Penyempurnaan POS & Pembayaran**: Memperbarui layar POS, detail keranjang, pembayaran, struk, dan riwayat transaksi agar selaras dengan alur offline dan pemindaian barcode.
* **Pembaruan Navigasi & Pengaturan**: Menyesuaikan router, navbar, drawer, serta beberapa halaman pengaturan untuk mengakomodasi fitur sinkronisasi dan perubahan alur aplikasi.
* **Dokumentasi Perencanaan**: Menambahkan dokumen perencanaan fitur offline dan AI sebagai referensi pengembangan lanjutan.

---

**Versi 1.3.0+5 (Auth Refactor & Search Optimization)**

Ringkasan perubahan sejak commit `b8119c8019a4d7be3421acd0fc3eacc8b7052ed0`:

* **Redesain Antarmuka Autentikasi (UI/UX Auth)**: Merancang ulang halaman Login (`login_screen.dart`), Register (`register_screen.dart`), dan Setup Password (`setup_password_screen.dart`) dengan gaya minimalis, elegan, dan warna brand *Vibrant Lime* yang terpadu.
* **Validasi Input Autentikasi Ketat**: Mengimplementasikan pemeriksaan validasi instan untuk memastikan seluruh kolom input tidak kosong sebelum memproses otorisasi, lengkap dengan *toggle show/hide password* yang interaktif.
* **Pencarian POS & Manajemen dengan Debouncing**: Menambahkan utilitas debouncer (`debouncer.dart`) pada bilah pencarian produk layar Kasir/POS (`pos_screen.dart`) serta halaman produk/stok untuk mengoptimalkan performa input dan mencegah lag saat mengetik.
* **Tooltips & Aksesibilitas POS**: Memberikan petunjuk visual (*tooltips*) di setiap tombol ikonik layar POS kasir guna mempercepat adaptasi pengguna.
* **Integrasi Lihat Produk per Kategori**: Memperbarui alur visual pada pengelolaan kategori agar pengguna dapat melihat katalog produk per kategori secara langsung.
