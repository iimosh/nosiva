-- =============================================================================
-- Nosiva — initial schema, relationships, triggers & Row Level Security
-- Run via the Supabase SQL editor or `supabase db push`.
-- =============================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pg_trgm;

-- ----------------------------------------------------------------------------
-- Reference tables (categories & style tags)
-- ----------------------------------------------------------------------------
create table if not exists public.categories (
  slug   text primary key,
  label  text not null,
  emoji  text,
  sort   int default 0
);

create table if not exists public.style_tags (
  slug   text primary key,
  label  text not null
);

-- ----------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  username        text unique not null,
  display_name    text,
  avatar_url      text,
  bio             text,
  location        text,
  vibe_tags       text[] not null default '{}',
  follower_count  int not null default 0,
  following_count int not null default 0,
  rating_avg      numeric(3,2) not null default 0,
  rating_count    int not null default 0,
  onboarded       boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- Follows (graph) — drives follower/following counts
-- ----------------------------------------------------------------------------
create table if not exists public.follows (
  follower_id  uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

-- ----------------------------------------------------------------------------
-- Listings
-- ----------------------------------------------------------------------------
create table if not exists public.listings (
  id             uuid primary key default uuid_generate_v4(),
  seller_id      uuid not null references public.profiles(id) on delete cascade,
  title          text not null,
  description    text not null default '',
  category       text not null references public.categories(slug),
  brand          text,
  size           text,
  condition      text not null default 'good',
  color          text,
  price          numeric(10,2) not null check (price >= 0),
  status         text not null default 'active',  -- active | reserved | sold | hidden
  style_tags     text[] not null default '{}',
  location       text,
  favorite_count int not null default 0,
  view_count     int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  -- Full-text search document over title/description/brand
  search_doc tsvector generated always as (
    to_tsvector('english',
      coalesce(title,'') || ' ' || coalesce(description,'') || ' ' || coalesce(brand,''))
  ) stored
);

create index if not exists listings_seller_idx   on public.listings(seller_id);
create index if not exists listings_category_idx  on public.listings(category);
create index if not exists listings_status_idx    on public.listings(status);
create index if not exists listings_created_idx   on public.listings(created_at desc);
create index if not exists listings_price_idx      on public.listings(price);
create index if not exists listings_search_idx     on public.listings using gin(search_doc);
create index if not exists listings_styletags_idx  on public.listings using gin(style_tags);

-- ----------------------------------------------------------------------------
-- Listing images
-- ----------------------------------------------------------------------------
create table if not exists public.listing_images (
  id         uuid primary key default uuid_generate_v4(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  image_url  text not null,
  position   int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists listing_images_listing_idx on public.listing_images(listing_id);

-- ----------------------------------------------------------------------------
-- Favorites (wishlist)
-- ----------------------------------------------------------------------------
create table if not exists public.favorites (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  listing_id uuid not null references public.listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index if not exists favorites_listing_idx on public.favorites(listing_id);

-- ----------------------------------------------------------------------------
-- Conversations & messages (1:1 chat per listing)
-- ----------------------------------------------------------------------------
create table if not exists public.conversations (
  id              uuid primary key default uuid_generate_v4(),
  listing_id      uuid references public.listings(id) on delete set null,
  buyer_id        uuid not null references public.profiles(id) on delete cascade,
  seller_id       uuid not null references public.profiles(id) on delete cascade,
  last_message    text,
  last_message_at timestamptz,
  created_at      timestamptz not null default now(),
  unique (listing_id, buyer_id, seller_id)
);
create index if not exists conversations_buyer_idx  on public.conversations(buyer_id);
create index if not exists conversations_seller_idx on public.conversations(seller_id);

create table if not exists public.messages (
  id              uuid primary key default uuid_generate_v4(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  body            text not null default '',
  image_url       text,
  created_at      timestamptz not null default now()
);
create index if not exists messages_conversation_idx on public.messages(conversation_id, created_at);

-- ----------------------------------------------------------------------------
-- Offers
-- ----------------------------------------------------------------------------
create table if not exists public.offers (
  id         uuid primary key default uuid_generate_v4(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  buyer_id   uuid not null references public.profiles(id) on delete cascade,
  seller_id  uuid not null references public.profiles(id) on delete cascade,
  amount     numeric(10,2) not null check (amount > 0),
  status     text not null default 'pending', -- pending|accepted|declined|countered|expired
  message    text,
  created_at timestamptz not null default now()
);
create index if not exists offers_listing_idx on public.offers(listing_id);
create index if not exists offers_seller_idx  on public.offers(seller_id);

-- ----------------------------------------------------------------------------
-- Orders
-- ----------------------------------------------------------------------------
create table if not exists public.orders (
  id               uuid primary key default uuid_generate_v4(),
  listing_id       uuid not null references public.listings(id) on delete restrict,
  buyer_id         uuid not null references public.profiles(id) on delete cascade,
  seller_id        uuid not null references public.profiles(id) on delete cascade,
  total            numeric(10,2) not null,
  status           text not null default 'pending', -- pending|paid|shipped|delivered|cancelled
  shipping_address text,
  stripe_payment_intent text,  -- 🔌 set when Stripe is wired up
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists orders_buyer_idx  on public.orders(buyer_id);
create index if not exists orders_seller_idx on public.orders(seller_id);

-- ----------------------------------------------------------------------------
-- Reviews (buyer ↔ seller ratings)
-- ----------------------------------------------------------------------------
create table if not exists public.reviews (
  id          uuid primary key default uuid_generate_v4(),
  order_id    uuid references public.orders(id) on delete set null,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  reviewee_id uuid not null references public.profiles(id) on delete cascade,
  rating      int not null check (rating between 1 and 5),
  comment     text,
  created_at  timestamptz not null default now(),
  unique (order_id, reviewer_id)
);
create index if not exists reviews_reviewee_idx on public.reviews(reviewee_id);

-- ----------------------------------------------------------------------------
-- Notifications
-- ----------------------------------------------------------------------------
create table if not exists public.notifications (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  type       text not null, -- message|offer|sale|follow|review|system
  title      text not null,
  body       text,
  data       jsonb,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);

-- =============================================================================
-- Triggers
-- =============================================================================

-- updated_at maintenance
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_profiles_touch on public.profiles;
create trigger trg_profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
drop trigger if exists trg_listings_touch on public.listings;
create trigger trg_listings_touch before update on public.listings
  for each row execute function public.touch_updated_at();
drop trigger if exists trg_orders_touch on public.orders;
create trigger trg_orders_touch before update on public.orders
  for each row execute function public.touch_updated_at();

-- favorite_count maintenance
create or replace function public.sync_favorite_count() returns trigger
language plpgsql as $$
begin
  if (tg_op = 'INSERT') then
    update public.listings set favorite_count = favorite_count + 1 where id = new.listing_id;
  elsif (tg_op = 'DELETE') then
    update public.listings set favorite_count = greatest(favorite_count - 1, 0) where id = old.listing_id;
  end if;
  return null;
end; $$;

drop trigger if exists trg_favorites_count on public.favorites;
create trigger trg_favorites_count after insert or delete on public.favorites
  for each row execute function public.sync_favorite_count();

-- follower / following count maintenance
create or replace function public.sync_follow_counts() returns trigger
language plpgsql as $$
begin
  if (tg_op = 'INSERT') then
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
    update public.profiles set follower_count  = follower_count  + 1 where id = new.following_id;
  elsif (tg_op = 'DELETE') then
    update public.profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
    update public.profiles set follower_count  = greatest(follower_count  - 1, 0) where id = old.following_id;
  end if;
  return null;
end; $$;

drop trigger if exists trg_follow_counts on public.follows;
create trigger trg_follow_counts after insert or delete on public.follows
  for each row execute function public.sync_follow_counts();

-- review aggregate maintenance
create or replace function public.sync_review_aggregate() returns trigger
language plpgsql as $$
declare target uuid := coalesce(new.reviewee_id, old.reviewee_id);
begin
  update public.profiles p set
    rating_count = (select count(*) from public.reviews where reviewee_id = target),
    rating_avg   = coalesce((select avg(rating) from public.reviews where reviewee_id = target), 0)
  where p.id = target;
  return null;
end; $$;

drop trigger if exists trg_reviews_agg on public.reviews;
create trigger trg_reviews_agg after insert or update or delete on public.reviews
  for each row execute function public.sync_review_aggregate();

-- =============================================================================
-- Row Level Security
-- =============================================================================
alter table public.profiles       enable row level security;
alter table public.follows        enable row level security;
alter table public.listings       enable row level security;
alter table public.listing_images enable row level security;
alter table public.favorites      enable row level security;
alter table public.conversations  enable row level security;
alter table public.messages       enable row level security;
alter table public.offers         enable row level security;
alter table public.orders         enable row level security;
alter table public.reviews        enable row level security;
alter table public.notifications  enable row level security;
alter table public.categories     enable row level security;
alter table public.style_tags     enable row level security;

-- Reference data: readable by everyone
create policy "categories readable" on public.categories for select using (true);
create policy "style_tags readable" on public.style_tags for select using (true);

-- Profiles: public read; users manage only their own row
create policy "profiles readable"        on public.profiles for select using (true);
create policy "profiles insert own"      on public.profiles for insert with check (auth.uid() = id);
create policy "profiles update own"      on public.profiles for update using (auth.uid() = id);

-- Follows: public read; act as yourself
create policy "follows readable" on public.follows for select using (true);
create policy "follows insert own" on public.follows for insert with check (auth.uid() = follower_id);
create policy "follows delete own" on public.follows for delete using (auth.uid() = follower_id);

-- Listings: active listings public; owner has full control
create policy "listings readable"
  on public.listings for select
  using (status <> 'hidden' or seller_id = auth.uid());
create policy "listings insert own"
  on public.listings for insert with check (auth.uid() = seller_id);
create policy "listings update own"
  on public.listings for update using (auth.uid() = seller_id);
create policy "listings delete own"
  on public.listings for delete using (auth.uid() = seller_id);

-- Listing images: readable by all; writable by the listing's seller
create policy "listing_images readable"
  on public.listing_images for select using (true);
create policy "listing_images write own"
  on public.listing_images for all
  using (exists (select 1 from public.listings l
                 where l.id = listing_id and l.seller_id = auth.uid()))
  with check (exists (select 1 from public.listings l
                      where l.id = listing_id and l.seller_id = auth.uid()));

-- Favorites: a user sees & manages only their own
create policy "favorites own read"   on public.favorites for select using (auth.uid() = user_id);
create policy "favorites own insert" on public.favorites for insert with check (auth.uid() = user_id);
create policy "favorites own delete" on public.favorites for delete using (auth.uid() = user_id);

-- Conversations: only the buyer or seller
create policy "conversations participants read"
  on public.conversations for select
  using (auth.uid() = buyer_id or auth.uid() = seller_id);
create policy "conversations buyer insert"
  on public.conversations for insert with check (auth.uid() = buyer_id);
create policy "conversations participants update"
  on public.conversations for update
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- Messages: only conversation participants
create policy "messages participants read"
  on public.messages for select
  using (exists (select 1 from public.conversations c
                 where c.id = conversation_id
                   and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())));
create policy "messages sender insert"
  on public.messages for insert
  with check (auth.uid() = sender_id
    and exists (select 1 from public.conversations c
                where c.id = conversation_id
                  and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())));

-- Offers: buyer & seller can see; buyer creates; seller updates status
create policy "offers participants read"
  on public.offers for select using (auth.uid() = buyer_id or auth.uid() = seller_id);
create policy "offers buyer insert"
  on public.offers for insert with check (auth.uid() = buyer_id);
create policy "offers participants update"
  on public.offers for update using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- Orders: buyer & seller can see; buyer creates; either can update status
create policy "orders participants read"
  on public.orders for select using (auth.uid() = buyer_id or auth.uid() = seller_id);
create policy "orders buyer insert"
  on public.orders for insert with check (auth.uid() = buyer_id);
create policy "orders participants update"
  on public.orders for update using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- Reviews: public read; reviewer writes their own
create policy "reviews readable"     on public.reviews for select using (true);
create policy "reviews insert own"   on public.reviews for insert with check (auth.uid() = reviewer_id);
create policy "reviews update own"   on public.reviews for update using (auth.uid() = reviewer_id);

-- Notifications: each user sees & updates only their own
create policy "notifications own read"   on public.notifications for select using (auth.uid() = user_id);
create policy "notifications own update" on public.notifications for update using (auth.uid() = user_id);
-- Inserts are performed by service-role / SECURITY DEFINER functions only.

-- =============================================================================
-- Realtime — broadcast inserts/updates for chat & notifications
-- =============================================================================
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversations;
alter publication supabase_realtime add table public.notifications;

-- =============================================================================
-- Seed reference data
-- =============================================================================
insert into public.categories (slug, label, emoji, sort) values
  ('tops','Tops','👚',1),
  ('dresses','Dresses','👗',2),
  ('bottoms','Bottoms','👖',3),
  ('shoes','Shoes','👠',4),
  ('bags','Bags','👜',5),
  ('accessories','Accessories','🧣',6),
  ('jewelry','Jewelry','💍',7),
  ('outerwear','Outerwear','🧥',8)
on conflict (slug) do nothing;

insert into public.style_tags (slug, label) values
  ('y2k','Y2K'), ('coquette','coquette'), ('streetwear','streetwear'),
  ('vintage','vintage'), ('minimalist','minimalist'), ('cottagecore','cottagecore'),
  ('grunge','grunge'), ('preppy','preppy'), ('boho','boho'),
  ('academia','academia'), ('athleisure','athleisure'), ('gorpcore','gorpcore')
on conflict (slug) do nothing;
