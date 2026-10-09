-- =============================================================================
-- Create the profile at sign-up from the username in the user metadata.
--
-- With email confirmation on, sign-up returns no session, so the app cannot
-- insert the profile itself (row-level security rejects an unauthenticated
-- insert). This trigger creates it as part of the sign-up, which also
-- reserves the chosen username immediately instead of at first sign-in.
--
-- Skipped silently when there is no valid username in the metadata (e.g.
-- Google sign-in), and when the username is already taken — in both cases
-- the app creates the profile on first sign-in instead, so sign-up never
-- fails because of this trigger.
-- =============================================================================

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  chosen text := new.raw_user_meta_data ->> 'username';
begin
  if chosen is null or chosen !~ '^[A-Za-z0-9_]{3,30}$' then
    return new;
  end if;

  begin
    insert into public.profiles (id, username)
    values (new.id, chosen)
    on conflict (id) do nothing;
  exception when unique_violation then
    null;
  end;

  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
