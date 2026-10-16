-- Migration: Menambahkan kolom google_play_product_id ke subscription_plans
-- Memungkinkan konfigurasi Product ID Google Play Billing langsung dari database Supabase

ALTER TABLE subscription_plans 
ADD COLUMN IF NOT EXISTS google_play_product_id text;

-- Update ID default dan harga baru untuk paket-paket yang ada
UPDATE subscription_plans 
SET 
  google_play_product_id = 'com.posmobile.subscription.umkm_hebat',
  price = 49000
WHERE slug IN ('umkm-hebat', 'umkm_hebat');

UPDATE subscription_plans 
SET 
  google_play_product_id = 'com.posmobile.subscription.bisnis',
  price = 99000
WHERE slug IN ('bisnis', 'bisnis-skalabel', 'bisnis_skalabel');

-- Paket gratis tidak memerlukan Google Play Product ID
UPDATE subscription_plans 
SET google_play_product_id = NULL
WHERE price = 0;

