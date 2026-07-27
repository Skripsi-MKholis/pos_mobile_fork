-- products and users FK to stores had no ON DELETE rule (defaulted to NO ACTION),
-- which silently blocked store deletion whenever a store still had products or staff users.
-- transactions.store_id is intentionally left as NO ACTION: financial/audit records must
-- never be cascade-deleted with a store; store removal should be handled via soft-delete
-- or explicit transaction archival at the application layer instead.

alter table public.products
  drop constraint products_store_id_fkey,
  add constraint products_store_id_fkey
    foreign key (store_id) references public.stores(id) on delete cascade;

alter table public.users
  drop constraint users_store_id_fkey,
  add constraint users_store_id_fkey
    foreign key (store_id) references public.stores(id) on delete set null;
