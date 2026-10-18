-- =====================================================================
-- Migrasi: Hapus Fitur Model Prediksi & Smart Analytics (LSTM)
-- Tanggal: 2026-10-18
-- Keterangan: Fitur prediksi penjualan & model forecasting ditiadakan.
-- =====================================================================

-- 1. Hapus RPC functions terkait evaluasi akurasi & input model
DROP FUNCTION IF EXISTS public.evaluate_forecast_points(uuid, integer);
DROP FUNCTION IF EXISTS public.get_forecast_input(uuid, integer, integer);

-- 2. Hapus tabel titik evaluasi prediksi & tabel snapshot analitik
DROP TABLE IF EXISTS public.ai_forecast_points CASCADE;
DROP TABLE IF EXISTS public.smart_analytics_snapshots CASCADE;
