# Rencana Strategis Penerapan Analitik Real-Time (Firebase Analytics)
## Parzello POS (pos_mobile)

Dokumen ini memetakan rencana perluasan integrasi **Firebase Analytics** di berbagai modul aplikasi Parzello POS. Dengan melacak peristiwa (events) ini secara real-time, pemilik aplikasi dapat memahami perilaku pengguna, memantau kinerja operasional, dan mengukur efisiensi sistem secara kuantitatif.

---

## 📦 1. Modul Produk & Inventaris (`product`)
Pelacakan di modul ini bertujuan untuk menganalisis keaktifan pemilik toko dalam mengelola katalog produk dan memantau fluktuasi stok.

| Nama Event | Parameter | Lokasi Pemicu (Trigger) | Deskripsi / Justifikasi Bisnis |
| :--- | :--- | :--- | :--- |
| `create_product` | `category_name`, `price`, `has_image`, `business_type` | `product_form_screen.dart` | Dilacak ketika produk baru ditambahkan. Membantu mengetahui kategori produk apa yang paling sering dibuat oleh merchant. |
| `update_product` | `price_changed` (bool), `stock_changed` (bool) | `product_form_screen.dart` | Dilacak saat produk diedit. Membantu memantau frekuensi pembaruan harga atau informasi produk. |
| `delete_product` | `category_name` | `product_list_screen.dart` / Form | Dilacak saat produk dihapus. Berguna untuk memahami siklus hidup menu/barang di toko. |
| `create_category` | `category_name` | `category_list_screen.dart` | Dilacak saat merchant membuat kategori produk baru. |
| `adjust_stock` | `product_name`, `adjustment_type` (tambah/kurang), `quantity` | `stock_management_screen.dart` | Dilacak saat stok disesuaikan secara manual (misal: karena barang rusak atau stok masuk manual). Penting untuk audit inventaris. |

---

## 🛒 2. Modul Kasir & Penjualan POS (`pos`)
Selain event transaksi sukses (`purchase`) yang sudah kita buat, interaksi kasir sebelum transaksi selesai sangat penting dipantau untuk mendeteksi *friction points* (kendala transaksi).

| Nama Event | Parameter | Lokasi Pemicu (Trigger) | Deskripsi / Justifikasi Bisnis |
| :--- | :--- | :--- | :--- |
| `apply_voucher` | `voucher_code`, `discount_amount`, `voucher_type` | `cart_detail_sheet.dart` / Payment Screen | Dilacak saat kasir menerapkan voucher belanja. Membantu mengevaluasi efektivitas kampanye promosi. |
| `apply_discount` | `discount_type` (persen/nominal), `amount` | `cart_detail_sheet.dart` | Dilacak saat kasir memberikan diskon manual tanpa voucher. |
| `split_bill` | `table_number`, `original_amount`, `split_count` | `split_bill_screen.dart` | Dilacak saat kasir membagi tagihan (split bill). Membantu memantau seberapa populer fitur pembayaran fleksibel ini di restoran/kafe. |
| `print_receipt` | `printer_connection` (bluetooth/wifi), `is_reprint` (bool) | `receipt_screen.dart` | Dilacak saat struk dicetak. Membantu memantau keandalan perangkat thermal printer pihak ketiga. |
| `table_monitoring_view` | `active_tables_count`, `waiting_orders_count` | `table_monitoring_screen.dart` | Dilacak saat kasir membuka pemantauan meja. Menunjukkan seberapa aktif manajemen meja digunakan. |

---

## 🍳 3. Modul Kitchen Display System (`kds`)
Kitchen Display System (KDS) adalah jantung operasional kafe/restoran. Pelacakan di modul ini berfokus pada **efisiensi waktu penyajian makanan**.

| Nama Event | Parameter | Lokasi Pemicu (Trigger) | Deskripsi / Justifikasi Bisnis |
| :--- | :--- | :--- | :--- |
| `kds_start_cooking` | `order_id`, `item_count` | `kds_screen.dart` (ketika pesanan di-tap untuk mulai dimasak) | Dilacak saat koki mulai memproses pesanan dapur. |
| `kds_order_ready` | `order_id`, `preparation_duration_seconds` | `kds_screen.dart` (ketika pesanan selesai dimasak) | Dilacak saat masakan selesai. Parameter `preparation_duration_seconds` sangat penting untuk mengukur kecepatan pelayanan dapur (Service Level Agreement). |
| `kds_order_served` | `order_id` | `kds_screen.dart` (ketika pesanan diantar ke meja) | Dilacak saat pramusaji mengonfirmasi makanan telah disajikan ke pelanggan. |

---

## ⚙️ 4. Modul Pengaturan & Sinkronisasi (`settings`)
Pelacakan di modul ini membantu mendeteksi masalah teknis, konfigurasi perangkat keras, serta manajemen hak akses (RBAC).

| Nama Event | Parameter | Lokasi Pemicu (Trigger) | Deskripsi / Justifikasi Bisnis |
| :--- | :--- | :--- | :--- |
| `add_staff` | `staff_role` (Kasir/Koki/Admin) | `staff_management_screen.dart` | Dilacak saat merchant menambah karyawan baru. Mengukur rata-rata jumlah staf per merchant. |
| `receipt_customization` | `show_logo` (bool), `header_customized` (bool) | `receipt_customization_screen.dart` | Dilacak saat pemilik kustomisasi tampilan struk belanjanya. |
| `force_manual_sync` | `unsynced_items_count` | `sync_monitoring_screen.dart` | Dilacak ketika pengguna menekan tombol sinkronisasi paksa secara manual. Jika frekuensinya tinggi, bisa menjadi indikasi adanya masalah pada auto-sync latar belakang. |
| `printer_setup_success` | `printer_model`, `connection_type` | `printer_settings_screen.dart` | Dilacak saat printer berhasil terhubung. Berguna untuk memetakan merk/tipe printer terpopuler yang kompatibel. |

---

## 🔔 5. Modul Dashboard & Notifikasi (`dashboard` / `notifications`)
Pelacakan interaksi komunikasi internal antara pemilik toko dan staf.

| Nama Event | Parameter | Lokasi Pemicu (Trigger) | Deskripsi / Justifikasi Bisnis |
| :--- | :--- | :--- | :--- |
| `send_broadcast` | `notification_type` (info/warning/stock), `target_role` | `broadcast_notification_screen.dart` | Dilacak saat pemilik toko mengirim pesan broadcast ke seluruh perangkat staf secara real-time. |
| `tap_notification` | `notification_type` | `notification_center_screen.dart` / System Tray | Dilacak saat staf berinteraksi atau membaca pemberitahuan masuk. Mengukur tingkat responsivitas staf terhadap info penting (misal: stok habis). |

---

## 🚀 Status Implementasi & Langkah Berikutnya

Seluruh rencana penerapan analitik pada **Modul 1 (Produk & Inventaris)** dan **Modul 2 (POS & Penjualan)** telah sepenuhnya diimplementasikan dengan sukses!

### ✅ Modul 1 (Produk & Inventaris) - SELESAI
- `create_product`: Terpasang di `product_form_screen.dart`
- `update_product`: Terpasang di `product_form_screen.dart`
- `delete_product`: Terpasang di `product_list_screen.dart`
- `create_category`: Terpasang di `category_list_screen.dart`
- `adjust_stock`: Terpasang di `stock_management_screen.dart`

### ✅ Modul 2 (POS & Penjualan) - SELESAI
- `apply_voucher`: Terpasang di `cart_detail_sheet.dart`
- `apply_discount`: Wrapper method siap di `AnalyticsService.dart`
- `split_bill`: Terpasang di `split_bill_screen.dart`
- `print_receipt`: Terpasang di `receipt_screen.dart`
- `table_monitoring_view`: Terpasang di `table_monitoring_screen.dart`

### 🍳 Langkah Selanjutnya: Modul 3 Kitchen Display System (KDS)
1. **Event `kds_start_cooking`**: Terapkan pelacakan saat koki men-tap pesanan untuk mulai dimasak.
2. **Event `kds_order_ready`**: Rekam metrik durasi memasak (`preparation_duration_seconds`).
3. **Event `kds_order_served`**: Rekam saat pesanan diantarkan ke meja pelanggan.
