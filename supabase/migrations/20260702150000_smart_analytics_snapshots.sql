-- Smart Analitik: riwayat hasil analisis per toko, disimpan agar tidak perlu
-- selalu memanggil endpoint model. Setiap "Segarkan Analisis" yang berhasil
-- menyimpan satu baris snapshot berisi data seluruh tab (harian/mingguan/
-- bulanan/kustom) sehingga histori dapat dilihat ulang tanpa refetch ke model.

create table public.smart_analytics_snapshots (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),

  business_type text not null default 'Retail',
  store_name text not null default 'Toko POS',

  model_used text,
  api_online boolean not null default false,
  is_local_server boolean not null default false,
  api_server_label text not null default 'HuggingFace Space',
  cold_start_warning text not null default '',

  best_selling_name text not null default 'Belum ada produk',
  total_revenue numeric not null default 0,
  revenue_text text not null default 'Rp 0',

  projected_best_sellers jsonb not null default '[]'::jsonb,
  pricing_recommendations jsonb not null default '[]'::jsonb,
  tab_data jsonb not null default '{}'::jsonb,

  constraint smart_analytics_snapshots_tab_data_check check (jsonb_typeof(tab_data) = 'object'),
  constraint smart_analytics_snapshots_pbs_check check (jsonb_typeof(projected_best_sellers) = 'array'),
  constraint smart_analytics_snapshots_pr_check check (jsonb_typeof(pricing_recommendations) = 'array')
);

comment on table public.smart_analytics_snapshots is 'Riwayat hasil Smart Analitik per toko; setiap baris = satu kali refresh (panggilan ke server prediksi). tab_data menyimpan data siap-tampil untuk tab daily/weekly/monthly/custom agar histori bisa dilihat tanpa refetch ke model.';

create index smart_analytics_snapshots_store_created_idx
  on public.smart_analytics_snapshots (store_id, created_at desc);

alter table public.smart_analytics_snapshots enable row level security;

-- Hanya Owner toko (via stores.owner_id atau store_members.role = 'Owner') yang
-- boleh membaca/menulis — konsisten dengan RBAC /smart-analytics di router.dart
-- (fitur ini owner-only di sisi aplikasi; RLS ini adalah lapisan pertahanan kedua).
create policy "Owners can view their store's analytics snapshots"
on public.smart_analytics_snapshots
for select
to authenticated
using (
  exists (
    select 1 from public.stores s
    where s.id = smart_analytics_snapshots.store_id
      and s.owner_id = (select auth.uid())
  )
  or exists (
    select 1 from public.store_members sm
    where sm.store_id = smart_analytics_snapshots.store_id
      and sm.user_id = (select auth.uid())
      and sm.role = 'Owner'
  )
);

create policy "Owners can insert analytics snapshots for their store"
on public.smart_analytics_snapshots
for insert
to authenticated
with check (
  exists (
    select 1 from public.stores s
    where s.id = smart_analytics_snapshots.store_id
      and s.owner_id = (select auth.uid())
  )
  or exists (
    select 1 from public.store_members sm
    where sm.store_id = smart_analytics_snapshots.store_id
      and sm.user_id = (select auth.uid())
      and sm.role = 'Owner'
  )
);

create policy "Owners can delete their store's analytics snapshots"
on public.smart_analytics_snapshots
for delete
to authenticated
using (
  exists (
    select 1 from public.stores s
    where s.id = smart_analytics_snapshots.store_id
      and s.owner_id = (select auth.uid())
  )
  or exists (
    select 1 from public.store_members sm
    where sm.store_id = smart_analytics_snapshots.store_id
      and sm.user_id = (select auth.uid())
      and sm.role = 'Owner'
  )
);

grant select, insert, delete on public.smart_analytics_snapshots to authenticated;
grant select, insert, delete on public.smart_analytics_snapshots to anon;
