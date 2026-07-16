-- =============================================================================
-- Harden public.conversations against direct client writes.
--
-- The "conversations participants update" policy (0001) has a `using` clause
-- but no `with check`, so RLS alone lets either participant UPDATE *any*
-- column via a raw REST call — including the other side's unread counter,
-- last_message preview, or (since 0012) their deleted_by_* hide flag.
--
-- No client code performs a direct .update() on this table (mark_conversation_read
-- and hide_conversation are the only write paths, both SECURITY DEFINER RPCs that
-- run as the function owner regardless of table-level grants) so revoking the
-- authenticated role's UPDATE privilege closes this off without breaking anything.
-- =============================================================================

revoke update on public.conversations from authenticated;

drop policy if exists "conversations participants update" on public.conversations;
