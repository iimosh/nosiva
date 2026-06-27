-- =============================================================================
-- Make profile changes live so a user's follower/following counts (maintained
-- by the sync_follow_counts trigger) update in real time on their own profile.
--   * REPLICA IDENTITY FULL lets Realtime evaluate RLS on UPDATE events.
--   * Adding profiles to the realtime publication broadcasts row changes; each
--     client subscribes filtered to its own id, so it only receives its row.
-- =============================================================================

alter table public.profiles replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.profiles;
exception
  when duplicate_object then null;
end $$;
