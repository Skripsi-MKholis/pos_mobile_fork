# Dokumentasi Fitur Sistem POS Mobile (Parzello POS)

Dokumen ini merangkum seluruh fitur, arsitektur data, dan spesifikasi sistem Point of Sale (POS) berbasis Flutter yang dioptimalkan untuk perangkat mobile dan tablet.

---

## 👥 Jenis Pengguna & Peran (Role)

Sistem menggunakan Role-Based Access Control (RBAC) yang divalidasi melalui Supabase RLS:

### 1. Owner (Pemilik Toko)
- **Akses Penuh**: Memiliki kontrol total atas satu atau lebih toko melalui dashboard mobile.
- **Manajemen Inventaris**: Tambah/edit/hapus produk, kategori, dan stok langsung dari kamera ponsel (scan barcode).
- **Konfigurasi Modular**: Mengaktifkan/nonaktifkan fitur (Meja, KDS, Reservasi) sesuai model bisnis.
- **Manajemen Staf**: Mengelola tim melalui undangan email atau **Unique Invite Code**.
- **Analitik Real-time**: Memantau performa toko dari mana saja dengan notifikasi push untuk transaksi besar atau stok rendah.

### 2. Staf / Kasir
- **Operasional Cepat**: Akses ke antarmuka kasir yang dioptimalkan untuk sentuhan.
- **Manajemen Pesanan**: Melayani pelanggan, mengelola meja (untuk F&B), dan memproses pembayaran.
- **Laporan Harian**: Melihat ringkasan penjualan pribadi dalam satu shift.

### 3. Super Admin (System Administrator)
- **Otoritas Global**: Akses ke seluruh data sistem melalui aplikasi admin khusus atau panel web.
- **Governance**: Menangguhkan (Suspend) atau mengaktifkan kembali toko secara global.

---

## 🚀 Fitur Utama

### 1. Adaptive Store Setup & Onboarding
- **Mobile Setup Flow**: Alur pendaftaran toko yang ringkas dan intuitif.
- **Business Model Presets**: Konfigurasi otomatis dalam satu klik (F&B, Retail, Coffee Shop).
- **Feature Toggles**: Kontrol modular untuk mengaktifkan fitur spesifik (Dine-in, KDS, Reservasi) tanpa update aplikasi.

### 2. Multi-Store Ecosystem
- **Store Switcher**: Berpindah antar outlet dengan cepat dari menu drawer atau profil.
- **Invitation System**: Mendukung **Invite Code Fast-track** untuk pendaftaran staf baru tanpa hambatan.

### 3. Antarmuka Kasir (Point of Sale)
- **Optimasi Sentuhan**: Tombol besar, swipe gestures, dan alur checkout yang efisien.
- **Barcode Scanning**: Menggunakan kamera ponsel untuk scan produk secara instan.
- **Split Bill & Pindah Meja**: Fitur fleksibel untuk operasional restoran/kafe.
- **Offline Mode (Experimental)**: Kemampuan memproses transaksi dasar saat koneksi internet terputus dan sinkronisasi otomatis saat kembali online.

### 4. Manajemen Perangkat (Hardware Integration)
- **Thermal Printer**: Koneksi via Bluetooth atau USB untuk cetak struk 58mm/80mm.
- **Label Printer**: Dukungan cetak barcode produk.
- **Cash Drawer**: Trigger laci kasir otomatis setelah pembayaran tunai.

### 5. Kitchen Display System (KDS) Mobile
- **Tablet Interface**: Tampilan khusus tablet untuk area dapur dengan notifikasi suara saat pesanan masuk.
- **Status Tracking**: Update status pesanan (Cooking, Ready) dengan satu ketukan.

### 6. Notifikasi & Komunikasi Internal
- **Push Notifications**: Pemberitahuan real-time untuk stok rendah, pengumuman owner, dan update sistem.
- **Broadcast Hub**: Owner dapat mengirim pesan internal ke seluruh staf yang akan muncul sebagai notifikasi di perangkat mereka.

---

## 🎨 UI/UX Design System (Mobile-Centric)

Sistem mengadopsi estetika **Modern Premium & Ergonomic** yang disesuaikan untuk Flutter:

### 🌈 Palet Warna
- **Primary (Vibrant Lime)**: `Color(0xFFCCFF00)`.
- **Success (Emerald)**: `Color(0xFF10B981)`.
- **Destructive (Ruby)**: `Color(0xFFE11D48)`.

### ✍️ Tipografi
- **Heading (Space Grotesk)**: Karakter modern untuk branding dan angka stats.
- **Sans/Body (Outfit)**: Keterbacaan tinggi untuk daftar produk dan form.
- **Data/Mono (Geist Mono)**: Untuk SKU, ID Transaksi, dan data teknis.

---

## 📊 Model Data (Schema Supabase)

Sistem mobile ini berbagi database yang sama dengan versi web untuk sinkronisasi sempurna:

### Inti Bisnis & Inventaris
- **`stores`**: Metadata toko dengan pengaturan modular (JSONB).
- **`products`**: Katalog produk dengan dukungan scan barcode.
- **`store_members`**: Relasi user-toko dan manajemen role.

### Transaksi & Operasional
- **`transactions`**: Log transaksi lengkap dengan metode pembayaran.
- **`tables` & `kds_orders`**: Manajemen operasional khusus F&B.
- **`vouchers` & `discounts`**: Integrasi sistem promosi.

### Komunikasi & Log
- **`notifications`**: Pusat notifikasi push dan in-app.
- **`broadcasts`**: Pesan internal antar pengguna dalam satu toko.
dentifikasi Super Admin.
