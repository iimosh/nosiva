-- =============================================================================
-- Offers: Activity state + acceptance flow.
--
-- Offers now appear in Activity for both buyer and seller. When a seller
-- accepts an offer, a real order is created at the offered price.
-- =============================================================================

alter table public.offers
  add column if not exists updated_at timestamptz,
  add column if not exists activity_at timestamptz,
  add column if not exists buyer_seen_at timestamptz,
  add column if not exists seller_seen_at timestamptz,
  add column if not exists buyer_archived_at timestamptz,
  add column if not exists seller_archived_at timestamptz,
  add column if not exists order_id uuid references public.orders(id) on delete set null;

update public.offers
   set updated_at = coalesce(updated_at, created_at, now()),
       activity_at = coalesce(activity_at, created_at, now()),
       buyer_seen_at = coalesce(buyer_seen_at, created_at, now()),
       seller_seen_at = coalesce(seller_seen_at, created_at, now())
 where updated_at is null
    or activity_at is null
    or buyer_seen_at is null
    or seller_seen_at is null;

create index if not exists offers_buyer_activity_visible_idx
  on public.offers(buyer_id, activity_at desc)
  where buyer_archived_at is null;

create index if not exists offers_seller_activity_visible_idx
  on public.offers(seller_id, activity_at desc)
  where seller_archived_at is null;

alter table public.offers replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.offers;
exception
  when duplicate_object then null;
end $$;

create or replace function public.sync_offer_activity() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    new.updated_at = now();
    new.activity_at = now();
    new.buyer_seen_at = now();
    new.seller_seen_at = null;
    new.buyer_archived_at = null;
    new.seller_archived_at = null;
  elsif (tg_op = 'UPDATE') then
    new.updated_at = now();

    if new.status is distinct from old.status then
      new.activity_at = now();
      new.buyer_archived_at = null;
      new.seller_archived_at = null;

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
  end if;

  return new;
end; $$;

drop trigger if exists trg_offers_activity on public.offers;
create trigger trg_offers_activity before insert or update on public.offers
  for each row execute function public.sync_offer_activity();

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
    insert into public.orders (listing_id, buyer_id, seller_id, total, status)
    select new.listing_id, new.buyer_id, new.seller_id, new.amount, 'paid'
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

drop trigger if exists trg_offers_acceptance on public.offers;
create trigger trg_offers_acceptance after update of status on public.offers
  for each row execute function public.create_order_from_accepted_offer();
