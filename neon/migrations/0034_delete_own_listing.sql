-- =============================================================================
-- 0034 (Neon): sellers can delete their own listings
--
-- delete_my_listing(listing) decides what "delete" can safely mean:
--   * an order still in progress (pending / accepted / sent) -> refused
--     ("listing_has_open_order"), so no buyer is left hanging;
--   * only finished orders (delivered / cancelled) -> the listing becomes
--     'removed': gone from the feed, search and profiles, but still readable
--     by the people in those orders, whose history points to it (orders
--     can't lose their item: orders_listing_id_fkey is ON DELETE RESTRICT);
--   * never ordered -> deleted for real (photos, favourites and offers go
--     with it; the nightly photo cleanup deletes the files).
-- Either way, pending offers are declined first, so their buyers are told.
-- Returns 'deleted' or 'removed'.
--
-- Also: the people in an order or offer can always read that listing, even
-- once it's hidden by an admin or removed by its seller — before, a buyer's
-- own order history lost the item when an admin hid it.
-- =============================================================================

alter table public.listings
  drop constraint if exists listings_status_check,
  add constraint listings_status_check
    check (status in ('active', 'sold', 'hidden', 'removed')) not valid;

create index if not exists orders_listing_idx on public.orders(listing_id);

drop policy if exists "listings readable" on public.listings;
create policy "listings readable" on public.listings
  for select using (
    status not in ('hidden', 'removed')
    or seller_id = auth.uid()
    or exists (
      select 1 from public.orders o
       where o.listing_id = listings.id
         and (o.buyer_id = auth.uid() or o.seller_id = auth.uid())
    )
    or exists (
      select 1 from public.offers f
       where f.listing_id = listings.id
         and f.buyer_id = auth.uid()
    )
  );

create or replace function public.delete_my_listing(p_listing uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  owner_id uuid;
begin
  if uid is null then
    raise exception 'Not signed in';
  end if;

  select seller_id into owner_id
    from public.listings where id = p_listing
     for update;
  if owner_id is null or owner_id <> uid then
    raise exception 'Not your listing';
  end if;

  if exists (
    select 1 from public.orders
     where listing_id = p_listing and status in ('pending', 'paid', 'shipped')
  ) then
    raise exception 'listing_has_open_order';
  end if;

  -- Tell anyone still waiting on an offer (sends their notification).
  update public.offers
     set status = 'declined'
   where listing_id = p_listing and status in ('pending', 'countered');

  if exists (select 1 from public.orders where listing_id = p_listing) then
    update public.listings set status = 'removed' where id = p_listing;
    return 'removed';
  end if;

  delete from public.listings where id = p_listing;
  return 'deleted';
end; $$;

revoke all on function public.delete_my_listing(uuid) from public, anonymous;
grant execute on function public.delete_my_listing(uuid) to authenticated;
