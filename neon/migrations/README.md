# Neon database migrations

Applied in name order by `npm run migrate` (from the `neon/` folder), each
in its own transaction; `public._migrations` records which ones ran.

- **0001–0025** are ported from `supabase/migrations/` (same rules, same
  security). What changed for Neon:
  - Supabase Storage rules are removed. Photos live in Neon buckets
    (`neon.ts`), and uploads and private downloads go through
    `functions/media.ts`, which enforces the same limits (signed-in users,
    own folder only, images only, 8 MB listing photos, 5 MB avatars,
    10 MB chat photos).
  - Supabase Realtime publication statements are removed (the app refreshes
    instead; see the migration notes).
  - `auth.users` is Neon's `neon_auth."user"`, and the guest role is called
    `anonymous` instead of `anon`. `auth.uid()` exists on Neon too.
  - 0020 creates the profile from the sign-up `name`, where the app sends
    the chosen username.
  - 0002 (storage only) has no Neon version.
- **0026** is the Neon version of push notifications: same triggers, but
  notifications go to `private.push_outbox` for `functions/push.ts`.
- **0027** grants the Data API roles their table access (Supabase does this
  automatically).
- **0028–0033** were added after the move:
  - 0028: only signed-in people can call the chat helpers.
  - 0029: fixes accepting offers.
  - 0030: notifications for reviews and new followers.
  - 0031: an item can be sold again after a delivered order.
  - 0032: the block check reveals nothing to strangers, and the seller is
    checked in the offer and order rules.
  - 0033: per-account rate limits.

  0029 and 0031 are also in `supabase/migrations` (0027, 0028).
- **Push timing:** the app nudges the `push` function right after every
  action that notifies someone. The schedule (0026 mentions every minute)
  is now **hourly** (`neon.ts`), because waking the database every minute
  kept it from ever sleeping.

Never edit a migration that has already run; add a new one.
