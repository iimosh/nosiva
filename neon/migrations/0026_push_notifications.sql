-- =============================================================================
-- 0026 (Neon): push notifications
--
-- Same rules as supabase/migrations/0026 — who is notified about what is
-- decided by the triggers below, unchanged:
--   * new message            -> the other person in the chat
--   * new offer              -> seller
--   * offer accepted/declined -> buyer (including offers declined
--                               automatically when the item sells)
--   * new order              -> seller
--   * order accepted/shipped/delivered/cancelled -> the other person
--   Nobody is notified about their own action or by someone they blocked.
--
-- What's different on Neon: Postgres can't call a web address here, so each
-- notification is written to private.push_outbox instead. The `push`
-- function (neon/functions/push.ts) sends what's waiting: the app nudges it
-- right after each action, and a schedule runs it every minute in case a
-- nudge was missed. Sent rows are deleted; rows that keep failing are
-- dropped after a day.
--
-- Never breaks the action itself: any error in the notification code is
-- caught and only logged.
-- =============================================================================


-- ----------------------------------------------------------------------------
-- 1. Tokens
-- ----------------------------------------------------------------------------
create table if not exists public.push_tokens (
  token      text primary key check (char_length(token) between 20 and 4096),
  user_id    uuid not null references neon_auth."user"(id) on delete cascade,
  locale     text not null default 'en' check (locale in ('en', 'mk')),
  platform   text not null default 'android' check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);
create index if not exists push_tokens_user_idx on public.push_tokens(user_id);

alter table public.push_tokens enable row level security;

-- People may see and remove their own tokens; adding goes through the
-- function below (a phone's token can move to another account when someone
-- else signs in on it, which a plain insert policy can't allow safely).
drop policy if exists "push tokens own read" on public.push_tokens;
create policy "push tokens own read" on public.push_tokens
  for select using (auth.uid() = user_id);

drop policy if exists "push tokens own delete" on public.push_tokens;
create policy "push tokens own delete" on public.push_tokens
  for delete using (auth.uid() = user_id);

create or replace function public.register_push_token(
  p_token text,
  p_locale text default 'en',
  p_platform text default 'android'
) returns void
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not signed in';
  end if;

  insert into public.push_tokens (token, user_id, locale, platform, updated_at)
  values (
    p_token,
    uid,
    case when p_locale = 'mk' then 'mk' else 'en' end,
    case when p_platform = 'ios' then 'ios' else 'android' end,
    now()
  )
  on conflict (token) do update
     set user_id = excluded.user_id,
         locale = excluded.locale,
         platform = excluded.platform,
         updated_at = now();

  -- The app re-registers every time it opens, so a token untouched for 60
  -- days belongs to a phone where the app was removed.
  delete from public.push_tokens where updated_at < now() - interval '60 days';

  -- Keep the 10 most recent phones per account; older ones are stale.
  delete from public.push_tokens
   where user_id = uid
     and token not in (
       select token from public.push_tokens
        where user_id = uid
        order by updated_at desc
        limit 10
     );
end; $$;

create or replace function public.unregister_push_token(p_token text)
returns void
language sql security definer set search_path = public as $$
  delete from public.push_tokens where token = p_token and user_id = auth.uid();
$$;

revoke all on function public.register_push_token(text, text, text) from public, anonymous;
revoke all on function public.unregister_push_token(text) from public, anonymous;
grant execute on function public.register_push_token(text, text, text) to authenticated;
grant execute on function public.unregister_push_token(text) to authenticated;

-- ----------------------------------------------------------------------------
-- 2. Sending
-- ----------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anonymous, authenticated;

create table if not exists private.push_outbox (
  id         bigint generated always as identity primary key,
  recipient  uuid not null references neon_auth."user"(id) on delete cascade,
  payload    jsonb not null,
  attempts   int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists push_outbox_created_idx on private.push_outbox(created_at);
revoke all on private.push_outbox from public, anonymous, authenticated;

-- Queues one notification for the push function. Quietly does nothing when
-- the recipient is the actor, when either has blocked the other, or when
-- the recipient has no phone registered.
create or replace function private.queue_push(
  recipient uuid,
  actor uuid,
  payload jsonb
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if recipient is null or recipient = actor then
    return;
  end if;
  if actor is not null and public.is_blocked_between(actor, recipient) then
    return;
  end if;
  if not exists (select 1 from public.push_tokens where user_id = recipient) then
    return;
  end if;

  insert into private.push_outbox (recipient, payload)
  values (
    recipient,
    payload || jsonb_build_object(
      'actor_name', (
        select coalesce(nullif(trim(display_name), ''), username)
          from public.profiles where id = actor
      )
    )
  );
exception when others then
  raise warning 'queue_push failed: %', sqlerrm;
end; $$;

revoke all on function private.queue_push(uuid, uuid, jsonb) from public, anonymous, authenticated;

create or replace function private.listing_title(listing uuid)
returns text
language sql stable security definer set search_path = public as $$
  select left(title, 80) from public.listings where id = listing;
$$;

-- New message -> the other person in the conversation.
create or replace function private.push_on_message()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  c record;
begin
  select buyer_id, seller_id into c
    from public.conversations where id = new.conversation_id;
  perform private.queue_push(
    case when new.sender_id = c.buyer_id then c.seller_id else c.buyer_id end,
    new.sender_id,
    jsonb_build_object(
      'kind', 'message',
      'conversation_id', new.conversation_id,
      'preview', left(new.body, 120),
      'has_image', new.image_url is not null
    )
  );
  return null;
exception when others then
  raise warning 'push_on_message failed: %', sqlerrm;
  return null;
end; $$;

drop trigger if exists trg_zz_push_messages on public.messages;
create trigger trg_zz_push_messages after insert on public.messages
  for each row execute function private.push_on_message();

-- New offer -> seller. Accepted / declined -> buyer.
create or replace function private.push_on_offer()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  current_status text;
begin
  if tg_op = 'INSERT' then
    if new.status = 'pending' then
      perform private.queue_push(new.seller_id, new.buyer_id, jsonb_build_object(
        'kind', 'offer_new',
        'listing_title', private.listing_title(new.listing_id),
        'amount', new.amount
      ));
    end if;
    return null;
  end if;

  if new.status is not distinct from old.status
     or new.status not in ('accepted', 'declined') then
    return null;
  end if;

  -- Accepting an offer on an item that already has an order turns it into a
  -- decline straight away (create_order_from_accepted_offer). Look at the
  -- row as it is now, so the buyer hears only the final answer.
  select status into current_status from public.offers where id = new.id;
  if current_status is distinct from new.status then
    return null;
  end if;

  perform private.queue_push(new.buyer_id, new.seller_id, jsonb_build_object(
    'kind', case when new.status = 'accepted' then 'offer_accepted'
                 else 'offer_declined' end,
    'listing_title', private.listing_title(new.listing_id),
    'amount', new.amount,
    'order_id', (select order_id from public.offers where id = new.id)
  ));
  return null;
exception when others then
  raise warning 'push_on_offer failed: %', sqlerrm;
  return null;
end; $$;

drop trigger if exists trg_zz_push_offers on public.offers;
create trigger trg_zz_push_offers after insert or update of status on public.offers
  for each row execute function private.push_on_offer();

-- New order -> seller. Status changes -> the other person.
create or replace function private.push_on_order()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  actor uuid := auth.uid();
  recipient uuid;
begin
  if tg_op = 'INSERT' then
    -- Orders from an accepted offer start as 'paid' (accepted); the buyer
    -- is already told through the offer, and the seller accepted it.
    if new.status = 'pending' then
      perform private.queue_push(new.seller_id, new.buyer_id, jsonb_build_object(
        'kind', 'order_new',
        'order_id', new.id,
        'listing_title', private.listing_title(new.listing_id),
        'amount', new.total
      ));
    end if;
    return null;
  end if;

  if new.status is not distinct from old.status then
    return null;
  end if;

  recipient := case when actor = new.buyer_id then new.seller_id
                    else new.buyer_id end;
  perform private.queue_push(recipient, actor, jsonb_build_object(
    'kind', 'order_' || new.status,
    'order_id', new.id,
    'listing_title', private.listing_title(new.listing_id),
    'amount', new.total
  ));
  return null;
exception when others then
  raise warning 'push_on_order failed: %', sqlerrm;
  return null;
end; $$;

drop trigger if exists trg_zz_push_orders on public.orders;
create trigger trg_zz_push_orders after insert or update of status on public.orders
  for each row execute function private.push_on_order();
