# Nosiva

Nosiva is a mobile marketplace for buying and selling second-hand fashion in North Macedonia. It is a Flutter app (Android first) with a [Neon](https://neon.com) backend: Postgres with row-level security, Neon Auth, the Neon Data API, Neon Functions and Neon object storage. Push notifications go through Firebase Cloud Messaging. The app is available in English and Macedonian.

Items are paid for in cash to the courier on delivery. The app doesn't take card payments.

## Features

- **Accounts**
  - Email and password sign-up with a 6-digit email confirmation code.
  - Google sign-in.
  - Password reset by emailed code, and change password.
  - Account deletion, which also removes the account's photos.
- **Guest browsing**: browse listings and profiles without an account. Signing in is asked for only when needed.
- **Listings**
  - Photos (cropped and compressed on the phone), category, size, condition, brand, colour, price and city.
  - Mark as sold or available, edit, delete.
  - View counts.
- **Search and filters**: as-you-type search with prefix matching, recent searches, filters for category, size, condition, colour, brand, city and price, and sorting.
- **Buying**
  - Cart with delivery address and phone, remembered for next time.
  - Offers, which the seller accepts or declines; accepting creates the order.
  - Order steps: pending, accepted, sent, delivered or cancelled.
  - Reviews after delivery.
- **Chat**: one-to-one chats per listing, with private photos that only the two people can open.
- **Social**: follows, favourites, reporting and blocking.
- **Notifications**: push notifications for messages, offers, orders, reviews and new followers, in the person's language. Tapping one opens the right screen.
- **Admin dashboard**: users and roles, reports, and listing moderation.
- **Polish**:
  - light and dark themes
  - an offline bar
  - accessibility labels
  - privacy policy and terms (EN/MK)

## Technology

| Area | Technology |
| --- | --- |
| App | Flutter, Dart, Riverpod, go_router, freezed/json_serializable |
| Database | Neon Postgres, with row-level security on every table |
| Data access | Neon Data API (PostgREST-compatible), via the `supabase` Dart data client |
| Auth | Neon Auth (managed Better Auth): email/password, email codes, Google |
| Server code | Neon Functions (TypeScript), in `neon/functions` |
| Photos | Neon object storage (S3-compatible), behind the `media` function |
| Push | Firebase Cloud Messaging and flutter_local_notifications |
| Live updates | Refresh on notification, on app resume, and on timers while the app is open (`lib/core/live`) |
| Testing | flutter_test |

## Project layout

```text
lib/
|-- main.dart, app.dart
|-- core/
|   |-- backend/     data client, auth and function providers
|   |-- neon/        Neon Auth client, Neon Functions client
|   |-- live/        refresh-instead-of-realtime helper
|   |-- config/      .env addresses, app info
|   |-- router/, theme/, l10n/, widgets/, utils/, network/, media/, ...
|-- shell/           bottom navigation, offline bar
`-- features/        one folder per area (auth, listings, messaging, offers,
                     orders, profile, notifications, admin, safety, ...),
                     each with data/ domain/ presentation/
neon/
|-- neon.ts          Neon project config: auth, Data API, buckets,
|                    functions, schedules
|-- migrations/      database migrations (see migrations/README.md)
|-- functions/       media.ts, push.ts, authbounce.ts
`-- scripts/         migrate.mjs, save-fcm-key.mjs
```

## Backend

Everything about the backend lives in `neon/`.

- **Database:** `npm run migrate` (in `neon/`) applies new files in `neon/migrations` in order. Every public table has row-level security, and migration 0027 refuses to finish if one doesn't. Business rules are enforced in the database too: order and offer state changes, one active order per item, blocks, and per-account rate limits.
- **Functions:**
  - `media`: upload links with size and type limits, private chat-photo links, deleting an account's photos, and a nightly cleanup of unused photo files.
  - `push`: sends notifications waiting in the database's outbox.
  - `authbounce`: the last step of Google sign-in.
- **Deploy:** `npm run deploy` (in `neon/`) applies `neon.ts`: functions, buckets and schedules.
- **Secrets** live only in git-ignored files:
  - `neon/.env.local` (written by `neon deploy`)
  - `neon/.env.secrets` (the Firebase key)
  - `android/app/google-services.json`

  None of them is ever committed.

The `supabase/` folder holds the previous Supabase backend, kept for reference until the move to Neon is settled.

## Running the app

1. Copy `.env.example` to `.env` and fill in the Neon addresses (all public; see the comments in the file).
2. Put the Firebase `google-services.json` in `android/app/`. Without it the app runs, but without push notifications.
3. Run `flutter pub get`, then `flutter run`.

Tests: `flutter test`. Static checks: `flutter analyze`.
