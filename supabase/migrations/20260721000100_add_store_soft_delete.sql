-- Soft-delete support for stores. Hard-deleting a store is still blocked by
-- transactions.store_id (ON DELETE NO ACTION, intentional — see
-- 20260721000000_fix_store_fk_delete_rules.sql). "Deleting" a store from the
-- app should set deleted_at instead of issuing a DELETE, so financial records
-- stay intact and the store simply disappears from all normal queries/RLS.

alter table public.stores
  add column deleted_at timestamptz;

drop policy "Anyone can view stores" on public.stores;
create policy "Anyone can view stores" on public.stores
  for select
  using (deleted_at is null);

drop policy "Stores viewable by members." on public.stores;
create policy "Stores viewable by members." on public.stores
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from store_members
      where store_members.store_id = stores.id
        and store_members.user_id = auth.uid()
    )
  );

drop policy "Users can view stores they are members of" on public.stores;
create policy "Users can view stores they are members of" on public.stores
  for select
  using (
    deleted_at is null
    and (
      auth.uid() = owner_id
      or exists (
        select 1 from store_members
        where store_members.store_id = stores.id
          and store_members.user_id = auth.uid()
      )
    )
  );

-- "Admins can manage all stores" and "Owners can manage their stores" are left
-- unfiltered on purpose, so owners/admins can still see and restore a
-- soft-deleted store.
