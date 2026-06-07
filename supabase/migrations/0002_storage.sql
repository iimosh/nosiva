-- =============================================================================
-- Nosiva — Storage buckets & policies
-- Buckets: `listing-images` and `avatars` (both public-read).
-- Files are namespaced by user id: `<uid>/<listingId>/<file>` so a user may
-- only write under their own folder.
-- =============================================================================

insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Public read for both buckets
create policy "public read listing images"
  on storage.objects for select
  using (bucket_id = 'listing-images');

create policy "public read avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Authenticated users may write only under their own uid folder.
create policy "users upload own listing images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users modify own listing images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users delete own listing images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users upload own avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users modify own avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
