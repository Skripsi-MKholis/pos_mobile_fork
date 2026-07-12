# Planning — Enhance Fitur Struk & Kelola Struk

> Status: **PLANNING**
> Target: Fitur Struk (receipt) & Kustomisasi Struk pada Parzello POS
> Tanggal: 12 Juli 2026

---

## 1. Latar Belakang & Masalah Saat Ini

Fitur struk saat ini sudah memiliki layar kustomisasi (`lib/features/settings/presentation/receipt_customization_screen.dart`) dengan pengaturan disimpan di `stores.settings.receipt` (JSON di Supabase, via `activeStoreProvider.updateSettings`). Struk dirender di 3 tempat yang **masing-masing hardcode/duplikat logika**:

| Lokasi | File | Masalah |
|---|---|---|
| Layar struk in-app + share teks | `lib/features/pos/presentation/receipt_screen.dart` | Kasir hardcode `l10n.parzelloStaff` ("Staf Parzello") — baris 288 & 570 |
| Print thermal Bluetooth | `lib/core/services/printer_service.dart` | Kasir hardcode `"Staf Parzello"` — baris 83 |
| Pratinjau kustomisasi | `receipt_customization_screen.dart` | Kasir hardcode `'Staf Parzello'` — baris 999 |

Masalah utama:

1. **Nama kasir tidak bisa diatur** — selalu tampil "Staf Parzello", padahal `transactions.cashier_id` sudah tersimpan (diisi `supabase.auth.currentUser.id` di `payment_screen.dart:436,517`) dan nama staf sudah ada di tabel `profiles` (`full_name`, dipakai `staff_management_screen.dart:881`). Data ada, hanya tidak dipakai.
2. **Logika parsing settings struk terduplikasi 3x** (receipt_screen, printer_service, customization screen) — rawan tidak sinkron saat menambah field baru.
3. Beberapa keterbatasan lain: tidak ada nomor struk kustom, tidak ada info pajak/diskon di struk, tidak ada share sebagai gambar/PDF, tidak ada pilihan lebar kertas printer (58mm vs 80mm), tidak ada test print dari layar kustomisasi.

---

## 2. Tujuan

1. Nama kasir pada struk **otomatis mengikuti akun yang login** (dari `profiles.full_name`), dengan **opsi override manual** ("Nama Kasir Kustom") di Kelola Struk.
2. Sentralisasi konfigurasi & data struk ke satu model agar 3 renderer konsisten.
3. Menambah opsi kustomisasi yang paling berdampak bagi UMKM (prefix no. struk, lebar kertas, test print, share gambar).

---

## 3. Rancangan Solusi

### Fase 1 — Nama Kasir Dinamis (prioritas utama)

**3.1. Sumber nama kasir (urutan fallback):**
1. `settings.receipt.cashier_name` (override manual dari Kelola Struk) — jika diisi.
2. `profiles.full_name` milik `cashier_id` transaksi (untuk histori) / user login (untuk transaksi baru).
3. Fallback terakhir: `l10n.parzelloStaff` ("Staf Parzello") — perilaku lama, untuk data offline tanpa profil.

**3.2. Implementasi:**
- Buat provider `cashierNameProvider` (Riverpod, `@riverpod`) di `lib/features/auth/providers/` yang mengambil `full_name` profil user login, dengan cache + fallback offline (simpan nama terakhir ke SharedPreferences agar tetap tampil saat offline).
- Saat transaksi dibuat di `payment_screen.dart`, sertakan `cashier_name` (snapshot) ke map transaksi yang dikirim ke `ReceiptScreen` dan `PrinterService` — snapshot penting agar struk histori tidak berubah kalau nama staf diganti.
- Untuk histori transaksi (`transaction_history_provider.dart`): tampilkan nama via join/lookup `profiles` berdasarkan `cashier_id` (query Supabase `select('*, profiles(full_name)')` atau lookup terpisah); jika gagal → fallback.
- `receipt_screen.dart:288,570`, `printer_service.dart:83`, dan pratinjau `receipt_customization_screen.dart:999` diganti dari hardcode ke nilai resolusi di atas.

**3.3. UI di Kelola Struk (bagian "LAINNYA"):**
- Di bawah toggle "Tampilkan Nama Kasir", tambah input `Nama Kasir Kustom` (muncul hanya jika toggle aktif), placeholder: *"Kosongkan untuk memakai nama akun yang login"*.
- Pratinjau real-time menampilkan: override → nama user login → "Staf Parzello".
- Field baru di `_settings` / `_initialSettings` / `_hasChanges`: `cashier_name`.

### Fase 2 — Refactor: Model `ReceiptConfig` Terpusat

- Buat `lib/core/models/receipt_config.dart`: class `ReceiptConfig` dengan factory `ReceiptConfig.fromStore(Map store)` yang membaca `settings.receipt` + fallback default (menggantikan parsing manual `receiptSettings['x'] ?? default` yang terduplikasi).
- Field: `storeName, address, phone, headerMessage, footerMessage, websiteUrl, freeText, cashierName, showLogo, showAddress, showPhone, showHeaderMessage, showFooterMessage, showCashier, showQrCode` + field baru Fase 3.
- `printer_service.dart`, `receipt_screen.dart`, `receipt_customization_screen.dart` dikonversi memakai model ini. Tidak perlu build_runner (bukan Isar/Riverpod codegen).

### Fase 3 — Enhancement Kustomisasi Tambahan

Diurutkan berdasarkan dampak:

1. **Prefix No. Struk kustom** (`receipt_number_prefix`, default `PRZ`) — dipakai di `receipt_screen`, `printer_service` (`#PRZ-XXXXXX` → `#<PREFIX>-XXXXXX`), dan pratinjau.
2. **Lebar kertas printer** (`paper_width`: `58` / `80`) — memengaruhi jumlah karakter separator & ukuran font di `printer_service.dart` (sekarang hardcode 32 char/58mm).
3. **Test Print** — tombol di Kelola Struk untuk mencetak struk contoh (data mock sama seperti pratinjau) via `PrinterService`, agar owner bisa cek hasil tanpa transaksi sungguhan. Tampilkan error jelas jika printer belum terhubung.
4. **Share struk sebagai gambar** — bungkus widget struk di `receipt_screen.dart` dengan `RepaintBoundary` + `screenshot`/`toImage`, share via `share_plus` (saat ini share hanya berupa teks polos). Opsi share: Teks / Gambar.
5. **Tampilkan Ringkasan Item di meta struk** (opsional, `show_payment_method` toggle) — metode bayar saat ini selalu tampil; jadikan opsional agar konsisten dengan toggle lain.
6. **Ucapan berbasis nama pelanggan** (jika transaksi punya customer): "Pelanggan: <nama>" di bawah baris Kasir (toggle `show_customer`, default off).

### Fase 4 — Konsistensi Struk Online (QR)

- QR mengarah ke `https://parzello-pos.vercel.app/receipt/<id>` (`printer_service.dart:148`). Pastikan halaman web struk online juga menampilkan nama kasir & pengaturan yang sama (di luar scope repo ini — catat sebagai tindak lanjut; minimal pastikan data `cashier_name`/`cashier_id` ikut tersinkron ke Supabase via `sync_provider.dart` yang sudah mengirim `p_cashier_id`).

---

## 4. Perubahan Data / Skema

- **Tidak ada migrasi tabel baru.** Semua setting baru masuk `stores.settings.receipt` (JSONB): `cashier_name`, `receipt_number_prefix`, `paper_width`, `show_customer`, `show_payment_method`.
- Semua field baru wajib punya default agar backward-compatible dengan settings lama.
- l10n: tambah key baru di `lib/l10n/*.arb` (mis. `customCashierName`, `testPrint`, `shareAsImage`) lalu `flutter gen-l10n`. Jangan edit `app_localizations*.dart` manual.

## 5. File yang Terdampak

| File | Perubahan |
|---|---|
| `lib/core/models/receipt_config.dart` | **Baru** — model konfigurasi struk |
| `lib/features/auth/providers/cashier_name_provider.dart` (+`.g.dart`) | **Baru** — resolve nama kasir (perlu build_runner) |
| `lib/features/settings/presentation/receipt_customization_screen.dart` | Input nama kasir kustom, prefix struk, paper width, test print, pratinjau dinamis |
| `lib/core/services/printer_service.dart` | Pakai `ReceiptConfig`, kasir dinamis, paper width |
| `lib/features/pos/presentation/receipt_screen.dart` | Kasir dinamis, prefix struk, share sebagai gambar |
| `lib/features/pos/presentation/payment_screen.dart` | Snapshot `cashier_name` ke data transaksi |
| `lib/features/pos/providers/transaction_history_provider.dart` | Lookup nama kasir untuk struk histori |
| `lib/l10n/app_id.arb`, `app_en.arb` | Key l10n baru |

## 6. Urutan Pengerjaan & Estimasi

1. Fase 2 (refactor `ReceiptConfig`) — dikerjakan **duluan** agar fase lain bersih. (~0.5 hari)
2. Fase 1 (nama kasir dinamis + UI override). (~1 hari)
3. Fase 3 poin 1–3 (prefix, paper width, test print). (~1 hari)
4. Fase 3 poin 4–6 (share gambar, toggle tambahan). (~1 hari)
5. Fase 4 (verifikasi sync struk online). (~0.5 hari)

## 7. Testing / Verifikasi

- `flutter analyze` bersih; `flutter pub run build_runner build --delete-conflicting-outputs` setelah provider baru.
- Manual: transaksi baru → struk in-app menampilkan nama akun login; ubah "Nama Kasir Kustom" → struk & pratinjau berubah; kosongkan → kembali ke nama akun; logout/akun tanpa profil → "Staf Parzello".
- Offline: buat transaksi tanpa internet → nama kasir tetap tampil (cache SharedPreferences), sync ke Supabase tetap membawa `cashier_id`.
- Print thermal 58mm: layout tidak pecah dengan nama kasir panjang (truncate ±16 char sisi kanan `printLeftRight`).
- Struk histori lama (tanpa snapshot `cashier_name`) tetap tampil benar via lookup `cashier_id`.

## 8. Risiko & Mitigasi

| Risiko | Mitigasi |
|---|---|
| Nama kasir panjang merusak layout printer 32 char | Truncate + ellipsis sebelum `printLeftRight` |
| Settings lama tanpa field baru | Default di `ReceiptConfig.fromStore` |
| Offline: profil belum ter-cache | Fallback berlapis (override → cache → "Staf Parzello") |
| Histori transaksi dari device lain (cashier_id ≠ user login) | Lookup `profiles` by `cashier_id`, bukan user aktif |
