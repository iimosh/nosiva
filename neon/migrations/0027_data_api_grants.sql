-- =============================================================================
-- 0027 (Neon only): table access for the Data API's two roles
--
-- Supabase grants its `anon` and `authenticated` roles access to every
-- table automatically, and row-level security then decides which rows each
-- person may see or change. Neon's Data API uses the roles `anonymous`
-- (guests) and `authenticated` (signed in), which start with no access, so
-- the same access is granted here:
--   * guests may only read (browsing listings and profiles);
--   * signed-in people may read and write;
--   * in both cases the row-level security rules still apply to every row —
--     a table without RLS would be fully exposed, which the check at the
--     end refuses.
-- The `private` schema and the migration log are never exposed.
-- =============================================================================

grant usage on schema public to authenticated, anonymous;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to anonymous;
grant usage, select on all sequences in schema public to authenticated;

alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public
  grant select on tables to anonymous;
alter default privileges in schema public
  grant usage, select on sequences to authenticated;

revoke all on public._migrations from authenticated, anonymous;

-- Refuse to finish if any exposed table is missing row-level security.
do $$
declare
  unprotected text;
begin
  select string_agg(c.relname, ', ') into unprotected
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind = 'r'
     and c.relname <> '_migrations'
     and not c.relrowsecurity;
  if unprotected is not null then
    raise exception 'Tables without row-level security: %', unprotected;
  end if;
end $$;
