-- =============================================================================
-- Chat: unread counters + reliable conversation bookkeeping.
--
--   * Each conversation tracks an unread count per side (buyer / seller).
--   * A trigger on message insert bumps the *recipient's* unread counter and
--     keeps last_message / last_message_at in sync (server-side & atomic, so the
--     inbox always reflects the latest message and ordering).
--   * mark_conversation_read() resets the caller's unread when they open a chat.
--   * REPLICA IDENTITY FULL lets Realtime evaluate RLS on UPDATEs so the inbox
--     badge updates live.
-- =============================================================================

alter table public.conversations
  add column if not exists buyer_unread  int not null default 0,
  add column if not exists seller_unread int not null default 0;

alter table public.conversations replica identity full;

create or replace function public.on_message_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.conversations set
    buyer_unread  = buyer_unread  + (case when buyer_id  <> new.sender_id then 1 else 0 end),
    seller_unread = seller_unread + (case when seller_id <> new.sender_id then 1 else 0 end),
    last_message    = case when new.image_url is not null then 'Photo' else new.body end,
    last_message_at = now()
  where id = new.conversation_id;
  return new;
end; $$;

drop trigger if exists trg_messages_on_insert on public.messages;
create trigger trg_messages_on_insert after insert on public.messages
  for each row execute function public.on_message_insert();

-- Resets the calling user's unread counter for a conversation they're part of.
create or replace function public.mark_conversation_read(conv uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.conversations set
    buyer_unread  = case when buyer_id  = auth.uid() then 0 else buyer_unread  end,
    seller_unread = case when seller_id = auth.uid() then 0 else seller_unread end
  where id = conv and (buyer_id = auth.uid() or seller_id = auth.uid());
end; $$;
