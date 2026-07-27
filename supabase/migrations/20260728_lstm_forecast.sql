-- =====================================================================
-- Migrasi: Peningkatan & Perluasan Model LSTM
-- Rujukan: Dokumen/28 Juli - Improve Fitur LSTM.md §6
-- Tanggal: 2026-07-28
--
-- Aman dijalankan berulang (idempoten). Aplikasi Flutter sudah dibuat
-- toleran: bila migrasi ini BELUM dijalankan, fitur tetap berfungsi
-- dengan jalur lama (kolom opsional dilepas saat insert, RPC di-fallback
-- ke query langsung, evaluasi akurasi dilewati).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Kolom tambahan pada smart_analytics_snapshots (§6.1)
-- ---------------------------------------------------------------------
ALTER TABLE public.smart_analytics_snapshots
  ADD COLUMN IF NOT EXISTS model_version   text,
  ADD COLUMN IF NOT EXISTS fallback_reason text,
  ADD COLUMN IF NOT EXISTS input_days      integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS metrics         jsonb   NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS hourly_traffic  jsonb   NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS product_demand  jsonb   NOT NULL DEFAULT '[]'::jsonb,
  -- Menyimpan hasil model + seri historis input sekaligus, sehingga sebuah
  -- snapshot bisa digambar ulang seluruhnya (termasuk rentang tab kustom
  -- yang belum dihitung saat snapshot dibuat).
  ADD COLUMN IF NOT EXISTS forecast_payload jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.smart_analytics_snapshots.model_version IS
  'Versi artefak model, mis. lstm-v2.1.0. Menjaga hasil lama tetap dapat ditelusuri.';
COMMENT ON COLUMN public.smart_analytics_snapshots.fallback_reason IS
  'Alasan server memakai baseline alih-alih LSTM: insufficient_history, model_unavailable, timeout, dst.';
COMMENT ON COLUMN public.smart_analytics_snapshots.forecast_payload IS
  'Objek {forecast, input_daily, profile} — sumber lengkap untuk render ulang snapshot.';

-- ---------------------------------------------------------------------
-- 2. Tabel titik prediksi untuk evaluasi akurasi (§6.2)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_forecast_points (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id      uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  snapshot_id   uuid REFERENCES public.smart_analytics_snapshots(id) ON DELETE CASCADE,
  target_date   date NOT NULL,
  horizon_days  smallint NOT NULL,
  model_used    text NOT NULL,
  predicted_revenue numeric NOT NULL,
  predicted_tx      integer,
  actual_revenue    numeric,
  actual_tx         integer,
  evaluated_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ai_forecast_points_unique UNIQUE (store_id, snapshot_id, target_date)
);

COMMENT ON TABLE public.ai_forecast_points IS
  'Setiap titik prediksi disimpan agar akurasinya bisa diukur setelah tanggalnya lewat. Dasar MAE/RMSE/MAPE pada layar Akurasi Model.';

CREATE INDEX IF NOT EXISTS idx_forecast_points_store_date
  ON public.ai_forecast_points (store_id, target_date DESC);

-- Mempercepat pencarian baris yang belum dievaluasi.
CREATE INDEX IF NOT EXISTS idx_forecast_points_pending
  ON public.ai_forecast_points (store_id, target_date)
  WHERE actual_revenue IS NULL;

ALTER TABLE public.ai_forecast_points ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "member read forecast points" ON public.ai_forecast_points;
CREATE POLICY "member read forecast points" ON public.ai_forecast_points
  FOR SELECT USING (
    store_id IN (
      SELECT store_id FROM public.store_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "member insert forecast points" ON public.ai_forecast_points;
CREATE POLICY "member insert forecast points" ON public.ai_forecast_points
  FOR INSERT WITH CHECK (
    store_id IN (
      SELECT store_id FROM public.store_members WHERE user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- 3. RPC input model (§6.3)
--
-- Menggantikan penarikan baris transaksi mentah ke perangkat (T-04, T-08).
-- Agregasi dikerjakan di server; payload turun dari puluhan MB menjadi
-- beberapa KB, sehingga jendela histori bisa dinaikkan dari 45 ke 180 hari.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_forecast_input(
  p_store_id uuid,
  p_days integer DEFAULT 180,
  p_tz_offset_minutes integer DEFAULT 420
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_offset interval := make_interval(mins => p_tz_offset_minutes);
  v_from   timestamptz := now() - make_interval(days => GREATEST(p_days, 1));
  v_daily    jsonb;
  v_hourly   jsonb;
  v_products jsonb;
  v_active_days integer;
BEGIN
  -- Seri harian: omzet, jumlah transaksi, jumlah item.
  WITH tx AS (
    SELECT
      t.id,
      (t.created_at + v_offset)::date AS local_date,
      EXTRACT(HOUR FROM (t.created_at + v_offset))::int AS local_hour,
      t.total_amount
    FROM public.transactions t
    WHERE t.store_id = p_store_id
      AND t.created_at >= v_from
      AND COALESCE(t.status, 'Berhasil') = 'Berhasil'
  ),
  items AS (
    SELECT tx.local_date, SUM(ti.quantity)::int AS item_count
    FROM tx
    JOIN public.transaction_items ti ON ti.transaction_id = tx.id
    GROUP BY tx.local_date
  )
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'date', to_char(d.local_date, 'YYYY-MM-DD'),
          'revenue', d.revenue,
          'tx_count', d.tx_count,
          'item_count', COALESCE(i.item_count, 0)
        ) ORDER BY d.local_date
      ),
      '[]'::jsonb
    ),
    COUNT(*)::int
  INTO v_daily, v_active_days
  FROM (
    SELECT local_date, SUM(total_amount) AS revenue, COUNT(*)::int AS tx_count
    FROM tx
    GROUP BY local_date
  ) d
  LEFT JOIN items i ON i.local_date = d.local_date;

  -- Seri per jam (input target hourly_traffic / perencanaan shift).
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'date', to_char(h.local_date, 'YYYY-MM-DD'),
        'hour', h.local_hour,
        'revenue', h.revenue,
        'tx_count', h.tx_count
      ) ORDER BY h.local_date, h.local_hour
    ),
    '[]'::jsonb
  )
  INTO v_hourly
  FROM (
    SELECT
      (t.created_at + v_offset)::date AS local_date,
      EXTRACT(HOUR FROM (t.created_at + v_offset))::int AS local_hour,
      SUM(t.total_amount) AS revenue,
      COUNT(*)::int AS tx_count
    FROM public.transactions t
    WHERE t.store_id = p_store_id
      AND t.created_at >= v_from
      AND COALESCE(t.status, 'Berhasil') = 'Berhasil'
    GROUP BY 1, 2
  ) h;

  -- Agregat per produk untuk target product_demand.
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'product_id', p.product_id,
        'product_name', p.product_name,
        'category', p.category,
        'price', p.price,
        'qty', p.qty,
        'avg_daily_qty',
          CASE WHEN v_active_days > 0
               THEN ROUND((p.qty::numeric / v_active_days), 4)
               ELSE 0 END
      ) ORDER BY p.qty DESC
    ),
    '[]'::jsonb
  )
  INTO v_products
  FROM (
    SELECT
      ti.product_id,
      ti.product_name,
      COALESCE(c.name, 'Lain-lain') AS category,
      MAX(ti.unit_price) AS price,
      SUM(ti.quantity)::int AS qty
    FROM public.transactions t
    JOIN public.transaction_items ti ON ti.transaction_id = t.id
    LEFT JOIN public.products pr ON pr.id = ti.product_id
    LEFT JOIN public.categories c ON c.id = pr.category_id
    WHERE t.store_id = p_store_id
      AND t.created_at >= v_from
      AND COALESCE(t.status, 'Berhasil') = 'Berhasil'
    GROUP BY ti.product_id, ti.product_name, c.name
  ) p;

  RETURN jsonb_build_object(
    'daily', v_daily,
    'hourly', v_hourly,
    'products', v_products,
    'active_days', COALESCE(v_active_days, 0),
    'window_days', p_days
  );
END;
$$;

COMMENT ON FUNCTION public.get_forecast_input(uuid, integer, integer) IS
  'Agregat siap-kirim ke server model: seri harian, per jam, dan per produk. Menggantikan penarikan transaksi mentah ke perangkat.';

-- ---------------------------------------------------------------------
-- 4. RPC evaluasi akurasi (§6.2)
--
-- Mengisi kolom actual_* untuk tanggal yang sudah lewat. Dipanggil klien
-- saat layar Smart Analitik dibuka — murah karena hanya menyentuh baris
-- yang belum dievaluasi.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.evaluate_forecast_points(
  p_store_id uuid,
  p_tz_offset_minutes integer DEFAULT 420
)
RETURNS integer
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_offset interval := make_interval(mins => p_tz_offset_minutes);
  v_updated integer;
BEGIN
  WITH pending AS (
    SELECT id, target_date
    FROM public.ai_forecast_points
    WHERE store_id = p_store_id
      AND actual_revenue IS NULL
      AND target_date < ((now() + v_offset)::date)
  ),
  realisasi AS (
    SELECT
      (t.created_at + v_offset)::date AS local_date,
      SUM(t.total_amount) AS revenue,
      COUNT(*)::int AS tx_count
    FROM public.transactions t
    WHERE t.store_id = p_store_id
      AND COALESCE(t.status, 'Berhasil') = 'Berhasil'
      AND (t.created_at + v_offset)::date IN (SELECT target_date FROM pending)
    GROUP BY 1
  )
  UPDATE public.ai_forecast_points fp
  SET
    -- Tanggal tanpa transaksi memang bernilai nol; itu realisasi yang sah,
    -- bukan data hilang.
    actual_revenue = COALESCE(r.revenue, 0),
    actual_tx      = COALESCE(r.tx_count, 0),
    evaluated_at   = now()
  FROM pending p
  LEFT JOIN realisasi r ON r.local_date = p.target_date
  WHERE fp.id = p.id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

COMMENT ON FUNCTION public.evaluate_forecast_points(uuid, integer) IS
  'Mengisi realisasi omzet untuk titik prediksi yang tanggalnya sudah lewat, sebagai dasar perhitungan MAE/RMSE/MAPE.';

-- ---------------------------------------------------------------------
-- 5. Hak akses
-- ---------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.get_forecast_input(uuid, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.evaluate_forecast_points(uuid, integer) TO authenticated;
