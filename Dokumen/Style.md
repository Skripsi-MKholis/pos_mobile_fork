# Desain Sistem & Panduan Gaya (Style Guide)

Dokumen ini merinci identitas visual, skema warna, tipografi, dan gaya komponen UI yang digunakan dalam aplikasi **Parzello POS**.

---

## 1. Skema Warna (Color Palette)

Aplikasi ini menggunakan perpaduan warna modern berbasis gaya desain **Shadcn UI (Preset: Luma - Stone/Lime)** yang bersih dengan aksen warna hijau limau (*lime green*) yang segar.

### A. Konstanta Warna Global (`Warna` Class)
Didefinisikan di [configuration.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/Configuration/configuration.dart). Digunakan secara langsung pada widget kustom maupun logika UI.

| Nama Warna | Nilai Hex | Representasi Visual | Deskripsi / Penggunaan |
| :--- | :--- | :--- | :--- |
| `primary` | `#9AE600` | 🟩 (Lime Green) | Warna utama untuk tombol primer, status aktif, dan aksen penting. |
| `success` | `#10B981` | 🟢 (Emerald Green) | Warna penanda sukses, penyelarasan (*sync*), dan status online. |
| `destructive`| `#E11D48` | 🔴 (Rose Red) | Warna penanda eror, pembatalan, dan status kegagalan. |
| `neutral` | `#F8FAFC` | ⬜ (Slate 50) | Warna latar belakang kartu ringan dan penampang sekunder. |
| `black` / `textBold` | `#121212` | ⬛ (Charcoal) | Warna teks tebal, teks utama, dan ikon. |
| `bg` | `#FFFFFF` | ⬜ (White) | Warna latar belakang dasar halaman (*light mode*). |
| `line` | `#E2E8F0` | ◽ (Slate 200) | Warna garis pembatas (*divider*) dan border input. |

#### Mode Gelap (Dark Mode Constants)
*Catatan: Meskipun saat ini aplikasi memaksa Light Mode, konstanta ini sudah dipersiapkan:*
* `darkBG`: `#121212`
* `darkSurface`: `#1E1E1E`
* `darkLine`: `#334155`

---

### B. Skema Warna Tema Shadcn (`ShadColorScheme`)
Dikonfigurasi di [main.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/main.dart). Mengatur komponen global dari pustaka `shadcn_ui`.

* **Background / Card / Popover**: `#FFFFFF` (Putih murni)
* **Foreground**: `#0C0A09` (Charcoal hangat - Stone 950)
* **Primary**: `#A5D907` (Lime Green terang)
* **Primary Foreground**: `#1B1B17` (Charcoal kehijauan)
* **Secondary / Muted / Accent**: `#F5F5F4` (Abu-abu terang hangat - Stone 100)
* **Secondary / Accent Foreground**: `#1C1917` (Stone 900)
* **Muted Foreground**: `#78716C` (Abu-abu sedang - Stone 500)
* **Destructive**: `#EF4444` (Merah - Red 500)
* **Destructive Foreground**: `#FBFBFB` (Off-white hangat)
* **Border / Input**: `#E7E5E4` (Stone 200)
* **Ring (Focus indicator)**: `#0C0A09` (Stone 950)

---

## 2. Tipografi & Font

Proyek ini memanfaatkan pustaka `google_fonts` untuk memuat font secara dinamis tanpa perlu menyimpan file ttf secara lokal. Terdapat empat keluarga font (*font family*) yang digunakan:

### A. Space Grotesk
Font bergaya modern-geometris dengan karakteristik tegas.
* **Penggunaan**: Judul besar dan teks penutup yang membutuhkan penekanan tinggi.
* **Lokasi**: [app_theme.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/core/theme/app_theme.dart)
* **Penerapan**:
  * `displayLarge`: Ukuran 32, Tebal (Bold), Warna Hitam/Putih.
  * `headlineMedium`: Ukuran 24, Semi-Tebal (w600), Warna Hitam/Putih.

### B. Outfit
Font sans-serif dengan lekukan halus yang modern dan ramah dibaca.
* **Penggunaan**: Konten teks utama, deskripsi, dan tulisan pada tombol primer.
* **Lokasi**: [app_theme.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/core/theme/app_theme.dart)
* **Penerapan**:
  * `bodyLarge`: Ukuran 16, Warna Hitam 87% / Putih 70%.
  * `bodyMedium`: Ukuran 14, Warna Hitam 54% / Putih 60%.
  * `ElevatedButton`: Gaya Semi-Tebal (w600).

### C. Plus Jakarta Sans
Font bersih dan profesional yang sangat cocok untuk antarmuka aplikasi seluler.
* **Penggunaan**: Semua komponen masukan (*input*), AppBar, item Drawer, dan notifikasi snackbar.
* **Lokasi**: [components.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/Configuration/components.dart)
* **Penerapan**:
  * Judul AppBar: Tebal (Bold).
  * Label Input Field: Tebal (Bold), Ukuran 12.
  * Teks Item Drawer: Tebal (Bold), Ukuran 14.
  * Teks Snackbar: Tebal (w700), Ukuran 14.

### D. Geist Mono
Font monospaced modern.
* **Penggunaan**: Kode unik, label kecil, atau detail teknis.
* **Lokasi**: [app_theme.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/core/theme/app_theme.dart)
* **Penerapan**:
  * `labelSmall`: Ukuran 12, Warna Abu-abu.

---

## 3. Komponen Desain & Konsistensi UI

Elemen UI standar didefinisikan dalam berkas pembantu [components.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/Configuration/components.dart) untuk menjaga konsistensi di seluruh halaman:

### A. Pengaturan Tema Global (Light Mode Only)
Di [main.dart](file:///e:/SKRIPSI/Kholis/pos_mobile_fork/lib/main.dart), aplikasi sengaja mengunci tema ke mode terang:
```dart
themeMode: ThemeMode.light
```
Ini memastikan tampilan antarmuka tetap konsisten dan tidak rusak oleh pengaturan tema gelap bawaan perangkat pengguna.

### B. Tombol Kustom (Buttons)
Menggunakan pembungkus `BounceTapper` untuk memberikan efek visual membal (skala mengecil) saat ditekan, memberikan umpan balik taktil yang memuaskan.
* **`MyButtonPrimary`**: Tombol dengan sudut membulat lebar (`BorderRadius.circular(16.0)`), warna latar belakang abu-abu terang/limau, dan teks hitam.
* **`MyButtonSecondary`**: Versi bergaris tepi (*outlined*) dari `MyButtonPrimary` dengan warna aksen `Warna.primary`.

### C. Bidang Input (Input Fields)
Semua input (`myTextField`, `mySelectField`, `mySelectDate`, `mySelectTime`) memiliki spesifikasi visual yang seragam:
* **Latar Belakang**: `#F6F8FA` (Abu-abu sangat terang).
* **Border**: Tanpa border luar aktif, namun ketika fokus (*focusedBorder*), akan menampilkan efek bayangan berpendar lembut berwarna hijau limau (`Warna.primary.withOpacity(0.2)`).
* **Sudut**: Sudut membulat dengan radius `12.0`.
* **Padding**: Padding vertikal `10` dan horizontal `12` untuk kenyamanan membaca.

### D. Toast & Notifikasi (`mySnackBar`)
Menggunakan pustaka `delightful_toast` dengan gaya melayang (*floating*), warna latar belakang pastel, dan teks berwana kontras sesuai jenis statusnya:
* **Success / Send**: Latar belakang `#E8FAF0` (Hijau pastel) dengan teks `#1AC966`. Ikon: `TablerIcons.circle_check` / `send`.
* **Error**: Latar belakang `#FEE2E2` (Merah pastel) dengan teks merah. Ikon: `TablerIcons.circle_x`.
* **Warning**: Latar belakang `#FFF7CD` (Kuning pastel) dengan teks `#C4841D`. Ikon: `TablerIcons.alert_circle`.
* **Info**: Latar belakang `#E6F1FE` (Biru pastel) dengan teks `#005BC4`. Ikon: `TablerIcons.info_circle`.

### E. Transisi & Efek Visual
* **Pembatas (`MyDivider`)**: Menggunakan garis putus-putus kustom (`DottedDashedLine`) untuk gaya desain neobrutalisme / modern yang bersih.
* **Pemuatan Gambar (`MyNetworkImage`)**: Menggunakan `CachedNetworkImage` yang digabungkan dengan transisi memudar (*shimmer effect*) untuk memberikan transisi mulus saat memuat gambar dari server.
