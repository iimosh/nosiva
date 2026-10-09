-- =============================================================================
-- Close a trust-integrity gap: rating_avg, rating_count, follower_count, and
-- following_count on profiles were never protected the way listings'
-- favorite_count/view_count are. "profiles update own" only checks
-- auth.uid() = id, with no column restriction — so a user could set their
-- own rating to 5.0 or fabricate a huge follower count via a raw update.
-- These numbers are the actual trust signal buyers rely on, so this closes
-- it the same way increment_listing_view()/validate_listing_security() did:
-- a guard trigger blocks direct writes, and the legitimate server-side
-- aggregate triggers set a transaction-local bypass flag before they run.
-- =============================================================================

create or replace function public.guard_profile_counters() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (new.rating_avg is distinct from old.rating_avg
      or new.rating_count is distinct from old.rating_count
      or new.follower_count is distinct from old.follower_count
      or new.following_count is distinct from old.following_count)
     and coalesce(current_setting('nosiva.bypass_profile_counter_guard', true), 'false') <> 'true'
     and not public.is_admin() then
    raise exception 'Profile counters are maintained by the server';
  end if;
  return new;
end; $$;

drop trigger if exists trg_guard_profile_counters on public.profiles;
create trigger trg_guard_profile_counters
  before update on public.profiles
  for each row execute function public.guard_profile_counters();

create or replace function public.sync_review_aggregate() returns trigger
language plpgsql security definer set search_path = public as $$
declare target uuid := coalesce(new.reviewee_id, old.reviewee_id);
begin
  perform set_config('nosiva.bypass_profile_counter_guard', 'true', true);
  update public.profiles p set
    rating_count = (select count(*) from public.reviews where reviewee_id = target),
    rating_avg   = coalesce((select avg(rating) from public.reviews where reviewee_id = target), 0)
  where p.id = target;
  return null;
end; $$;

create or replace function public.sync_follow_counts() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform set_config('nosiva.bypass_profile_counter_guard', 'true', true);
  if (tg_op = 'INSERT') then
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
    update public.profiles set follower_count  = follower_count  + 1 where id = new.following_id;
  elsif (tg_op = 'DELETE') then
    update public.profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
    update public.profiles set follower_count  = greatest(follower_count  - 1, 0) where id = old.following_id;
  end if;
  return null;
end; $$;
