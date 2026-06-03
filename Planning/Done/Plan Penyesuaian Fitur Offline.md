# Plan Penyesuaian & Penyempurnaan Fitur Offline

## 1. Analisis Sistem Saat Ini
Setelah melakukan pengecekan terhadap basis kode aplikasi, berikut adalah kondisi fitur offline (lokal) saat ini:
- **Telah Mendukung Offline:** Penyimpanan lokal (Isar) dan sinkronisasi otomatis via `sync_provider.dart` baru mencakup data `Category` dan `Product`.
- **Belum Mendukung Offline (Kritis):** Transaksi utama (Checkout di `payment_screen.dart`) masih secara langsung memanggil Supabase RPC (`create_transaction_v3`). Artinya jika tidak ada koneksi internet, kasir tidak bisa menyelesaikan pesanan sama sekali.
- **Fitur Lainnya:** Data pendukung seperti `Table` (Meja) dan `Voucher` masih mengambil data langsung secara *online* dan belum dicache dengan utuh di Isar untuk kebutuhan *offline*.

## 2. Langkah 1: Wajib Online Untuk Penggunaan Pertama (Store Initialization)
**Tujuan:** Memastikan aplikasi dapat beroperasi secara mandiri dengan data dasar yang cukup saat *offline*.
- **Implementasi (StoreSelection/Splash):** Pada saat aplikasi dibuka dan pengguna telah login, lakukan pengecekan pada *local database* (Isar) apakah tabel `Store` memiliki minimal 1 data.
- **Kondisi Offline & Kosong:** Jika *database* lokal kosong dan perangkat *offline*, tampilkan peringatan *blocking*: **"Untuk penggunaan pertama kali, wajib terhubung ke internet agar data toko dapat disinkronkan."**
- **Sukses:** Setelah data `Store` diunduh dan tersimpan di lokal, ke depannya aplikasi dapat langsung masuk ke kasir walaupun sedang *offline*.

## 3. Langkah 2: Transisi Fitur ke Mode *Offline-First*
**Tujuan:** Seluruh aktivitas utama (Checkout, Update Meja) harus selalu berhasil dieksekusi secara lokal tanpa delay internet.
- **Model Isar Baru:**
  - Tambahkan `@collection` untuk `TransactionLocal` dan `TransactionItemLocal`.
- **Modifikasi Alur Checkout (`payment_screen.dart`):**
  - Transaksi yang dilakukan selalu disimpan terlebih dahulu ke dalam Isar dengan penanda flag `isSynced = false`.
  - Jika internet tersedia, jalankan sinkronisasi secara otomatis *di background*. Jika terputus, tampilkan pesan kasir: "Transaksi berhasil (Tersimpan Offline)".
- **Pengelolaan Meja & Voucher:** Cache ketersediaan meja dan data voucher ke dalam Isar. Update status meja secara lokal, kemudian sinkronkan ke server secara berkala.

## 4. Langkah 3: Pengembangan `sync_provider.dart`
**Tujuan:** Melengkapi agen sinkronisasi otomatis yang sudah ada.
- Tambahkan logika `_syncTransactions()` dan `_syncTables()` untuk memproses seluruh data di Isar yang memiliki flag `isSynced == false`.
- Eksekusi RPC `create_transaction_v3` dari *queue* lokal satu per satu ke server.
- Update nilai `isSynced = true` di *database* Isar setelah server mengonfirmasi data berhasil masuk.

## 5. Langkah 4: Pembuatan Layar Monitor Sinkronisasi (Sync Monitor)
**Tujuan:** Transparansi kepada pengguna tentang kondisi data aplikasi.
- **Halaman Baru (`SyncMonitoringScreen`):** Tambahkan halaman ini (dapat diakses melalui `SettingsScreen`).
- **Informasi yang Ditampilkan:**
  - Jumlah "Produk / Kategori" belum tersinkronisasi.
  - Jumlah "Transaksi" belum terkirim ke server.
  - Daftar log sinkronisasi terakhir (Sukses / Gagal beserta alasannya).
- **Aksi Manual:** Sediakan tombol raksasa **"Sinkronkan Sekarang"** bagi pengguna yang ingin memaksakan pengiriman data secara manual ketika mereka merasa internet sudah stabil.
- **Indikator Global:** Tampilkan sebuah ikon kecil (misal: *Cloud Sync* merah/hijau) di AppBar menu utama atau POS untuk memberikan peringatan visual jika ada data tertunggak.
