-- =============================================================================
-- 0033 (Neon): per-account rate limits
--
-- Nothing limited how fast one account could create things, so a script
-- could post thousands of messages, listings or offers a minute — spam for
-- everyone, and database work that costs money. Each insert below now
-- checks how many the same person created in the last minute and day:
--
--   table          per minute   per day
--   messages            20        1000
--   conversations       10          60
--   listings             5          30
--   offers               5          40
--   orders               5          30
--   reports              5          20
--   follows             30         300
--   favorites           60        2000
--   blocks              10         100
--
-- A real person never gets close. Over the limit, the insert is refused
-- with the message "rate_limited" (the app says "too many attempts, try
-- again later"). Only the signed-in person's own rows count, and
-- server-side inserts (nobody signed in) aren't limited. Each table gets an
-- index so the check stays instant.
-- =============================================================================

create or replace function private.enforce_rate_limit()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  actor uuid := auth.uid();
  owner_column text := tg_argv[0];
  per_minute int := tg_argv[1]::int;
  per_day int := tg_argv[2]::int;
  last_minute int;
  last_day int;
begin
  -- Server-side work, or a row that isn't the signed-in person's own (e.g.
  -- the order a seller's accepted offer creates for the buyer).
  if actor is null
     or (to_jsonb(new) ->> owner_column)::uuid is distinct from actor then
    return new;
  end if;

  execute format(
    'select count(*) filter (where created_at > now() - interval ''1 minute''),
            count(*)
       from %I.%I
      where %I = $1 and created_at > now() - interval ''1 day''',
    tg_table_schema, tg_table_name, owner_column)
  into last_minute, last_day
  using actor;

  if last_minute >= per_minute or last_day >= per_day then
    raise exception 'rate_limited: too many % in a short time', tg_table_name
      using hint = 'Try again later.';
  end if;
  return new;
end; $$;

-- (table, owner column, per minute, per day)
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('messages',      'sender_id',   20, 1000),
      ('conversations', 'buyer_id',    10,   60),
      ('listings',      'seller_id',    5,   30),
      ('offers',        'buyer_id',     5,   40),
      ('orders',        'buyer_id',     5,   30),
      ('reports',       'reporter_id',  5,   20),
      ('follows',       'follower_id', 30,  300),
      ('favorites',     'user_id',     60, 2000),
      ('blocks',        'blocker_id',  10,  100)
    ) as t(tbl, owner_column, per_minute, per_day)
  loop
    execute format(
      'create index if not exists %I on public.%I (%I, created_at desc)',
      r.tbl || '_rate_idx', r.tbl, r.owner_column);
    -- "trg_aa_" so it runs before the table's other checks.
    execute format('drop trigger if exists trg_aa_rate_limit on public.%I', r.tbl);
    execute format(
      'create trigger trg_aa_rate_limit before insert on public.%I
         for each row execute function private.enforce_rate_limit(%L, %L, %L)',
      r.tbl, r.owner_column, r.per_minute, r.per_day);
  end loop;
end $$;
