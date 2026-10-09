-- =============================================================================
-- User safety: blocking, reporting, and account deletion.
--
-- 1. blocks: a user can block another. A block (in either direction) prevents
--    starting conversations, sending messages, making offers and placing
--    orders between the two — enforced here in the database, not just hidden
--    in the UI.
-- 2. reports: users can report a user or a listing; admins review them.
-- 3. delete_my_account(): lets a signed-in user permanently delete their own
--    account. Refuses while they have open orders. Required by the app stores.
--
-- Also fixes a latent bug in the conversation-insert policy: inside the
-- listings subquery, `l.seller_id = seller_id` resolved BOTH sides to the
-- listing's column (always true), so the conversation's seller was never
-- actually compared to the listing's seller. Now qualified explicitly.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Blocks
-- ----------------------------------------------------------------------------
create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

alter table public.blocks enable row level security;

drop policy if exists "blocks own read" on public.blocks;
create policy "blocks own read" on public.blocks
  for select using (auth.uid() = blocker_id);

drop policy if exists "blocks own insert" on public.blocks;
create policy "blocks own insert" on public.blocks
  for insert with check (auth.uid() = blocker_id);

drop policy if exists "blocks own delete" on public.blocks;
create policy "blocks own delete" on public.blocks
  for delete using (auth.uid() = blocker_id);

-- True when either user has blocked the other. SECURITY DEFINER so a policy
-- can check blocks in both directions even though each user can only read
-- the blocks they created themselves.
create or replace function public.is_blocked_between(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.blocks
     where (blocker_id = a and blocked_id = b)
        or (blocker_id = b and blocked_id = a)
  );
$$;

-- Conversations: no new conversation between blocked users.
drop policy if exists "conversations buyer insert" on public.conversations;
create policy "conversations buyer insert"
  on public.conversations for insert
  with check (
    auth.uid() = buyer_id
    and buyer_id <> seller_id
    and not public.is_blocked_between(buyer_id, seller_id)
    and (
      listing_id is null
      or exists (
        select 1
          from public.listings l
         where l.id = listing_id
           and l.seller_id = conversations.seller_id
           and l.seller_id <> auth.uid()
           and l.status <> 'hidden'
      )
    )
  );

-- Messages: no sending in a conversation between blocked users.
drop policy if exists "messages sender insert" on public.messages;
create policy "messages sender insert"
  on public.messages for insert
  with check (
    auth.uid() = sender_id
    and (length(trim(body)) > 0 or image_url is not null)
    and exists (
      select 1
        from public.conversations c
       where c.id = conversation_id
         and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
         and not public.is_blocked_between(c.buyer_id, c.seller_id)
    )
  );

-- Offers: no offers between blocked users.
drop policy if exists "offers buyer insert" on public.offers;
create policy "offers buyer insert"
  on public.offers for insert
  with check (
    auth.uid() = buyer_id
    and buyer_id <> seller_id
    and not public.is_blocked_between(buyer_id, seller_id)
    and status = 'pending'
    and order_id is null
    and exists (
      select 1
        from public.listings l
       where l.id = listing_id
         and l.seller_id = seller_id
         and l.seller_id <> auth.uid()
         and l.status = 'active'
    )
  );

-- Orders: no orders between blocked users.
drop policy if exists "orders buyer insert" on public.orders;
create policy "orders buyer insert"
  on public.orders for insert
  with check (
    auth.uid() = buyer_id
    and buyer_id <> seller_id
    and not public.is_blocked_between(buyer_id, seller_id)
    and status = 'pending'
    and exists (
      select 1
        from public.listings l
       where l.id = listing_id
         and l.seller_id = seller_id
         and l.seller_id <> auth.uid()
         and l.status = 'active'
         and l.price = total
    )
  );

-- ----------------------------------------------------------------------------
-- Reports
-- ----------------------------------------------------------------------------
create table if not exists public.reports (
  id          uuid primary key default uuid_generate_v4(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('user', 'listing')),
  target_id   uuid not null,
  reason      text not null check (reason in
                ('spam', 'scam', 'inappropriate', 'harassment', 'counterfeit', 'other')),
  details     text check (char_length(details) <= 500),
  status      text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  created_at  timestamptz not null default now(),
  unique (reporter_id, target_type, target_id)
);

create index if not exists reports_status_idx on public.reports(status, created_at desc);

alter table public.reports enable row level security;

drop policy if exists "reports insert own" on public.reports;
create policy "reports insert own" on public.reports
  for insert with check (
    auth.uid() = reporter_id
    and status = 'open'
    and not (target_type = 'user' and target_id = auth.uid())
  );

drop policy if exists "reports read own or admin" on public.reports;
create policy "reports read own or admin" on public.reports
  for select using (auth.uid() = reporter_id or public.is_admin());

drop policy if exists "reports admin update" on public.reports;
create policy "reports admin update" on public.reports
  for update using (public.is_admin()) with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- Account deletion
-- ----------------------------------------------------------------------------
-- Deleting the auth user cascades to the profile and, through it, to
-- listings, offers, conversations/messages, reviews, favorites, follows,
-- blocks and reports. Orders are the exception: orders.listing_id is
-- ON DELETE RESTRICT, so a user's orders are removed first. Open orders
-- block deletion so a buyer or seller is never left mid-transaction.
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not signed in';
  end if;

  if exists (
    select 1
      from public.orders
     where (buyer_id = uid or seller_id = uid)
       and status not in ('delivered', 'cancelled')
  ) then
    raise exception 'open_orders';
  end if;

  delete from public.orders where buyer_id = uid or seller_id = uid;
  delete from auth.users where id = uid;
end; $$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
