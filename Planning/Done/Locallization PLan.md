# Pelacakan & Rencana Lokalisasi Multi-Bahasa (Localization Plan)

Dokumen ini melacak status implementasi lokalisasi multi-bahasa (Indonesia & Inggris) di seluruh modul aplikasi POS Mobile.

---

## 📊 Ringkasan Status Lokalisasi

| Modul | Total Halaman | Terlokalisasi | Belum Terlokalisasi | Status |
| :--- | :---: | :---: | :---: | :---: |
| **Auth & Onboarding** | 7 | 2 | 5 | 🟡 28% |
| **Dashboard** | 3 | 0 | 3 | 🔴 0% |
| **POS & Transaksi** | 7 | 7 | 0 | 🎉 100% |
| **Katalog Produk** | 4 | 4 | 0 | 🎉 100% |
| **Laporan & Analitik** | 2 | 2 | 0 | 🎉 100% |
| **Pengaturan (Settings)** | 7 | 1 | 6 | 🔴 14% |
| **KDS (Kitchen Display)** | 1 | 0 | 1 | 🔴 0% |
| **TOTAL** | **31** | **16** | **15** | **🟡 51%** |

---

## ✅ Halaman yang SUDAH Terlokalisasi

Berikut adalah daftar halaman/komponen yang telah berhasil dimigrasikan menggunakan `AppLocalizations`:

1. **Auth & Onboarding**
   - `LoginScreen` (`login_screen.dart`) — Halaman masuk dengan input email, password, login Google, dan pemilihan bahasa.
   - `RegisterScreen` (`register_screen.dart`) — Halaman pendaftaran akun baru dengan input data, registrasi Google, dan pemilihan bahasa.
2. **POS & Transaksi**
   - `POSScreen` (`pos_screen.dart`) — Halaman utama POS (keranjang, pencarian barang, scan barcode, dll).
   - `PaymentScreen` (`payment_screen.dart`) — Pilihan metode pembayaran dan nominal bayar.
   - `SplitBillScreen` (`split_bill_screen.dart`) — Fitur pemisahan tagihan pelanggan.
   - `ReceiptScreen` (`receipt_screen.dart`) — Tampilan struk digital, opsi cetak, dan kirim.
   - `CartDetailSheet` (`cart_detail_sheet.dart`) — Bottom sheet detail keranjang belanja.
   - `TransactionHistoryScreen` (`transaction_history_screen.dart`) — Riwayat transaksi penjualan.
3. **Katalog Produk**
   - `ProductListScreen` (`product_list_screen.dart`) — Halaman katalog produk dengan filter dan search.
   - `CategoryListScreen` (`category_list_screen.dart`) — Pengelolaan kategori produk (tambah, edit, hapus kategori).
   - `ProductFormScreen` (`product_form_screen.dart`) — Form tambah/edit produk (nama, harga, kategori, stok, upload gambar).
   - `StockManagementScreen` (`stock_management_screen.dart`) — Halaman cepat penyesuaian stok produk (stock opname).
4. **Laporan & Analitik**
   - `ReportsScreen` (`reports_screen.dart`) — Statistik penjualan, tren produk terlaris, filter waktu.
   - `SmartAnalyticsScreen` (`smart_analytics_screen.dart`) — Halaman analisis prediktif AI (fitur terkunci).
5. **Pengaturan**
   - `SettingsScreen` (`settings_screen.dart`) — Halaman utama pengaturan aplikasi dan bahasa.

---

## 📋 Daftar Halaman yang BELUM Terlokalisasi (To-Do List)

Berikut adalah audit lengkap layar yang masih menggunakan string hardcoded beserta prioritas implementasinya:

### 1. Modul Auth & Onboarding (Prioritas: Medium)
*   **`OnboardingScreen`** (`onboarding_screen.dart`)
    *   *Deskripsi:* Splash screen awal, pengenalan aplikasi, tombol mulai.
*   **`SetupPasswordScreen`** (`setup_password_screen.dart`)
    *   *Deskripsi:* Pembuatan password baru saat pendaftaran.
*   **`CreateStoreScreen`** (`create_store_screen.dart`)
    *   *Deskripsi:* Form input pembuatan toko pertama (nama toko, alamat, no hp).
*   **`StoreSelectionScreen`** (`store_selection_screen.dart`)
    *   *Deskripsi:* Halaman memilih toko yang ingin dikelola.
*   **`ProfileScreen`** (`profile_screen.dart`)
    *   *Deskripsi:* Detail profil pengguna dan tombol logout.

### 2. Modul Dashboard (Prioritas: High)
*   **`DashboardScreen`** (`dashboard_screen.dart`)
    *   *Deskripsi:* Halaman beranda utama dengan menu shortcut, status konektivitas, dan sambutan.
*   **`NotificationCenterScreen`** (`notification_center_screen.dart`)
    *   *Deskripsi:* Riwayat notifikasi sistem dan transaksi.
*   **`BroadcastNotificationScreen`** (`broadcast_notification_screen.dart`)
    *   *Deskripsi:* Halaman pengiriman notifikasi/pengumuman internal.

### 3. Modul Katalog Produk - Sisa (Prioritas: High)
*   *Semua halaman pada modul ini telah terlokalisasi sepenuhnya!*

### 4. Modul Pengaturan - Sisa (Prioritas: Medium)
*   **`StoreInfoScreen`** (`store_info_screen.dart`)
    *   *Deskripsi:* Pengeditan nama toko, alamat, telepon, dan upload logo toko.
*   **`StaffManagementScreen`** (`staff_management_screen.dart`)
    *   *Deskripsi:* Pengelolaan karyawan (tambah staff, atur role/hak akses).
*   **`ManageTablesScreen`** (`manage_tables_screen.dart`)
    *   *Deskripsi:* Pengaturan denah meja untuk restoran.
*   **`ReceiptCustomizationScreen`** (`receipt_customization_screen.dart`)
    *   *Deskripsi:* Kustomisasi konten struk belanja (header, footer, info tambahan).
*   **`SyncMonitoringScreen`** (`sync_monitoring_screen.dart`)
    *   *Deskripsi:* Status sinkronisasi offline-to-online, detail data antrean lokal.
*   **`PrinterSettingsScreen`** (`printer_settings_screen.dart`)
    *   *Deskripsi:* Pencarian & koneksi ke printer bluetooth termal.

### 5. Modul KDS - Kitchen Display System (Prioritas: Low)
*   **`KDSScreen`** (`kds_screen.dart`)
    *   *Deskripsi:* Layar monitor dapur untuk memantau pesanan masuk.

---

## 🛠️ Panduan & Praktik Terbaik Lokalisasi

Saat melanjutkan lokalisasi untuk halaman-halaman di atas, ikuti standar teknis berikut:

1. **Gunakan Parameter Dinamis (Placeholders):**
   * Hindari menggabungkan string secara manual seperti `'Terjadi kesalahan: ' + error`.
   * Definisikan key dengan parameter pada file `.arb`:
     ```json
     "failedToLoad": "Failed to load data: {error}",
     "@failedToLoad": {
       "placeholders": {
         "error": { "type": "String" }
       }
     }
     ```

2. **Gunakan Formatter Mata Uang Berbasis Locale:**
   * Selalu buat format uang responsif terhadap bahasa terpilih:
     ```dart
     final locale = Localizations.localeOf(context).toString();
     final currencyFormat = NumberFormat.currency(
       locale: locale,
       symbol: locale.startsWith('id') ? 'Rp ' : '\$ ',
       decimalDigits: 0,
     );
     ```

3. **Teruskan `BuildContext` pada Fungsi Helper Widget:**
   * Jika ada fungsi helper pembuat widget di luar build tree (misal: `_buildStatCard()`), tambahkan parameter `BuildContext context` agar fungsi tersebut dapat mengakses `AppLocalizations.of(context)`.

4. **Hindari `use_build_context_synchronously` di Fungsi Async:**
   * Ambil instance `l10n` sebelum melakukan operasi async:
     ```dart
     final l10n = AppLocalizations.of(context)!;
     await someAsyncProcess();
     if (mounted) {
       mySnackBar(context: context, text: l10n.successMessage);
     }
     ```
