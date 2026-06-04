-- Customer role base schema for Parzello POS Mobile
-- Note: This migration is prepared locally because Supabase CLI is not available in the current environment.

create extension if not exists "pgcrypto";

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade,
  display_name text,
  phone_number text,
  avatar_url text,
  loyalty_points integer not null default 0,
  loyalty_tier varchar(20) not null default 'bronze',
  total_spent numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_orders (
  id uuid primary key default gen_random_uuid(),
  store_id uuid references public.stores(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  transaction_id uuid references public.transactions(id) on delete set null,
  status varchar(30) not null default 'pending',
  table_number text,
  customer_name text,
  notes text,
  items jsonb not null,
  subtotal numeric(12, 2) not null,
  discount_amount numeric(12, 2) not null default 0,
  tax_amount numeric(12, 2) not null default 0,
  total_amount numeric(12, 2) not null,
  payment_method varchar(50),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.customers(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade,
  order_id uuid references public.customer_orders(id) on delete set null,
  type varchar(10) not null,
  points integer not null,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.loyalty_settings (
  id uuid primary key default gen_random_uuid(),
  store_id uuid references public.stores(id) on delete cascade unique,
  is_enabled boolean not null default false,
  points_per_amount numeric(5, 2) not null default 1.0,
  silver_threshold numeric(12, 2) not null default 500000,
  gold_threshold numeric(12, 2) not null default 2000000,
  platinum_threshold numeric(12, 2) not null default 10000000,
  created_at timestamptz not null default now()
);

create index if not exists idx_customers_user_id on public.customers (user_id);
create index if not exists idx_customers_store_id on public.customers (store_id);
create index if not exists idx_customer_orders_store_id on public.customer_orders (store_id);
create index if not exists idx_customer_orders_customer_id on public.customer_orders (customer_id);
create index if not exists idx_customer_orders_status on public.customer_orders (status);
create index if not exists idx_loyalty_transactions_customer_id on public.loyalty_transactions (customer_id);
create index if not exists idx_loyalty_transactions_store_id on public.loyalty_transactions (store_id);

drop trigger if exists trg_touch_customers_updated_at on public.customers;
create trigger trg_touch_customers_updated_at
before update on public.customers
for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_customer_orders_updated_at on public.customer_orders;
create trigger trg_touch_customer_orders_updated_at
before update on public.customer_orders
for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_loyalty_settings_updated_at on public.loyalty_settings;
create trigger trg_touch_loyalty_settings_updated_at
before update on public.loyalty_settings
for each row execute function public.touch_updated_at();

alter table public.customers enable row level security;
alter table public.customer_orders enable row level security;
alter table public.loyalty_transactions enable row level security;
alter table public.loyalty_settings enable row level security;

drop policy if exists "Customers can view own profile" on public.customers;
create policy "Customers can view own profile"
on public.customers
for select
using (auth.uid() = user_id);

drop policy if exists "Customers can update own profile" on public.customers;
create policy "Customers can update own profile"
on public.customers
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Customers can create orders" on public.customer_orders;
create policy "Customers can create orders"
on public.customer_orders
for insert
with check (true);

drop policy if exists "Customers can view own orders" on public.customer_orders;
create policy "Customers can view own orders"
on public.customer_orders
for select
using (
  customer_id in (
    select id
    from public.customers
    where user_id = auth.uid()
  )
);

drop policy if exists "Customers can update own pending orders" on public.customer_orders;
create policy "Customers can update own pending orders"
on public.customer_orders
for update
using (
  customer_id in (
    select id
    from public.customers
    where user_id = auth.uid()
  )
  and status = 'pending'
)
with check (
  customer_id in (
    select id
    from public.customers
    where user_id = auth.uid()
  )
);

drop policy if exists "Staff can view store orders" on public.customer_orders;
create policy "Staff can view store orders"
on public.customer_orders
for all
using (
  store_id in (
    select store_id
    from public.store_members
    where user_id = auth.uid()
  )
);

drop policy if exists "Customers can view own loyalty transactions" on public.loyalty_transactions;
create policy "Customers can view own loyalty transactions"
on public.loyalty_transactions
for select
using (
  customer_id in (
    select id
    from public.customers
    where user_id = auth.uid()
  )
);

drop policy if exists "Staff can manage loyalty settings" on public.loyalty_settings;
create policy "Staff can manage loyalty settings"
on public.loyalty_settings
for all
using (
  store_id in (
    select store_id
    from public.store_members
    where user_id = auth.uid()
  )
);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table public.customers to authenticated;
grant select, insert, update, delete on table public.customer_orders to authenticated;
grant select on table public.loyalty_transactions to authenticated;
grant select, insert, update, delete on table public.loyalty_settings to authenticated;

grant insert on table public.customer_orders to anon;

alter publication supabase_realtime add table public.customer_orders;
