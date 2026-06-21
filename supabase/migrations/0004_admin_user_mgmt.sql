-- =============================================================================
--   * This policy lets an admin UPDATE any profile row.
--   * The guard_role_change trigger (0003) already permits role changes when
--     the actor is an admin, so promote/demote succeeds for admins only.
--   * The app prevents an admin from changing their OWN role, so there's always
--     at least one admin (no self-lockout).
-- =============================================================================

drop policy if exists "profiles admin update" on public.profiles;
create policy "profiles admin update"
  on public.profiles for update
  using (public.is_admin())
  with check (public.is_admin());
