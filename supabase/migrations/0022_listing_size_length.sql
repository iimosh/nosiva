-- =============================================================================
-- 0022: cap the listing size text
--
-- Sellers can now type their own size ("38", "W30 L32", "One size", …)
-- instead of only picking from a fixed list. The app limits it to 20
-- characters; this enforces the same limit in the database, so a request
-- that skips the app can't store a huge value.
--
-- NOT VALID: checked for every new or edited listing, without failing on any
-- old row. Safe to run more than once.
-- =============================================================================

alter table public.listings drop constraint if exists listings_size_length;
alter table public.listings
  add constraint listings_size_length
  check (size is null or char_length(size) between 1 and 20) not valid;
