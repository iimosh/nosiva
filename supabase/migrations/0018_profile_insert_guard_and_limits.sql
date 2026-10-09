-- =============================================================================
-- Security hardening round: profile INSERT guard, username format, text length
-- limits, and storage bucket limits.
--
-- 1. Profile INSERT was unguarded. guard_role_change (0003) and
--    guard_profile_counters (0017) are BEFORE UPDATE triggers, but the profile
--    row is created with an INSERT, and "profiles insert own" only checks
--    auth.uid() = id. Anyone could therefore insert their own profile with
--    role = 'admin' or a fabricated rating/follower count straight through the
--    public API, bypassing both guards. This trigger forces safe defaults on
--    insert for everyone except admins and the service role / SQL editor.
--
-- 2. Username format was only checked in the app. Validated here too, but only
--    when a username is inserted or changed, so existing accounts with older
--    usernames can still update other profile fields.
--
-- 3. Text columns had no length limits server-side. Added generous limits as
--    NOT VALID (enforced for all new writes, without scanning old rows).
--
-- 4. Storage buckets accepted any file type and size. Added size limits and an
--    image-only allow-list.
-- =============================================================================

create or replace function public.guard_profile_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.role := 'user';
    new.rating_avg := 0;
    new.rating_count := 0;
    new.follower_count := 0;
    new.following_count := 0;
    new.onboarded := false;
  end if;
  return new;
end; $$;

drop trigger if exists trg_guard_profile_insert on public.profiles;
create trigger trg_guard_profile_insert
  before insert on public.profiles
  for each row execute function public.guard_profile_insert();

create or replace function public.validate_profile_username() returns trigger
language plpgsql set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.username is distinct from old.username then
    if new.username !~ '^[A-Za-z0-9_]{3,30}$' then
      raise exception 'Username must be 3-30 letters, numbers or underscores';
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists trg_validate_profile_username on public.profiles;
create trigger trg_validate_profile_username
  before insert or update of username on public.profiles
  for each row execute function public.validate_profile_username();

-- Text length limits (NOT VALID: applies to new writes only).
alter table public.messages
  drop constraint if exists messages_body_len,
  add constraint messages_body_len check (char_length(body) <= 4000) not valid;

alter table public.listings
  drop constraint if exists listings_title_len,
  add constraint listings_title_len check (char_length(title) <= 120) not valid,
  drop constraint if exists listings_description_len,
  add constraint listings_description_len check (char_length(description) <= 2000) not valid,
  drop constraint if exists listings_brand_len,
  add constraint listings_brand_len check (char_length(brand) <= 60) not valid,
  drop constraint if exists listings_color_len,
  add constraint listings_color_len check (char_length(color) <= 40) not valid,
  drop constraint if exists listings_location_len,
  add constraint listings_location_len check (char_length(location) <= 120) not valid;

alter table public.profiles
  drop constraint if exists profiles_display_name_len,
  add constraint profiles_display_name_len check (char_length(display_name) <= 60) not valid,
  drop constraint if exists profiles_bio_len,
  add constraint profiles_bio_len check (char_length(bio) <= 500) not valid,
  drop constraint if exists profiles_location_len,
  add constraint profiles_location_len check (char_length(location) <= 120) not valid;

alter table public.reviews
  drop constraint if exists reviews_comment_len,
  add constraint reviews_comment_len check (char_length(comment) <= 500) not valid;

alter table public.offers
  drop constraint if exists offers_message_len,
  add constraint offers_message_len check (char_length(message) <= 500) not valid;

-- Storage: size limits + images only.
update storage.buckets
   set file_size_limit = 8388608,
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
 where id = 'listing-images';

update storage.buckets
   set file_size_limit = 5242880,
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
 where id = 'avatars';

update storage.buckets
   set file_size_limit = 10485760,
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif', 'image/gif']
 where id = 'chat-images';
