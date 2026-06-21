-- =============================================================================
-- Nosiva — user roles (moderation MVP)
-- Adds a `role` column to profiles ('user' | 'admin'), a secure is_admin()
-- helper, a guard so users can't promote themselves, and admin-override RLS
-- so admins can moderate any listing.
--
-- Run AFTER 0001_init.sql & 0002_storage.sql.
--
-- 👑 Bootstrap your first admin (run once, in this SQL editor):
--     update public.profiles set role = 'admin' where username = '<your-username>';
--   (Works here because auth.uid() is null for the service role, so the guard
--    trigger below allows it.)
-- =============================================================================

-- 1. Role column ------------------------------------------------------------
alter table public.profiles
  add column if not exists role text not null default 'user'
  check (role in ('user', 'admin'));

-- 2. is_admin() helper ------------------------------------------------------
-- SECURITY DEFINER so it reads profiles regardless of RLS (prevents recursion
-- when referenced from within profile/listing policies).
create or replace function public.is_admin()
  returns boolean
  language sql
  stable
  security definer
  set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- 3. Guard: only admins may change a role -----------------------------------
-- auth.uid() is null for the service role / SQL editor, which is how the first
-- admin gets bootstrapped above; end users (non-null uid, non-admin) are blocked.
create or replace function public.guard_role_change()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'Only admins can change a user role';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_role on public.profiles;
create trigger trg_guard_role
  before update on public.profiles
  for each row execute function public.guard_role_change();

-- 4. Admin-override RLS (OR-ed with the existing owner policies) -------------
-- `for all` also covers SELECT, so admins can see hidden listings too.
drop policy if exists "listings admin manage" on public.listings;
create policy "listings admin manage"
  on public.listings for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "listing_images admin manage" on public.listing_images;
create policy "listing_images admin manage"
  on public.listing_images for all
  using (public.is_admin())
  with check (public.is_admin());
