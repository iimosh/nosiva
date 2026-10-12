-- =============================================================================
-- 0024: delivery details on offers, carried over to the order
--
-- When a seller accepts an offer, the order is created automatically (see
-- create_order_from_accepted_offer). Until now those orders had no delivery
-- address or phone, so the seller had to ask in chat. The buyer now gives
-- both when making the offer, and they're copied onto the order.
--
-- Who can see them: only the offer's buyer and seller (offers are readable
-- by their two participants only), then only the order's buyer and seller.
--
-- Same rules as on orders (0023): phone is digits with an optional +, 8–15
-- digits; both fields are fixed once the offer is made.
--
-- The two functions below are 0012's / 0011's versions with only the
-- delivery-detail lines added. NOT VALID: existing offers are untouched.
-- Run after 0023. Safe to run more than once.
-- =============================================================================

alter table public.offers add column if not exists shipping_address text;
alter table public.offers add column if not exists buyer_phone text;

alter table public.offers drop constraint if exists offers_buyer_phone_format;
alter table public.offers
  add constraint offers_buyer_phone_format
  check (buyer_phone is null or buyer_phone ~ '^\+?[0-9]{8,15}$') not valid;

alter table public.offers drop constraint if exists offers_shipping_address_length;
alter table public.offers
  add constraint offers_shipping_address_length
  check (shipping_address is null or char_length(shipping_address) <= 300) not valid;

-- Same limit for addresses typed at checkout.
alter table public.orders drop constraint if exists orders_shipping_address_length;
alter table public.orders
  add constraint orders_shipping_address_length
  check (shipping_address is null or char_length(shipping_address) <= 300) not valid;

create or replace function public.validate_offer_security()
returns trigger
language plpgsql
security definer
set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is null or new.buyer_id <> auth.uid() then
      raise exception 'Offers must be created by their buyer';
    end if;
    if new.buyer_id = new.seller_id then
      raise exception 'Sellers cannot make offers on their own listings';
    end if;
    if new.status <> 'pending' then
      raise exception 'New offers must start as pending';
    end if;
    if new.order_id is not null then
      raise exception 'New offers cannot be linked to an order';
    end if;
    if not exists (
      select 1
        from public.listings l
       where l.id = new.listing_id
         and l.seller_id = new.seller_id
         and l.status = 'active'
    ) then
      raise exception 'Offers can only be made on active listings';
    end if;
    return new;
  end if;

  if new.listing_id is distinct from old.listing_id
     or new.buyer_id is distinct from old.buyer_id
     or new.seller_id is distinct from old.seller_id
     or new.amount is distinct from old.amount
     or new.message is distinct from old.message
     or new.shipping_address is distinct from old.shipping_address
     or new.buyer_phone is distinct from old.buyer_phone
     or new.created_at is distinct from old.created_at then
    raise exception 'Offer core fields cannot be changed';
  end if;

  if new.status is distinct from old.status then
    if auth.uid() <> old.seller_id then
      raise exception 'Only the seller can accept or decline an offer';
    end if;
    if new.order_id is distinct from old.order_id then
      raise exception 'Offer order links are set by the server';
    end if;
    if old.status in ('pending', 'countered')
       and new.status in ('accepted', 'declined') then
      return new;
    end if;
    if old.status = 'accepted'
       and new.status = 'declined'
       and old.order_id is null then
      return new;
    end if;
    raise exception 'Invalid offer status transition';
  end if;

  if new.order_id is distinct from old.order_id then
    if new.order_id is null or not exists (
      select 1
        from public.orders o
       where o.id = new.order_id
         and o.listing_id = new.listing_id
         and o.buyer_id = new.buyer_id
         and o.seller_id = new.seller_id
    ) then
      raise exception 'Offer order link is invalid';
    end if;
    return new;
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

  raise exception 'Only offer participants can update offer activity';
end; $$;

create or replace function public.create_order_from_accepted_offer()
returns trigger
language plpgsql security definer set search_path = public as $$
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

    update public.orders
       set buyer_seen_at = null,
           seller_seen_at = now(),
           activity_at = now()
     where id = created_order_id;

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
