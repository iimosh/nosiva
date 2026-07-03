-- =============================================================================
-- Activity: stable event time for order cards.
--
-- `updated_at` also changes when an order is marked as read, so the UI should
-- not use it as the visible activity time. `activity_at` changes only when a
-- new order is created or the order status changes.
-- =============================================================================

alter table public.orders
  add column if not exists activity_at timestamptz;

update public.orders
   set activity_at = coalesce(activity_at, updated_at, created_at, now())
 where activity_at is null;

create index if not exists orders_activity_idx
  on public.orders(activity_at desc);

create or replace function public.sync_order_activity_seen() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    new.activity_at = now();
    new.buyer_seen_at = now();
    new.seller_seen_at = null;
  elsif (tg_op = 'UPDATE' and new.status is distinct from old.status) then
    new.activity_at = now();

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
