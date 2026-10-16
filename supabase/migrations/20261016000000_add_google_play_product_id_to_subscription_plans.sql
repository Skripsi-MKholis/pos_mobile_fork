-- Migration: Menambahkan kolom google_play_product_id ke subscription_plans
-- Memungkinkan konfigurasi Product ID Google Play Billing langsung dari database Supabase

ALTER TABLE subscription_plans 
ADD COLUMN IF NOT EXISTS google_play_product_id text;

-- Update ID default untuk paket-paket yang ada
UPDATE subscription_plans 
SET google_play_product_id = 'com.posmobile.subscription.umkm_hebat'
WHERE slug IN ('umkm-hebat', 'umkm_hebat');

UPDATE subscription_plans 
SET google_play_product_id = 'com.posmobile.subscription.bisnis'
WHERE slug IN ('bisnis', 'bisnis-skalabel', 'bisnis_skalabel');

-- Paket gratis tidak memerlukan Google Play Product ID
UPDATE subscription_plans 
SET google_play_product_id = NULL
WHERE price = 0;
