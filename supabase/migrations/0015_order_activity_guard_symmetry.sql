-- =============================================================================
-- Close an asymmetry in validate_order_security(): the buyer-side guard
-- blocks a buyer from touching seller_seen_at, seller_archived_at, and
-- activity_at — but the seller-side guard only blocked buyer_archived_at,
-- leaving buyer_seen_at and activity_at writable by the seller via a raw
-- update. Impact was cosmetic (suppressing the buyer's unread badge or
-- reordering activity lists), not data loss or unauthorized transactions,
-- but there's no reason to leave it open.
--
-- No client code sends these fields for the seller (markRead/archive only
-- ever touch seller_seen_at/seller_archived_at), so this only removes an
-- unused, unintended permission — nothing in the app changes behavior.
-- =============================================================================

create or replace function public.validate_order_security()
returns trigger
language plpgsql
security definer
set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if exists (
      select 1
        from public.orders o
       where o.listing_id = new.listing_id
         and o.status <> 'cancelled'
    ) then
      raise exception 'This listing already has an active order';
    end if;

    if auth.uid() = new.buyer_id then
      if new.buyer_id = new.seller_id then
        raise exception 'Sellers cannot order their own listings';
      end if;
      if new.status <> 'pending' then
        raise exception 'Buyer-created orders must start as pending';
      end if;
      if not exists (
        select 1
          from public.listings l
         where l.id = new.listing_id
           and l.seller_id = new.seller_id
           and l.status = 'active'
           and l.price = new.total
      ) then
        raise exception 'Orders can only be created for active listings at their current price';
      end if;
      return new;
    end if;

    if auth.uid() = new.seller_id and new.status = 'paid' then
      if not exists (
        select 1
          from public.offers f
         where f.listing_id = new.listing_id
           and f.buyer_id = new.buyer_id
           and f.seller_id = new.seller_id
           and f.amount = new.total
           and f.status = 'accepted'
           and f.order_id is null
      ) then
        raise exception 'Paid orders must come from an accepted offer';
      end if;
      return new;
    end if;

    raise exception 'Order insert is not allowed for this user';
  end if;

  if new.listing_id is distinct from old.listing_id
     or new.buyer_id is distinct from old.buyer_id
     or new.seller_id is distinct from old.seller_id
     or new.total is distinct from old.total
     or new.shipping_address is distinct from old.shipping_address
     or new.stripe_payment_intent is distinct from old.stripe_payment_intent
     or new.created_at is distinct from old.created_at then
    raise exception 'Order core fields cannot be changed';
  end if;

  if new.status is distinct from old.status then
    if old.status in ('delivered', 'cancelled') then
      raise exception 'Completed orders cannot change status';
    end if;

    if auth.uid() = old.seller_id then
      if (old.status = 'pending' and new.status in ('paid', 'cancelled'))
         or (old.status = 'paid' and new.status in ('shipped', 'cancelled'))
         or (old.status = 'shipped' and new.status = 'delivered') then
        return new;
      end if;
      raise exception 'Invalid seller order status transition';
    end if;

    if auth.uid() = old.buyer_id then
      if (old.status = 'pending' and new.status = 'cancelled')
         or (old.status = 'shipped' and new.status = 'delivered') then
        return new;
      end if;
      raise exception 'Invalid buyer order status transition';
    end if;

    raise exception 'Only order participants can update order status';
  end if;

  if auth.uid() = old.buyer_id then
    if new.seller_seen_at is distinct from old.seller_seen_at
       or new.seller_archived_at is distinct from old.seller_archived_at
       or new.activity_at is distinct from old.activity_at then
      raise exception 'Buyer can only update buyer activity state';
    end if;
    return new;
  end if;

  if auth.uid() = old.seller_id then
    if new.buyer_seen_at is distinct from old.buyer_seen_at
       or new.buyer_archived_at is distinct from old.buyer_archived_at
       or new.activity_at is distinct from old.activity_at then
      raise exception 'Seller can only update seller activity state';
    end if;
    return new;
  end if;

  raise exception 'Only order participants can update order activity';
end; $$;
