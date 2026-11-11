-- =============================================================================
-- 0028 (Neon): chat helpers are for signed-in people only
--
-- mark_conversation_read and hide_conversation already only touch
-- conversations the caller is part of (a guest has none), but guests have
-- no reason to call them at all — so only signed-in people may.
-- =============================================================================
revoke all on function public.mark_conversation_read(uuid) from public, anonymous;
revoke all on function public.hide_conversation(uuid) from public, anonymous;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
grant execute on function public.hide_conversation(uuid) to authenticated;
