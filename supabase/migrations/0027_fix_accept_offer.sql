-- =============================================================================
-- 0027: accepting an offer works again (same fix as neon/migrations/0029)
--
-- Accepting an offer creates the order (create_order_from_accepted_offer,
-- run as the seller). Two older rules clashed:
--   * sync_order_activity_seen marked every new order "seen by the buyer"
--     (orders normally come from the buyer's cart);
--   * create_order_from_accepted_offer then re-marked it "seen by the
--     seller" with an UPDATE — which validate_order_security (0015) refuses,
--     since a seller may not change the buyer's "seen" state. The whole
--     acceptance was rolled back ("something went wrong").
--
-- Now the new order gets the right "seen" state from the start, based on
-- who creates it (the other person sees it as new), and the follow-up
-- UPDATE is gone. No security rule is loosened.
-- =============================================================================

create or replace function public.sync_order_activity_seen()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if (tg_op = 'INSERT') then
    new.activity_at = now();
    -- Whoever creates the order has seen it; the other person hasn't.
    -- (The seller creates it when accepting an offer.)
    if auth.uid() is not null and auth.uid() = new.seller_id then
      new.seller_seen_at = now();
      new.buyer_seen_at = null;
    else
      new.buyer_seen_at = now();
      new.seller_seen_at = null;
    end if;
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

create or replace function public.create_order_from_accepted_offer()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  created_order_id uuid;
begin
  if (
    new.status = 'accepted'
    and old.status is distinct from new.status
  ) then
    insert into public.orders (listing_id, buyer_id, seller_id, total, status,
                               shipping_address, buyer_phone)
    select new.listing_id, new.buyer_id, new.seller_id, new.amount, 'paid',
           new.shipping_address, new.buyer_phone
    where not exists (
      select 1
        from public.orders o
       where o.listing_id = new.listing_id
         and o.status <> 'cancelled'
    )
    returning id into created_order_id;

    if created_order_id is null then
      update public.offers
         set status = 'declined'
       where id = new.id;
      return new;
    end if;

    -- (The order's "seen" state is set when it's created —
    -- sync_order_activity_seen.)

    update public.offers
       set order_id = created_order_id
     where id = new.id;

    update public.offers
       set status = 'declined'
     where listing_id = new.listing_id
       and id <> new.id
       and status = 'pending';
  end if;

  return new;
end; $$;
