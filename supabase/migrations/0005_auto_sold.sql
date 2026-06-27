-- =============================================================================
-- Auto-mark a listing as SOLD when an order is placed.
--
--   * A buyer is NOT the seller, so the "listings update own" RLS policy
--     (auth.uid() = seller_id) blocks the buyer from updating the listing.
--   * This trigger runs as the function owner (SECURITY DEFINER), which
--     bypasses RLS, so the status flip happens server-side and securely the
--     moment an order row is inserted.
--   * Sellers can still flip a listing back to 'active' manually from the app
--     (allowed by "listings update own").
-- =============================================================================

create or replace function public.mark_listing_sold() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.listings
     set status = 'sold'
   where id = new.listing_id
     and status <> 'sold';
  return new;
end; $$;

drop trigger if exists trg_orders_mark_sold on public.orders;
create trigger trg_orders_mark_sold after insert on public.orders
  for each row execute function public.mark_listing_sold();
