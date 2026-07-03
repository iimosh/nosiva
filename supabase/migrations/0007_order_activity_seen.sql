-- =============================================================================
-- Activity: unread state for buyer/seller order updates.
--
-- Orders are the single source of truth for Activity. A null seen timestamp
-- means that side has new activity to review.
-- =============================================================================

alter table public.orders
  add column if not exists buyer_seen_at timestamptz,
  add column if not exists seller_seen_at timestamptz;

-- Existing orders should not suddenly appear unread after this migration.
update public.orders
   set buyer_seen_at = coalesce(buyer_seen_at, updated_at, created_at, now()),
       seller_seen_at = coalesce(seller_seen_at, updated_at, created_at, now())
 where buyer_seen_at is null
    or seller_seen_at is null;

alter table public.orders replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.orders;
exception
  when duplicate_object then null;
end $$;

create or replace function public.sync_order_activity_seen() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    new.buyer_seen_at = now();
    new.seller_seen_at = null;
  elsif (tg_op = 'UPDATE' and new.status is distinct from old.status) then
    if auth.uid() = new.seller_id then
      new.seller_seen_at = now();
      new.buyer_seen_at = null;
    elsif auth.uid() = new.buyer_id then
      new.buyer_seen_at = now();
      new.seller_seen_at = null;
    else
      new.buyer_seen_at = null;
      new.seller_seen_at = null;
    end if;
  end if;

  return new;
end; $$;

drop trigger if exists trg_orders_activity_seen on public.orders;
create trigger trg_orders_activity_seen before insert or update on public.orders
  for each row execute function public.sync_order_activity_seen();
