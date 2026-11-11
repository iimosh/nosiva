-- =============================================================================
-- 0031: a delivered item can be sold again
--
-- "Does this item already have an order?" counted every order that wasn't
-- cancelled — delivered ones too. So once an item had been sold and
-- delivered, putting it back on sale (Mark as available) made it unsellable:
-- orders were refused and accepted offers were turned into declines.
--
-- Now only orders still in progress — pending, paid (accepted) or shipped —
-- count, in the three places that ask:
--   * validate_order_security          (placing an order)
--   * create_order_from_accepted_offer (accepting an offer)
--   * sync_listing_status_from_order   (back on sale when an order is
--                                        cancelled)
-- Nothing else in these functions changes.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.validate_order_security()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then
    if exists (
      select 1
        from public.orders o
       where o.listing_id = new.listing_id
         and o.status in ('pending', 'paid', 'shipped')
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
     or new.buyer_phone is distinct from old.buyer_phone
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
end; $function$;

CREATE OR REPLACE FUNCTION public.create_order_from_accepted_offer()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
         and o.status in ('pending', 'paid', 'shipped')
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
end; $function$;

CREATE OR REPLACE FUNCTION public.sync_listing_status_from_order()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if (tg_op = 'INSERT') then
    update public.listings
       set status = 'sold'
     where id = new.listing_id
       and status <> 'sold';
    return new;
  end if;

  if (
    tg_op = 'UPDATE'
    and new.status = 'cancelled'
    and old.status is distinct from new.status
  ) then
    update public.listings
       set status = 'active'
     where id = new.listing_id
       and status = 'sold'
       and not exists (
         select 1
           from public.orders o
          where o.listing_id = new.listing_id
            and o.id <> new.id
            and o.status in ('pending', 'paid', 'shipped')
       );
  end if;

  return new;
end; $function$;
