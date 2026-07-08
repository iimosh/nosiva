-- =============================================================================
-- Production hardening: ownership, status transitions, and chat image storage.
--
-- RLS decides who may attempt an action; the validation triggers below decide
-- whether the requested state change is actually valid for the marketplace.
-- This prevents a modified client from creating fake orders/offers, changing
-- someone else's activity state, or tampering with conversation metadata.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Chat image storage
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('chat-images', 'chat-images', true)
on conflict (id) do nothing;

drop policy if exists "public read chat images" on storage.objects;
create policy "public read chat images"
  on storage.objects for select
  using (bucket_id = 'chat-images');

drop policy if exists "participants upload chat images" on storage.objects;
create policy "participants upload chat images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[2] = auth.uid()::text
    and exists (
      select 1
        from public.conversations c
       where c.id::text = (storage.foldername(name))[1]
         and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

drop policy if exists "participants update own chat images" on storage.objects;
create policy "participants update own chat images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[2] = auth.uid()::text
    and exists (
      select 1
        from public.conversations c
       where c.id::text = (storage.foldername(name))[1]
         and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  )
  with check (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[2] = auth.uid()::text
    and exists (
      select 1
        from public.conversations c
       where c.id::text = (storage.foldername(name))[1]
         and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

drop policy if exists "participants delete own chat images" on storage.objects;
create policy "participants delete own chat images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[2] = auth.uid()::text
    and exists (
      select 1
        from public.conversations c
       where c.id::text = (storage.foldername(name))[1]
         and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

-- -----------------------------------------------------------------------------
-- Conversation/message rules
-- -----------------------------------------------------------------------------
drop policy if exists "conversations buyer insert" on public.conversations;
create policy "conversations buyer insert"
  on public.conversations for insert
  with check (
    auth.uid() = buyer_id
    and buyer_id <> seller_id
    and (
      listing_id is null
      or exists (
        select 1
          from public.listings l
         where l.id = listing_id
           and l.seller_id = seller_id
           and l.seller_id <> auth.uid()
           and l.status <> 'hidden'
      )
    )
  );

-- Clients should not directly mutate conversation metadata. Message triggers and
-- mark_conversation_read() maintain last_message and unread counters.
drop policy if exists "conversations participants update" on public.conversations;

alter table public.messages
  drop constraint if exists messages_body_or_image_check,
  add constraint messages_body_or_image_check
    check (length(trim(body)) > 0 or image_url is not null);

drop policy if exists "messages sender insert" on public.messages;
create policy "messages sender insert"
  on public.messages for insert
  with check (
    auth.uid() = sender_id
    and (length(trim(body)) > 0 or image_url is not null)
    and exists (
      select 1
        from public.conversations c
       where c.id = conversation_id
         and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

-- -----------------------------------------------------------------------------
-- Listing rules
-- -----------------------------------------------------------------------------
drop policy if exists "listings update own" on public.listings;
create policy "listings update own"
  on public.listings for update
  using (auth.uid() = seller_id)
  with check (auth.uid() = seller_id);

create or replace function public.validate_listing_security()
returns trigger
language plpgsql
security definer
set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is null or new.seller_id <> auth.uid() then
      raise exception 'Listings must be created by their seller';
    end if;
    if new.status <> 'active' then
      raise exception 'New listings must start as active';
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if new.seller_id is distinct from old.seller_id then
      raise exception 'Listing seller cannot be changed';
    end if;

    -- Server-maintained counters and order triggers may update these fields.
    -- Direct client writes from non-owners are still blocked by RLS.
    if auth.uid() is distinct from old.seller_id and not public.is_admin() then
      if new.title is distinct from old.title
         or new.description is distinct from old.description
         or new.category is distinct from old.category
         or new.brand is distinct from old.brand
         or new.size is distinct from old.size
         or new.condition is distinct from old.condition
         or new.color is distinct from old.color
         or new.price is distinct from old.price
         or new.style_tags is distinct from old.style_tags
         or new.location is distinct from old.location
         or new.view_count is distinct from old.view_count then
        raise exception 'Only the seller can edit listing details';
      end if;
    end if;

    if auth.uid() = old.seller_id and not public.is_admin() then
      if new.favorite_count is distinct from old.favorite_count
         or new.view_count is distinct from old.view_count then
        raise exception 'Listing counters are maintained by the server';
      end if;
    end if;
  end if;

  return new;
end; $$;

drop trigger if exists trg_listings_security on public.listings;
create trigger trg_listings_security before insert or update on public.listings
  for each row execute function public.validate_listing_security();

-- -----------------------------------------------------------------------------
-- Offer rules
-- -----------------------------------------------------------------------------
drop policy if exists "offers buyer insert" on public.offers;
create policy "offers buyer insert"
  on public.offers for insert
  with check (
    auth.uid() = buyer_id
    and buyer_id <> seller_id
    and status = 'pending'
    and order_id is null
    and exists (
      select 1
        from public.listings l
       where l.id = listing_id
         and l.seller_id = seller_id
         and l.seller_id <> auth.uid()
         and l.status = 'active'
    )
  );

drop policy if exists "offers participants update" on public.offers;
create policy "offers participants update"
  on public.offers for update
  using (auth.uid() = buyer_id or auth.uid() = seller_id)
  with check (auth.uid() = buyer_id or auth.uid() = seller_id);

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

drop trigger if exists trg_offers_security on public.offers;
create trigger trg_offers_security before insert or update on public.offers
  for each row execute function public.validate_offer_security();

-- -----------------------------------------------------------------------------
-- Order rules
-- -----------------------------------------------------------------------------
drop policy if exists "orders buyer insert" on public.orders;
create policy "orders buyer insert"
  on public.orders for insert
  with check (
    auth.uid() = buyer_id
    and buyer_id <> seller_id
    and status = 'pending'
    and exists (
      select 1
        from public.listings l
       where l.id = listing_id
         and l.seller_id = seller_id
         and l.seller_id <> auth.uid()
         and l.status = 'active'
         and l.price = total
    )
  );

drop policy if exists "orders participants update" on public.orders;
create policy "orders participants update"
  on public.orders for update
  using (auth.uid() = buyer_id or auth.uid() = seller_id)
  with check (auth.uid() = buyer_id or auth.uid() = seller_id);

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
    if new.buyer_archived_at is distinct from old.buyer_archived_at then
      raise exception 'Seller can only update seller activity state';
    end if;
    return new;
  end if;

  raise exception 'Only order participants can update order activity';
end; $$;

drop trigger if exists trg_orders_security on public.orders;
create trigger trg_orders_security before insert or update on public.orders
  for each row execute function public.validate_order_security();

-- -----------------------------------------------------------------------------
-- Review rules
-- -----------------------------------------------------------------------------
drop policy if exists "reviews insert own" on public.reviews;
create policy "reviews insert own"
  on public.reviews for insert
  with check (
    auth.uid() = reviewer_id
    and reviewer_id <> reviewee_id
    and exists (
      select 1
        from public.orders o
       where o.id = order_id
         and o.status = 'delivered'
         and (
           (o.buyer_id = reviewer_id and o.seller_id = reviewee_id)
           or (o.seller_id = reviewer_id and o.buyer_id = reviewee_id)
         )
    )
  );

drop policy if exists "reviews update own" on public.reviews;
create policy "reviews update own"
  on public.reviews for update
  using (auth.uid() = reviewer_id)
  with check (
    auth.uid() = reviewer_id
    and reviewer_id <> reviewee_id
    and exists (
      select 1
        from public.orders o
       where o.id = order_id
         and o.status = 'delivered'
         and (
           (o.buyer_id = reviewer_id and o.seller_id = reviewee_id)
           or (o.seller_id = reviewer_id and o.buyer_id = reviewee_id)
         )
    )
  );
