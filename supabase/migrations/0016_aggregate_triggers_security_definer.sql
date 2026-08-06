-- =============================================================================
-- Fix: cross-user aggregate counters silently never updated.
--
-- sync_review_aggregate(), sync_follow_counts(), and sync_favorite_count()
-- all update a *different* user's/listing's row than the one the invoking
-- user owns — e.g. leaving a review updates the REVIEWEE's rating_avg, not
-- the reviewer's own row. Without SECURITY DEFINER, a trigger function runs
-- with the *invoking user's* privileges, so its update is itself subject to
-- normal RLS. Since "profiles update own" only allows auth.uid() = id (and
-- "listings update own" only allows auth.uid() = seller_id), that update
-- silently touches zero rows — no error, the number just never moves:
--   - Reviewing someone never updates *their* rating_avg/rating_count.
--   - Following someone never updates *their* follower_count (your own
--     following_count is fine — that's your own row).
--   - Favoriting someone else's listing never updates its favorite_count.
--
-- Fix: mark all three SECURITY DEFINER, matching the pattern already used
-- for is_admin(), mark_conversation_read(), increment_listing_view(), etc.
-- Safe here because each function only ever writes a value it recomputes
-- itself from the real source rows (reviews/follows/favorites) — it never
-- takes arbitrary client input, and the source tables have their own RLS.
-- =============================================================================

create or replace function public.sync_review_aggregate() returns trigger
language plpgsql security definer set search_path = public as $$
declare target uuid := coalesce(new.reviewee_id, old.reviewee_id);
begin
  update public.profiles p set
    rating_count = (select count(*) from public.reviews where reviewee_id = target),
    rating_avg   = coalesce((select avg(rating) from public.reviews where reviewee_id = target), 0)
  where p.id = target;
  return null;
end; $$;

create or replace function public.sync_follow_counts() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
    update public.profiles set follower_count  = follower_count  + 1 where id = new.following_id;
  elsif (tg_op = 'DELETE') then
    update public.profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
    update public.profiles set follower_count  = greatest(follower_count  - 1, 0) where id = old.following_id;
  end if;
  return null;
end; $$;

create or replace function public.sync_favorite_count() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    update public.listings set favorite_count = favorite_count + 1 where id = new.listing_id;
  elsif (tg_op = 'DELETE') then
    update public.listings set favorite_count = greatest(favorite_count - 1, 0) where id = old.listing_id;
  end if;
  return null;
end; $$;

-- One-time backfill: recompute every profile's rating aggregate and every
-- listing's favorite count from the real data, so existing reviews/favorites
-- that were silently dropped by the bug above are reflected immediately
-- instead of only affecting future changes.
update public.profiles p set
  rating_count = (select count(*) from public.reviews where reviewee_id = p.id),
  rating_avg   = coalesce((select avg(rating) from public.reviews where reviewee_id = p.id), 0);

update public.profiles p set
  follower_count  = (select count(*) from public.follows where following_id = p.id),
  following_count = (select count(*) from public.follows where follower_id = p.id);

update public.listings l set
  favorite_count = (select count(*) from public.favorites where listing_id = l.id);
