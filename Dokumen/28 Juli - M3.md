# M3 — Model LSTM v2 (Sisi Server)

> **Tanggal**: 28 Juli 2026
> **Induk**: [28 Juli - Improve Fitur LSTM.md](28%20Juli%20-%20Improve%20Fitur%20LSTM.md) §5, §9
> **Ruang lingkup**: repo server model (Python) — **di luar** repo Flutter ini.
> **Status**: belum dikerjakan. Ini satu-satunya milestone yang tersisa.

---

## 1. Kenapa dokumen ini terpisah

M1, M2, M4, dan M5 sudah selesai di repo Flutter, dan migrasi database sudah dijalankan. Yang belum ada tinggal **modelnya sendiri**.

Konsekuensinya konkret dan sengaja dibiarkan terlihat: selama server masih mengembalikan baseline, aplikasi menampilkan label **"Estimasi statistik (pola mingguan)"**, bukan "Prediksi LSTM". Itu bukan bug — itu aturan pelabelan §10 dokumen induk yang bekerja sebagaimana mestinya. Menyelesaikan M3 adalah satu-satunya cara membuat label itu berubah secara sah.

**Sisi klien sudah siap sepenuhnya.** `LstmApiClient` sudah bicara kontrak v2, dan otomatis jatuh ke endpoint v1 kalau v2 belum ada. Artinya server baru bisa dikembangkan dan dirilis **tanpa perlu merilis ulang aplikasi**.

---

## 2. Definition of Done

M3 dianggap selesai bila keempat hal ini terpenuhi:

1. `GET /api/health` merespons < 3 detik saat hangat.
2. `POST /api/v2/forecast` mengembalikan `metadata.model_used = "lstm"` untuk toko dengan ≥ 45 hari data, dan baseline **beserta `fallback_reason`** untuk toko di bawah ambang itu.
3. Laporan backtest lima model tersedia (§6), dan keputusan lolos/tidaknya kriteria produksi sudah diambil serta dicatat.
4. Endpoint v1 lama masih berfungsi, sehingga versi aplikasi yang sudah beredar tidak rusak.

---

## 3. Kontrak API yang harus dipenuhi

Bagian ini adalah spesifikasi yang mengikat: klien sudah ditulis dan diuji terhadap bentuk persis di bawah. Sumber kebenaran di sisi klien ada di `lib/features/reports/data/lstm_api_client.dart` dan `lib/features/reports/models/`.

### 3.1 `GET /api/health`

Dipanggil **sebelum** setiap request berat, dengan timeout 3 detik. Kegagalannya tidak fatal — hanya membuat klien menganggap server dingin.

```json
{ "status": "ok", "model_loaded": true, "model_version": "lstm-v2.1.0", "warm": true }
```

Klien membaca `warm`, dan kalau tidak ada memakai `model_loaded`. Nilainya menentukan timeout request berikutnya:

| `warm` | Timeout `/api/v2/forecast` |
| :---: | :--- |
| `true` | 20 detik |
| `false` / gagal | 60 detik |

> Endpoint ini yang membuat cold start HuggingFace Space tidak lagi diam-diam jatuh ke fallback (T-07). Pastikan ia ringan — jangan memuat model di dalamnya, cukup laporkan status.

### 3.2 `POST /api/v2/forecast`

**Request yang dikirim klien** (persis, dari `ForecastInput.toJson()`):

```json
{
  "store_profile": {
    "business_type": "Cafe",
    "open_on_weekends": true,
    "closed_months": [],
    "open_weekdays": [1, 2, 3, 4, 5, 6, 7],
    "open_hour": 8,
    "close_hour": 21
  },
  "history": {
    "daily":    [{ "date": "2026-01-01", "revenue": 1250000, "tx_count": 34, "item_count": 71 }],
    "hourly":   [{ "date": "2026-01-01", "hour": 12, "revenue": 240000, "tx_count": 8 }],
    "products": [{ "product_id": "…", "product_name": "Kopi Susu Aren", "category": "Minuman",
                   "price": 15000, "qty": 44, "avg_daily_qty": 2.75 }]
  },
  "horizon": { "daily": 30, "hourly": 24 },
  "targets": ["revenue", "traffic", "hourly_traffic", "product_demand"],
  "model": "auto"
}
```

Catatan tentang `open_weekdays`: ISO, `1` = Senin … `7` = Minggu. Ini field baru yang lebih presisi daripada `open_on_weekends`; keduanya dikirim demi kompatibilitas, tapi **utamakan `open_weekdays`**.

**Response yang wajib dikembalikan:**

```json
{
  "metadata": {
    "model_used": "lstm",
    "model_version": "lstm-v2.1.0",
    "fallback_reason": null,
    "input_days": 174,
    "min_days_required": 45,
    "generated_at": "2026-07-28T03:10:00Z"
  },
  "metrics": { "backtest_mape": 0.142, "backtest_rmse": 318221.0, "baseline_mape": 0.231 },
  "daily": [
    { "date": "2026-07-29", "revenue": 1432000, "revenue_low": 1180000,
      "revenue_high": 1690000, "tx_count": 38, "confidence": 0.81 }
  ],
  "hourly": [{ "hour": 12, "tx_count": 9, "share": 0.14, "confidence": 0.72 }],
  "product_demand": [
    { "product_id": "…", "product_name": "Kopi Susu Aren", "category": "Minuman",
      "predicted_qty": 42, "predicted_qty_week": 280, "recommended_qty": 336,
      "confidence": 0.77, "trend": "up" }
  ],
  "recommendations": [
    { "kind": "target_omzet", "title": "Target Omzet Harian", "desc": "", "badge": "TARGET",
      "rationale": "Dihitung dari rata-rata 15 hari aktif terakhir.",
      "payload": { "moderate": 1500000, "aggressive": 1750000 } },
    { "kind": "happy_hour", "title": "Promo Jam Sepi", "desc": "", "badge": "PROMO",
      "rationale": "Jam 15.00 hanya menyumbang 3.1% transaksi harian.",
      "payload": { "discount_percent": 15, "hour_from": 15, "hour_to": 17, "product_ids": [] } }
  ]
}
```

**Aturan yang tidak boleh dilanggar:**

| Aturan | Alasan |
| :--- | :--- |
| `metadata.model_used` ∈ `lstm`, `lstm_finetuned`, `seasonal_naive`, `naive` | Nilai ini **menentukan label di UI**. Nilai tak dikenal otomatis diperlakukan sebagai `seasonal_naive` oleh `ForecastMode.fromApi` — aman, tapi berarti LSTM yang salah nama tidak akan pernah tampil sebagai LSTM. |
| Baseline **wajib** disertai `fallback_reason` | Dipakai UI untuk menjelaskan ke pengguna, dan disimpan ke kolom `smart_analytics_snapshots.fallback_reason`. |
| `daily[].date` unik dan berurutan, format `YYYY-MM-DD` | Klien mencocokkan per tanggal. Tanggal yang tidak dikirim **dilewati**, tidak diekstrapolasi — sengaja, agar horizon yang pendek terlihat apa adanya. |
| `desc` boleh dikosongkan pada `recommendations` | Klien merangkai deskripsinya sendiri dari `payload` supaya format rupiah mengikuti locale perangkat. Kirim angka mentah di `payload`, jangan teks jadi. |
| `revenue_low` / `revenue_high` dikirim berpasangan | Kalau salah satu hilang, pita interval tidak digambar. |

**Nilai `fallback_reason` yang sudah dikenali klien:**

`insufficient_history` · `model_unavailable` · `timeout` · `empty_forecast` · `bad_response` · `parse_error` · `network_error` · `http_<kode>` · `legacy_v1_endpoint` · `offline`

Boleh menambah nilai baru; klien menampilkannya apa adanya.

### 3.3 `POST /api/v2/backtest`

Dipakai untuk laporan skripsi (§6), bukan oleh aplikasi. Bebas bentuknya, asalkan memuat per model dan per horizon: MAE, RMSE, MAPE, sMAPE, dan jumlah sampel. Sediakan juga ekspor CSV.

### 3.4 Kompatibilitas v1 — **jangan dihapus dulu**

Klien memanggil trio lama ini ketika `/api/v2/forecast` membalas **404 atau 405**:

- `POST /api/predict/daily` → `{ n_days, k, open_on_weekends, closed_months, history }`
- `POST /api/recommendations/stock` → `{ predicted_revenue, open_on_weekends, closed_months, category_shares, top_products, history }`
- `POST /api/recommendations/target` → `{ factor, history }` (hanya bila histori ≥ 15 hari)

> ⚠️ **Jebakan yang paling mudah terlewat.** Pada jalur v1, klien menentukan model dari **nama field**, bukan dari `metadata.model_used`, dengan urutan prioritas:
>
> 1. `predicted_revenue_lstm` → dilabeli **LSTM**
> 2. `predicted_revenue` → mengikuti `metadata.model_used`
> 3. `predicted_revenue_seasonal_naive` → dilabeli **seasonal naive**
>
> Jadi kalau LSTM sungguhan dirilis lewat endpoint v1, field-nya **harus** bernama `predicted_revenue_lstm`. Kalau tidak, hasil LSTM akan tetap tampil sebagai "Estimasi statistik". Ini disengaja: nama field adalah bukti yang lebih sulit dipalsukan daripada metadata.

Endpoint v1 baru boleh dihapus satu rilis setelah v2 aktif dan mayoritas pengguna sudah memperbarui aplikasi.

---

## 4. Data & pipeline pelatihan

### 4.1 Sumber data

Cara termudah membangun dataset lintas toko adalah memakai RPC yang sudah ada di produksi:

```sql
-- Per toko, siap dipakai sebagai baris latih.
select public.get_forecast_input(id, 365, 420) from public.stores;
```

Atau langsung agregat mentah untuk ekspor massal:

```sql
select
  t.store_id,
  (t.created_at + interval '7 hours')::date as tanggal,
  sum(t.total_amount) as revenue,
  count(*)            as tx_count
from public.transactions t
where coalesce(t.status, 'Berhasil') = 'Berhasil'
group by 1, 2
order by 1, 2;
```

### 4.2 Realita data yang harus diperhitungkan

Hasil pemeriksaan produksi pada 28 Juli 2026:

| Fakta | Angka | Implikasi untuk M3 |
| :--- | :--- | :--- |
| Total transaksi | 56.493 | Cukup untuk melatih target **revenue** dan **hourly_traffic** |
| Toko terbesar | 56.394 transaksi, **77 hari aktif** | Praktis inilah satu-satunya toko dengan seri panjang |
| Toko kedua | 62 transaksi, 16 hari aktif | Terlalu pendek untuk dilatih sendiri |
| `transaction_items` seluruh database | **130 baris** | Data per produk nyaris tidak ada |
| `transaction_items` milik toko terbesar | **0 baris** | **Target `product_demand` tidak bisa dilatih dari toko ini** |

Dua konsekuensi yang perlu diputuskan di awal, bukan di tengah jalan:

1. **Model global lintas toko tidak bisa diandalkan** dengan komposisi sekarang — hanya satu toko yang punya seri memadai. Praktisnya: latih **satu model pada toko terbesar** dan laporkan apa adanya di skripsi, atau lakukan augmentasi/simulasi data dan **nyatakan terang-terangan** bahwa datanya sintetis.
2. **Target `product_demand` sebaiknya tidak diklaim sebagai keluaran LSTM** untuk sekarang. Klien sudah menyediakan jalur turunan statistik dari riwayat (`LocalForecastEstimator.productDemandFromHistory`), dan itu jawaban yang jujur sampai data itemnya ada. Kalau ingin fitur ini ikut didemokan, isi dulu `transaction_items` untuk toko besar.

### 4.3 Praproses (§9.1 dokumen induk)

- Granularitas harian per toko; seri per jam terpisah untuk target traffic.
- Jendela 180 hari; ambang **45 hari** untuk mengaktifkan LSTM.
- `log1p(revenue)` lalu `MinMaxScaler` per toko; inversi saat inferensi.
- **Hari tutup ditandai `is_closed` dan dikeluarkan dari perhitungan loss** — jangan diimputasi nol. Ini penting: model yang belajar "nol palsu" akan meniru persis kesalahan T-03 yang baru saja dibersihkan dari klien.

### 4.4 Fitur per langkah waktu (§9.2)

| Fitur | Bentuk | Sumber |
| :--- | :--- | :--- |
| `revenue_scaled` | float | `history.daily[].revenue` |
| `tx_count_scaled` | float | `history.daily[].tx_count` |
| `dow` | one-hot 7 | turunan tanggal |
| `is_weekend` | biner | turunan tanggal |
| `day_of_month_sin/cos` | 2 float | siklus gajian/awal-akhir bulan |
| `is_holiday` | biner | kalender libur nasional statis (aset JSON) |
| `is_closed` | biner | `store_profile.open_weekdays` + `closed_months` |
| `business_type` | embedding | `store_profile.business_type` |

### 4.5 Arsitektur & pelatihan (§9.3)

```
LSTM(64, return_sequences=True) → Dropout(0.2) → LSTM(32) → Dense(16, relu) → Dense(horizon)
```

- Sliding window 14 hari → 7 hari; inferensi 30 hari via *recursive rollout*.
- Galat kumulatif rollout dilaporkan sebagai **pelebaran `revenue_low`/`revenue_high`**, bukan disembunyikan.
- Loss `Huber`, `Adam(1e-3)`, `EarlyStopping(patience=10)` pada validasi walk-forward.
- Versi artefak (`lstm-v2.1.0`) dikirim di `metadata.model_version` dan tersimpan di setiap snapshot.

---

## 5. Fallback berjenjang di server

Server tidak boleh gagal total. Urutannya:

```
LSTM (data ≥ 45 hari)
  └─ gagal / data kurang → seasonal naive (y[t-7])
        └─ data < 14 hari → naive (y[t-1])
              └─ tidak ada data sama sekali → HTTP 200 dengan daily: []
```

Setiap tingkat **wajib** mengisi `model_used` dan `fallback_reason` yang sesuai. Kalau `daily` kosong, klien akan menampilkan catatan "prediksi belum tersedia" alih-alih grafik kosong — itu perilaku yang benar, jangan diakali dengan mengirim angka karangan.

---

## 6. Backtest & kriteria lulus

**Protokol**: walk-forward — latih t₀…tₙ, uji tₙ₊₁…tₙ₊₇, geser 7 hari, ulangi.

**Metrik**: MAE, RMSE, MAPE, sMAPE per horizon (H+1, H+3, H+7).

**Lima model pembanding wajib**:

| # | Model | Peran |
| :--- | :--- | :--- |
| 1 | Naive `y[t-1]` | Batas bawah |
| 2 | Seasonal naive `y[t-7]` | **Yang dipakai produksi sekarang** — ini yang harus dikalahkan |
| 3 | Moving average 7 hari | Pembanding statistik |
| 4 | LSTM global | Kandidat utama |
| 5 | LSTM fine-tuned | Kandidat utama |

**Kriteria lulus**: LSTM harus mengalahkan seasonal naive pada MAPE H+1 **dan** H+7 di ≥ 60% toko uji.

> Jika tidak tercapai: **baseline tetap dipakai di produksi**, dan aplikasi tidak boleh menampilkan label "LSTM". Hasil negatif tetap temuan yang sah dan justru lebih kuat secara ilmiah daripada klaim yang tidak terbukti — apalagi dengan komposisi data di §4.2, hasil ini cukup mungkin terjadi. Siapkan pembahasannya sejak awal.

Simpan hasil backtest sebagai CSV sejak percobaan pertama. Mengumpulkannya belakangan jauh lebih mahal.

---

## 7. Saran struktur repo server

```
model-server/
├── app.py                  # FastAPI/Flask: /api/health, /api/v2/*, v1 lama
├── models/
│   ├── lstm.py             # arsitektur & inferensi
│   ├── baselines.py        # naive, seasonal naive, moving average
│   └── artifacts/          # bobot + scaler, diberi versi
├── pipeline/
│   ├── preprocess.py       # §4.3
│   ├── features.py         # §4.4
│   └── train.py
├── evaluation/
│   ├── backtest.py         # §6
│   └── reports/            # CSV untuk lampiran skripsi
├── schemas.py              # validasi request/response §3
└── requirements.txt
```

Deployment mengikuti yang sekarang (HuggingFace Space). URL-nya sudah bisa dioverride tanpa mengubah kode aplikasi:

```bash
flutter run --dart-define=LSTM_HF_URL=https://xxx.hf.space
```

---

## 8. Checklist M3

- [ ] `GET /api/health` (ringan, tanpa memuat model)
- [ ] Skrip praproses (§4.3) + fitur (§4.4)
- [ ] Arsitektur & pelatihan LSTM (§4.5)
- [ ] `POST /api/v2/forecast` sesuai kontrak §3.2
- [ ] Fallback berjenjang + `fallback_reason` di setiap tingkat (§5)
- [ ] `POST /api/v2/backtest` (§3.3)
- [ ] Backtest lima model + tabel perbandingan (§6)
- [ ] **Keputusan kriteria lulus dicatat** — lolos atau tidak, keduanya harus tertulis
- [ ] Verifikasi endpoint v1 lama masih berfungsi (§3.4)
- [ ] Uji end-to-end dengan aplikasi (§9)

---

## 9. Cara uji end-to-end dengan aplikasi

1. Jalankan server lokal, lalu di aplikasi buka **Smart Analitik → pilih server "Lokal"**.
   Untuk HP fisik: `flutter run --dart-define=LSTM_LOCAL_PHYSICAL_URL=http://<ip-komputer>:5000`
2. Tekan **Segarkan Analisis**. Yang harus diperiksa:
   - Banner status berubah menjadi **"Prediksi LSTM"** (hijau), bukan "Estimasi statistik".
   - Grafik menampilkan **pita interval** bila `revenue_low`/`revenue_high` dikirim.
   - Snackbar setelah refresh menyebut mode yang benar.
3. Buka **Akurasi Model** (`/smart-analytics/accuracy`). Titik prediksi tersimpan otomatis ke `ai_forecast_points`; akurasinya baru muncul setelah tanggal yang diprediksi berlalu.
4. Uji jalur gagal — matikan server, lalu Segarkan Analisis. Yang harus terjadi: label turun menjadi **"Estimasi lokal"** dan banner peringatan muncul. Kalau labelnya tetap "LSTM", ada yang salah pada pemetaan mode.
5. Uji cold start — biarkan HF Space tidur > 30 menit, lalu Segarkan. Harus berhasil dalam timeout 60 detik, bukan langsung jatuh ke fallback.

---

## 10. Celah yang diketahui di sisi klien

Bukan bagian M3, tapi perlu ditangani agar hasil M3 terpakai penuh:

| Celah | Dampak | Perbaikan |
| :--- | :--- | :--- |
| `ProductDemand.daysOfStockLeft` tidak pernah diisi pada jalur `refreshAnalytics` — server tidak tahu stok, dan estimator lokal tidak menghitungnya | Cabang "stok habis < 2 hari" pada notifikasi prediksi **tidak pernah aktif**. Badge di layar Stok tetap benar karena `stockForecastProvider` menghitung sendiri dari stok Isar | Hitung `daysOfStockLeft` saat menyusun `productDemand` di provider, memakai stok dari Isar — bukan meminta server, karena server memang tidak punya datanya |
| `transaction_items` nyaris kosong (§4.2) | Saran belanja, badge sisa stok, chip tren, dan filter "Melambat" tidak muncul untuk toko terbesar | Isi ulang `transaction_items`, atau pakai toko kedua sebagai toko demo skripsi |

---

> [!IMPORTANT]
> **Privasi (PRD §6)** — payload ke server model hanya berisi angka agregat: tanggal, omzet, jumlah transaksi, kuantitas per produk, kategori, dan jam. Dilarang mengirim `customer_id`, nama/nomor telepon pelanggan, `cashier_id`, atau data pembayaran. Berlaku juga untuk `/api/v2/backtest` dan untuk dataset pelatihan yang diekspor keluar dari Supabase.
