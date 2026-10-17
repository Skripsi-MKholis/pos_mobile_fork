-- Migration: Add soft-delete support for products
-- Setting deleted_at prevents FK violations on transaction_items_product_id_fkey
-- while maintaining full historical transaction and analytics accuracy.

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz DEFAULT NULL;

-- Create an index to keep queries fast when filtering active products
CREATE INDEX IF NOT EXISTS idx_products_store_deleted_at 
  ON public.products(store_id, deleted_at);

-- Update RLS or public view policy if desired, or let queries filter deleted_at is null
