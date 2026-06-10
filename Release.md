### **Versi Sekarang**

**1.6.0+9**

---

### **Nama Release**

**ZelloPOS Customer Portal & Smart Analytics Integration**

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

---

**Versi 1.4.0+6 (Internationalization & Localization Stability)**

Ringkasan perubahan pada rilis ini:

* **Sinkronisasi Preferensi Bahasa Global**: Memindahkan inisialisasi preferensi bahasa ke dalam fungsi `main()` secara synchronous sebelum aplikasi dirintis (`runApp`). Menghilangkan efek kedipan (*flicker*) atau reset bahasa kembali ke default ketika aplikasi dimuat ulang melalui *Hot Restart*.
* **Lokalisasi Penuh Modul Katalog Produk**: Merampungkan lokalisasi 100% pada layar form tambah/edit produk (`product_form_screen.dart`) dan kelola penyesuaian stok cepat (`stock_management_screen.dart`). Menambahkan *dynamic NumberFormat* untuk format mata uang lokal (Rp/$) berbasis perangkat.
* **Fitur Pemilihan Bahasa pada Halaman Autentikasi**: Merancang *floating pill language selector* premium di pojok kanan atas halaman Login dan Register, melokalkan seluruh string kolom input, snackbar error validasi, dan tombol autentikasi Google.

---

**Versi 1.4.0+7 (Firebase Analytics & Security Update)**

Ringkasan perubahan pada rilis ini:

* **Integrasi Izin ID Iklan (AD_ID)**: Menambahkan deklarasi izin `com.google.android.gms.permission.AD_ID` pada file `AndroidManifest.xml` untuk memastikan Firebase Analytics dapat mengakses *Advertising ID* pada perangkat Android 12 (API 31) ke atas demi keandalan pelacakan demografi dan kampanye pemasaran.

---

**Versi 1.5.0+8 (Premium UX & Advanced Inventory Overhaul)**

Ringkasan perubahan pada rilis ini:

* **Redesain Antarmuka "Pilih Toko" (Store Selection)**: Menyederhanakan navigasi AppBar, menambahkan animasi membal (*bouncing scroll*), label peran (*role badges*) yang jelas, serta mengamankan tombol aksi utama (Gabung/Buat Toko) di bagian bawah (*sticky bottom footer*) demi pengalaman pengguna yang premium dan interaktif.
* **Redesain Detail Informasi Toko**: Memodernisasi halaman Informasi Toko dengan struktur *bento cards*, kontrol navigasi melayang (*floating*), pemilih logo squircular interaktif terintegrasi dengan modal bottom sheet, dan kolom input data bisnis yang selaras.
* **Peningkatan Halaman Profil Pengguna**: Menerapkan tata letak estetika *bento-grid*, mengintegrasikan fitur "Ubah Foto Profil" menggunakan kamera/galeri native dengan penyimpanan Supabase Storage, sinkronisasi avatar real-time, serta kartu detail akun yang lebih rapi tanpa terpotong (*text truncation*).
* **Perombakan Manajemen & Riwayat Stok**:
  * Mengganti tombol penambah/pengurang stok kasir sebaris dengan tombol "Ubah Stok" yang membuka modal bottom sheet interaktif untuk integritas data yang lebih baik.
  * Menambahkan halaman **Riwayat Stok** yang melacak seluruh riwayat penyesuaian stok.
  * Menampilkan kategori produk pada bottom sheet pemilihan produk (`_AddProductsBottomSheet`), lengkap dengan label "Tanpa Kategori" untuk produk yang belum dikelompokkan.
* **Standarisasi Branding Hijau POS**: Mengganti semua kode warna lime hijau usang (`0xFF98D100`) dengan warna utama resmi `Warna.primary` (`#9AE600`) di layar Kasir/POS, detail keranjang belanja, dan daftar produk demi harmoni visual premium. Memastikan teks/ikon kontras tinggi menggunakan `Warna.black` untuk keterbacaan optimal.
* **Sistem AppBar Melayang (Floating AppBar)**: Mengimplementasikan desain global transparent/floating rounded AppBar di seluruh modul aplikasi. Mengatur properti `extendBodyBehindAppBar` pada Scaffold secara dinamis agar konten mengalir mulus di bawah header saat di-scroll tanpa saling tumpang tindih.
* **Stabilisasi Sinkronisasi & Perbaikan UI**: Memperbaiki alur sinkronisasi data transaksi offline secara real-time dan memoles elemen UI di beberapa halaman inti untuk memastikan kestabilan aplikasi.

---

**Versi 1.6.0+9 (Customer Portal & Smart Analytics Integration)**

Ringkasan perubahan sejak commit `2730edd9d36634ec58aa185a423a0e8c5f6c2245`:

* **Portal & Fitur Pelanggan (Customer Role)**:
  * **Registrasi & Manajemen Sesi**: Mengintegrasikan `CustomerSessionProvider` untuk menangani status masuk, keluar, dan autentikasi khusus bagi akun pelanggan.
  * **Database & Migrasi Supabase**: Migrasi skema database baru (`20260603000100_customer_role_base.sql`) untuk mendukung profil pelanggan, riwayat poin loyalitas, serta pencatatan pesanan khusus pelanggan.
  * **Antarmuka Utama Pelanggan**: Menyediakan antarmuka dashboard pelanggan (`customer_screens.dart`) lengkap dengan riwayat transaksi, pengaturan profil, pencarian outlet terdekat dengan filter lokasi ter-debounce, dan navigasi bottom bar khusus (`customer_shell_screen.dart`).
  * **Detail Outlet & Katalog Digital**: Halaman khusus toko (`customer_store_detail_screen.dart`) yang menampilkan produk berdasarkan kategori, informasi promo, serta poin loyalitas toko.
  * **Keranjang Belanja & Checkout Mandiri**: Implementasi sistem checkout lokal (`customer_checkout_page.dart`) dan provider keranjang belanja (`customer_cart_provider.dart`) untuk memfasilitasi pesanan langsung dari aplikasi pelanggan.
  * **Pemindaian QR/Barcode**: Layar pemindaian (`customer_scan_screen.dart`) menggunakan `mobile_scanner` untuk memudahkan pelanggan melakukan check-in toko atau scan produk.
* **Onboarding Screen Premium**:
  * Merombak total tampilan layar onboarding (`onboarding_screen.dart`) dengan ilustrasi interaktif, mikro-animasi premium, layout modern, serta implementasi branding warna *Vibrant Lime Green*.
* **Play Store In-App Update**:
  * Menambahkan `UpdateService` (`update_service.dart`) yang terintegrasi dengan modul `in_app_update` untuk mendeteksi pembaruan aplikasi secara otomatis dan memicu dialog pembaruan (fleksibel atau segera) langsung dari dalam aplikasi Google Play.
* **Smart Analytics & Visualisasi Data**:
  * Menyempurnakan visualisasi grafik penjualan, tren produk terlaris, serta laporan performa keuangan interaktif di halaman analitik (`smart_analytics_screen.dart`) yang didukung penuh oleh `SmartAnalyticsProvider`.
* **Navigasi & Komponen UI Global**:
  * Memperkenalkan `PillAppBar` (`pill_appbar.dart`) untuk navigasi melayang berbentuk pil yang modern dan estetis.
  * Penyesuaian `router.dart`, `scaffold_with_navbar.dart`, dan `app_drawer.dart` agar responsif secara dinamis dalam membedakan tampilan menu antara peran Owner/Staf dengan peran Pelanggan.
* **Dokumentasi & Rancangan**:
  * Menambahkan berkas PRD komprehensif, desain sistem (Style), diagram ERD, Use Case, Activity Diagram, serta daftar fitur yang belum selesai (*Unfinished*) untuk panduan pengembangan lanjutan di folder `Dokumen`.

