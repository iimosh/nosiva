-- =============================================================================
-- 0021: guest browsing — only signed-in visits count as listing views
--
-- With guest browsing, anyone can open listings without an account. The
-- public "anon" key ships inside the app, so without this anyone could call
-- increment_listing_view() in a loop and inflate a listing's view count.
--
-- Now:
--   * guests (anon) can no longer call the function at all;
--   * the function itself also ignores calls without a signed-in user, and
--     still never counts a seller viewing their own listing.
-- The app already skips the call for guests.
--
-- Safe to run more than once.
-- =============================================================================

create or replace function public.increment_listing_view(listing uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    return;
  end if;
  perform set_config('nosiva.bypass_view_count_guard', 'true', true);
  update public.listings
     set view_count = view_count + 1
   where id = listing
     and seller_id <> auth.uid();
end; $$;

revoke execute on function public.increment_listing_view(uuid) from public, anon;
grant execute on function public.increment_listing_view(uuid) to authenticated;
