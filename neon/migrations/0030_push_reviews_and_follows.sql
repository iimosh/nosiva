-- =============================================================================
-- 0030 (Neon): notifications for new reviews and new followers
--
--   * new review   -> the person reviewed ("Ana left you a 5-star review")
--   * new follower -> the person followed ("Ana started following you")
--
-- Same path as every other notification (0026): queued in
-- private.push_outbox, never about your own action, never from someone
-- either person blocked, and the action itself never fails because of it.
--
-- Following, unfollowing and following again would otherwise notify every
-- time, so a follow notifies the same person at most once a week.
-- =============================================================================

-- New review -> the person reviewed.
create or replace function private.push_on_review()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform private.queue_push(new.reviewee_id, new.reviewer_id, jsonb_build_object(
    'kind', 'review_new',
    'rating', new.rating,
    'user_id', new.reviewee_id
  ));
  return null;
exception when others then
  raise warning 'push_on_review failed: %', sqlerrm;
  return null;
end; $$;

drop trigger if exists trg_zz_push_reviews on public.reviews;
create trigger trg_zz_push_reviews after insert on public.reviews
  for each row execute function private.push_on_review();

-- When each follower last caused a "new follower" notification.
create table if not exists private.follow_notified (
  follower_id  uuid not null references neon_auth."user"(id) on delete cascade,
  following_id uuid not null references neon_auth."user"(id) on delete cascade,
  notified_at  timestamptz not null default now(),
  primary key (follower_id, following_id)
);
revoke all on private.follow_notified from public, anonymous, authenticated;

-- New follower -> the person followed (at most once a week per follower).
create or replace function private.push_on_follow()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into private.follow_notified as f (follower_id, following_id)
  values (new.follower_id, new.following_id)
  on conflict (follower_id, following_id) do update
     set notified_at = now()
   where f.notified_at < now() - interval '7 days';
  if not found then
    return null; -- already notified this week
  end if;

  perform private.queue_push(new.following_id, new.follower_id, jsonb_build_object(
    'kind', 'follow_new',
    'user_id', new.follower_id
  ));
  return null;
exception when others then
  raise warning 'push_on_follow failed: %', sqlerrm;
  return null;
end; $$;

drop trigger if exists trg_zz_push_follows on public.follows;
create trigger trg_zz_push_follows after insert on public.follows
  for each row execute function private.push_on_follow();
