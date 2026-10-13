-- =============================================================================
-- 0025: chat photos are private to the two people in the conversation
--
-- Before: the chat-images bucket was public. Every photo sent in a chat had a
-- permanent web link that anyone could open — no account needed — if the
-- link was ever forwarded, logged or leaked.
--
-- Now:
--   1. The bucket is private. Photos can only be read by a signed-in member
--      of the conversation they were sent in (the first folder of every
--      photo's path is its conversation id). The app asks for short-lived
--      links (valid one hour) to show them.
--   2. A photo message must point at a file in its own conversation's folder,
--      uploaded by its own sender: "<conversation>/<sender>/<file>". A
--      tampered app can no longer put an outside web address in a message
--      (which would make the other person's phone load it and reveal their
--      IP address to that server), or point at someone else's chat.
--
-- Uploading, replacing and deleting keep their existing rules (0012).
-- Photos already sent keep working: the app turns their old public links
-- into private ones.
--
-- NOT VALID: messages already sent aren't re-checked; every new one is.
-- Safe to run more than once.
-- =============================================================================

update storage.buckets set public = false where id = 'chat-images';

drop policy if exists "public read chat images" on storage.objects;
drop policy if exists "participants read chat images" on storage.objects;
create policy "participants read chat images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-images'
    and exists (
      select 1
        from public.conversations c
       where c.id::text = (storage.foldername(name))[1]
         and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

alter table public.messages drop constraint if exists messages_image_in_own_chat;
alter table public.messages
  add constraint messages_image_in_own_chat
  check (
    image_url is null
    or (
      image_url like conversation_id::text || '/' || sender_id::text || '/%'
      and image_url !~ '\.\.'
      and char_length(image_url) <= 200
    )
  ) not valid;
