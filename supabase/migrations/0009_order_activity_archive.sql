-- =============================================================================
-- Activity: per-user archive state for orders.
--
-- Archiving only hides an order from the current user's Activity list. It does
-- not delete the order and does not hide it from the other participant.
-- =============================================================================

alter table public.orders
  add column if not exists buyer_archived_at timestamptz,
  add column if not exists seller_archived_at timestamptz;

create index if not exists orders_buyer_activity_visible_idx
  on public.orders(buyer_id, activity_at desc)
  where buyer_archived_at is null;

create index if not exists orders_seller_activity_visible_idx
  on public.orders(seller_id, activity_at desc)
  where seller_archived_at is null;

create or replace function public.sync_order_activity_seen() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    new.activity_at = now();
    new.buyer_seen_at = now();
    new.seller_seen_at = null;
    new.buyer_archived_at = null;
    new.seller_archived_at = null;
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

    -- A real new activity should be visible again even if the user previously
    -- archived the order.
    new.buyer_archived_at = null;
    new.seller_archived_at = null;
  end if;

  return new;
end; $$;
