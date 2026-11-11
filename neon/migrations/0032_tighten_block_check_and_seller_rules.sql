-- =============================================================================
-- 0032: two tightened security rules
--
-- 1. is_blocked_between(a, b) — "has either of these two people blocked
--    the other?" — could be called by anyone through the Data API (even a
--    guest), revealing who blocked whom. Blocks are private (the blocks
--    table shows people only their own). It now gives a real answer only
--    to one of the two people, or to server-side code with nobody signed
--    in; for anyone else it says false. Every rule that uses it passes the
--    signed-in person, so they work exactly as before. Guests can no longer
--    call it at all.
--
-- 2. The offer and order insert rules compared the listing's seller with
--    itself ("l.seller_id = l.seller_id", always true) instead of with the
--    seller on the new row — the same slip 0019 fixed for conversations.
--    validate_offer_security / validate_order_security already refused a
--    wrong seller, so this wasn't exploitable; the rules now check it too.
-- =============================================================================

create or replace function public.is_blocked_between(a uuid, b uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select case
    when auth.uid() is not null
         and auth.uid() is distinct from a
         and auth.uid() is distinct from b
      then false -- not one of the two: reveal nothing
    else exists (
      select 1 from public.blocks
       where (blocker_id = a and blocked_id = b)
          or (blocker_id = b and blocked_id = a)
    )
  end;
$$;

revoke all on function public.is_blocked_between(uuid, uuid) from public, anonymous;
grant execute on function public.is_blocked_between(uuid, uuid) to authenticated;

alter policy "offers buyer insert" on public.offers
  with check (((auth.uid() = buyer_id) AND (buyer_id <> seller_id) AND (NOT is_blocked_between(buyer_id, seller_id)) AND (status = 'pending'::text) AND (order_id IS NULL) AND (EXISTS ( SELECT 1
   FROM listings l
  WHERE ((l.id = offers.listing_id) AND (l.seller_id = offers.seller_id) AND (l.seller_id <> auth.uid()) AND (l.status = 'active'::text))))));

alter policy "orders buyer insert" on public.orders
  with check (((auth.uid() = buyer_id) AND (buyer_id <> seller_id) AND (NOT is_blocked_between(buyer_id, seller_id)) AND (status = 'pending'::text) AND (EXISTS ( SELECT 1
   FROM listings l
  WHERE ((l.id = orders.listing_id) AND (l.seller_id = orders.seller_id) AND (l.seller_id <> auth.uid()) AND (l.status = 'active'::text) AND (l.price = orders.total))))));
