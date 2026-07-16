-- =============================================================================
-- Per-user "delete conversation" (soft hide from the inbox).
--
--   * A conversation can be hidden independently by either side via
--     hide_conversation(); it simply stops showing up in *their* inbox.
--   * If the other participant sends a new message, on_message_insert()
--     clears both hide flags so the conversation reappears for everyone —
--     matches WhatsApp/Messenger "delete chat" semantics, not a hard delete.
-- =============================================================================

alter table public.conversations
  add column if not exists deleted_by_buyer  boolean not null default false,
  add column if not exists deleted_by_seller boolean not null default false;

create or replace function public.hide_conversation(conv uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.conversations set
    deleted_by_buyer  = case when buyer_id  = auth.uid() then true else deleted_by_buyer  end,
    deleted_by_seller = case when seller_id = auth.uid() then true else deleted_by_seller end
  where id = conv and (buyer_id = auth.uid() or seller_id = auth.uid());
end; $$;

create or replace function public.on_message_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.conversations set
    buyer_unread  = buyer_unread  + (case when buyer_id  <> new.sender_id then 1 else 0 end),
    seller_unread = seller_unread + (case when seller_id <> new.sender_id then 1 else 0 end),
    last_message    = case when new.image_url is not null then 'Photo' else new.body end,
    last_message_at = now(),
    deleted_by_buyer  = false,
    deleted_by_seller = false
  where id = new.conversation_id;
  return new;
end; $$;
