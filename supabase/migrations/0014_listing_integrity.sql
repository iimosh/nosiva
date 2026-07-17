-- =============================================================================
-- Listing data integrity: real view tracking + column-level guardrails.
--
-- view_count is displayed on the detail screen but nothing has ever
-- incremented it. The 0012 security trigger (correctly) blocks *any* direct
-- write to view_count, by owner or non-owner alike, so a plain client
-- .update() can't be used — we need a narrow SECURITY DEFINER RPC instead
-- (same pattern as mark_conversation_read/hide_conversation).
--
-- SECURITY DEFINER changes which role RLS evaluates against, but it does NOT
-- suspend triggers — validate_listing_security() still fires and would still
-- reject this RPC's own update. So the RPC sets a transaction-local flag
-- that the trigger explicitly recognizes as "this is the server-side view
-- counter, not a client-supplied value." Every other guard in the trigger is
-- unchanged; a raw client PATCH still cannot move view_count.
--
-- condition/status are only constrained by the Flutter enum today; add DB
-- CHECK constraints matching those enums as defense-in-depth.
-- =============================================================================

create or replace function public.increment_listing_view(listing uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform set_config('nosiva.bypass_view_count_guard', 'true', true);
  update public.listings
     set view_count = view_count + 1
   where id = listing
     and (auth.uid() is null or auth.uid() <> seller_id);
end; $$;

create or replace function public.validate_listing_security()
returns trigger
language plpgsql
security definer
set search_path = public as $$
declare
  view_count_bypassed boolean :=
    coalesce(current_setting('nosiva.bypass_view_count_guard', true), 'false') = 'true';
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
         or (new.view_count is distinct from old.view_count and not view_count_bypassed) then
        raise exception 'Only the seller can edit listing details';
      end if;
    end if;

    if auth.uid() = old.seller_id and not public.is_admin() then
      if new.favorite_count is distinct from old.favorite_count
         or (new.view_count is distinct from old.view_count and not view_count_bypassed) then
        raise exception 'Listing counters are maintained by the server';
      end if;
    end if;
  end if;

  return new;
end; $$;

-- NOT VALID: applies to all new inserts/updates immediately without scanning
-- (and potentially failing on) any existing row that predates this migration.
-- Run `validate constraint` later once existing data is confirmed clean.
alter table public.listings
  drop constraint if exists listings_condition_check,
  add constraint listings_condition_check
    check (condition in ('new_with_tags', 'like_new', 'good', 'fair')) not valid;

alter table public.listings
  drop constraint if exists listings_status_check,
  add constraint listings_status_check
    check (status in ('active', 'sold', 'hidden')) not valid;
